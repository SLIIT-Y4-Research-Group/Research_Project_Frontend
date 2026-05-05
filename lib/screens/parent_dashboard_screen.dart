import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/parent_bottom_nav_bar.dart';
import 'child_report_screen.dart';
import 'parent_drawings_screen.dart';
import 'welcome_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();

  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _trustedContacts = [];

  String? _selectedChildId;
  Map<String, dynamic>? _selectedChild;

  bool _isLoading = false;
  bool _isDarkMode = false;

  Timer? _pollingTimer;
  bool _isPolling = false;

  Color get _pageBackground =>
      _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF6F8F7);

  Color get _cardColor =>
      _isDarkMode ? const Color(0xFF1F2937) : Colors.white;

  Color get _headerColor =>
      _isDarkMode ? const Color(0xFF1A2332) : const Color(0xFFF1F8F4);

  Color get _primaryTextColor =>
      _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  Color get _borderColor => _isDarkMode
      ? Colors.white.withValues(alpha: 0.10)
      : const Color(0xFFE3EAE5);

  Color get _emptyStateIconBg =>
      _isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F6F4);

  Color get _emptyStateIconColor =>
      _isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

  Color get _selectedChildBg =>
      _isDarkMode ? const Color(0xFF1E3A2E) : const Color(0xFFEEF7EF);

  Color get _unselectedChildBg =>
      _isDarkMode ? const Color(0xFF374151) : const Color(0xFFF8FCF9);

  Color get _fieldFillColor =>
      _isDarkMode ? const Color(0xFF374151) : const Color(0xFFF8FAFB);

  Color get _dialogFieldFillColor =>
      _isDarkMode ? const Color(0xFF374151) : const Color(0xFFF5F7F6);

  Color get _dividerColor => _isDarkMode
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFFE8ECEA);

  Color get _subtleSurfaceTint =>
      _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF8FCF9);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChildren();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTrustedContactsPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && _selectedChildId != null) {
      _loadTrustedContacts(_selectedChildId!);
    }
  }

  String? _getChildId(Map<String, dynamic> child) {
    return child['id']?.toString() ?? child['_id']?.toString();
  }

  String? _getTrustedId(Map<String, dynamic> contact) {
    return contact['id']?.toString() ??
        contact['_id']?.toString() ??
        contact['trusted_id']?.toString() ??
        contact['trustedId']?.toString();
  }

  Future<void> _refreshData() async {
    await _loadChildren();

    if (_selectedChildId != null) {
      await _loadTrustedContacts(_selectedChildId!);
    }
  }

  Future<void> _loadChildren() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final response = await ApiClient.getChildren();

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final children = data.cast<Map<String, dynamic>>();

        if (!mounted) return;

        setState(() {
          _children = children;

          if (_children.isNotEmpty && _selectedChildId == null) {
            _selectedChild = _children.first;
            _selectedChildId = _getChildId(_children.first);
          }
        });

        if (_selectedChildId != null) {
          await _loadTrustedContacts(_selectedChildId!);
        }
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load children: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading children: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTrustedContacts(String childId) async {
    try {
      final response = await ApiClient.getTrustedContacts(childId);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          _trustedContacts = data.cast<Map<String, dynamic>>();
        });

        _startTrustedContactsPolling();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trusted contacts: $e')),
      );
    }
  }

  Future<void> _fetchTrustedContacts(String childId) async {
    try {
      final response = await ApiClient.getTrustedContacts(childId);

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        final newContacts = data.cast<Map<String, dynamic>>();

        if (_contactsChanged(newContacts)) {
          setState(() {
            _trustedContacts = newContacts;
          });
        }

        final hasPendingContacts = _trustedContacts.any(
          (contact) =>
              (contact['status'] ?? '').toString().toLowerCase() == 'pending',
        );

        if (!hasPendingContacts) {
          _stopTrustedContactsPolling();
        }
      }
    } catch (_) {}
  }

  bool _contactsChanged(List<Map<String, dynamic>> newContacts) {
    if (_trustedContacts.length != newContacts.length) return true;

    for (int i = 0; i < _trustedContacts.length; i++) {
      final oldContact = _trustedContacts[i];
      final newContact = newContacts[i];

      if (oldContact['status'] != newContact['status'] ||
          oldContact['email'] != newContact['email'] ||
          oldContact['relationship'] != newContact['relationship'] ||
          oldContact['role'] != newContact['role']) {
        return true;
      }
    }

    return false;
  }

  void _startTrustedContactsPolling() {
    _stopTrustedContactsPolling();

    if (_selectedChildId == null || !mounted) return;

    final hasPendingContacts = _trustedContacts.any(
      (contact) =>
          (contact['status'] ?? '').toString().toLowerCase() == 'pending',
    );

    if (!hasPendingContacts && _trustedContacts.isNotEmpty) return;

    _isPolling = true;

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _selectedChildId == null) {
        _stopTrustedContactsPolling();
        return;
      }

      _fetchTrustedContacts(_selectedChildId!);
    });
  }

  void _stopTrustedContactsPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  void _selectChild(Map<String, dynamic> child) {
    _stopTrustedContactsPolling();

    setState(() {
      _selectedChild = child;
      _selectedChildId = _getChildId(child);
      _trustedContacts = [];
    });

    if (_selectedChildId != null) {
      _loadTrustedContacts(_selectedChildId!);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  void _showNoChildSelectedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a child first'),
        backgroundColor: Color(0xFFF59E0B),
      ),
    );
  }

  void _goToParentDrawings() {
    if (_selectedChildId == null) {
      _showNoChildSelectedMessage();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParentDrawingsScreen(
          childId: _selectedChildId!,
          childName: _selectedChild?['name']?.toString(),
        ),
      ),
    );
  }

  void _goToChildReport() {
    if (_selectedChildId == null) {
      _showNoChildSelectedMessage();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildReportScreen(
          childId: _selectedChildId!,
          childName: _selectedChild?['name']?.toString(),
        ),
      ),
    );
  }

  void _onParentNavTap(int index) {
    if (index == 0) return;

    if (index == 1 || index == 3) {
      _goToChildReport();
      return;
    }

    if (index == 2) {
      _goToParentDrawings();
    }
  }

  void _showAddChildDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final ageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _cardColor,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Child',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: usernameController,
                    style: GoogleFonts.inter(color: _primaryTextColor),
                    decoration: _inputDecoration('Username'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    style: GoogleFonts.inter(color: _primaryTextColor),
                    decoration: _inputDecoration('Password'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    style: GoogleFonts.inter(color: _primaryTextColor),
                    decoration: _inputDecoration('Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: _primaryTextColor),
                    decoration: _inputDecoration('Age'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final parsed = int.tryParse(v);
                      if (parsed == null) return 'Enter a valid number';
                      if (parsed <= 0) return 'Age must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            try {
                              final response = await ApiClient.addChild(
                                username: usernameController.text.trim(),
                                password: passwordController.text,
                                name: nameController.text.trim(),
                                age: int.parse(ageController.text),
                              );

                              if (response.statusCode == 201 ||
                                  response.statusCode == 200) {
                                if (Navigator.of(dialogContext).canPop()) {
                                  Navigator.pop(dialogContext);
                                }

                                await _loadChildren();

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Child added successfully'),
                                    backgroundColor: Color(0xFF22C55E),
                                  ),
                                );
                              } else {
                                final data = jsonDecode(response.body);

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      data['detail'] ?? 'Failed to add child',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Add Child'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        color: _secondaryTextColor,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: _fieldFillColor,
    );
  }

  void _showInviteTrustedDialog(String childId) {
    final emailController = TextEditingController();
    String? selectedRelationship;
    bool isInviting = false;

    const relationshipOptions = [
      'Teacher',
      'Relative',
      'Family Friend',
      'Other',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: _cardColor,
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite Trusted Contact',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _primaryTextColor,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isInviting,
                  style: GoogleFonts.inter(color: _primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'contact@email.com',
                    filled: true,
                    fillColor: _dialogFieldFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _dialogFieldFillColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRelationship,
                      isExpanded: true,
                      dropdownColor: _cardColor,
                      hint: Text(
                        'Select relationship',
                        style: TextStyle(color: _secondaryTextColor),
                      ),
                      style: GoogleFonts.inter(
                        color: _primaryTextColor,
                        fontSize: 14,
                      ),
                      items: relationshipOptions.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: isInviting
                          ? null
                          : (value) {
                              setLocalState(() {
                                selectedRelationship = value;
                              });
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isInviting
                        ? null
                        : () async {
                            if (emailController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter an email address'),
                                ),
                              );
                              return;
                            }

                            setLocalState(() => isInviting = true);

                            try {
                              final response =
                                  await ApiClient.inviteTrustedContact(
                                childId,
                                emailController.text.trim(),
                                relationship: selectedRelationship,
                              );

                              if (response.statusCode == 201 ||
                                  response.statusCode == 200) {
                                if (Navigator.of(dialogContext).canPop()) {
                                  Navigator.pop(dialogContext);
                                }

                                await _fetchTrustedContacts(childId);

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invitation sent successfully'),
                                    backgroundColor: Color(0xFF22C55E),
                                  ),
                                );
                              } else {
                                setLocalState(() => isInviting = false);

                                final data = jsonDecode(response.body);

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      data['detail'] ??
                                          'Failed to send invitation',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              setLocalState(() => isInviting = false);

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                    icon: isInviting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.email_outlined),
                    label: Text(isInviting ? 'Sending...' : 'Send Invitation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43A047),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRemoveTrustedContactDialog(
    String childId,
    String trustedId,
    String email,
  ) {
    final reasonController = TextEditingController();
    String? errorText;
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: _cardColor,
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remove Trusted Contact',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _primaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Contact: $email',
                  style: TextStyle(color: _secondaryTextColor),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  enabled: !isDeleting,
                  style: GoogleFonts.inter(color: _primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'Please provide a reason...',
                    filled: true,
                    fillColor: _dialogFieldFillColor,
                    errorText: errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    if (errorText != null && value.trim().length >= 3) {
                      setLocalState(() => errorText = null);
                    }
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isDeleting
                            ? null
                            : () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () async {
                                final reason = reasonController.text.trim();

                                if (reason.isEmpty) {
                                  setLocalState(() {
                                    errorText = 'Reason is required';
                                  });
                                  return;
                                }

                                if (reason.length < 3) {
                                  setLocalState(() {
                                    errorText =
                                        'Reason must be at least 3 characters';
                                  });
                                  return;
                                }

                                setLocalState(() => isDeleting = true);

                                try {
                                  final response =
                                      await ApiClient.removeTrustedContact(
                                    childId,
                                    trustedId,
                                    reason,
                                  );

                                  if (Navigator.of(dialogContext).canPop()) {
                                    Navigator.pop(dialogContext);
                                  }

                                  if (response.statusCode == 200) {
                                    await _fetchTrustedContacts(childId);

                                    if (!mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Trusted contact removed successfully',
                                        ),
                                        backgroundColor: Color(0xFF22C55E),
                                      ),
                                    );
                                  } else {
                                    if (!mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Failed to remove contact'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (Navigator.of(dialogContext).canPop()) {
                                    Navigator.pop(dialogContext);
                                  }

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Remove'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _pageBackground,
      bottomNavigationBar: ParentBottomNavBar(
        currentIndex: 0,
        onTap: _onParentNavTap,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF43A047),
                        ),
                      ),
                    )
                  : isWideScreen
                      ? _buildTwoColumnLayout()
                      : _buildSingleColumnLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: isMobile ? 18 : 24,
      ),
      decoration: BoxDecoration(
        color: _headerColor,
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your child profiles, reports and trusted contacts',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.35,
                    color: _secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() => _isDarkMode = !_isDarkMode);
                      },
                      icon: Icon(
                        _isDarkMode
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: _isDarkMode
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF6B7280),
                        backgroundColor: _isDarkMode
                            ? const Color(0xFFFBBF24).withValues(alpha: 0.10)
                            : const Color(0xFFE8F5E9),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF43A047),
                          side: const BorderSide(color: Color(0xFF43A047)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your child profiles, reports and trusted contacts',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() => _isDarkMode = !_isDarkMode);
                      },
                      icon: Icon(
                        _isDarkMode
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: _isDarkMode
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF6B7280),
                        backgroundColor: _isDarkMode
                            ? const Color(0xFFFBBF24).withValues(alpha: 0.10)
                            : const Color(0xFFE8F5E9),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF43A047),
                        side: const BorderSide(color: Color(0xFF43A047)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildTwoColumnLayout() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF43A047),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 11, child: _buildChildrenCard()),
            Expanded(flex: 19, child: _buildChildDetails()),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleColumnLayout() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF43A047),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildChildrenCard(),
            const SizedBox(height: 16),
            _buildChildDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenCard() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: EdgeInsets.all(isMobile ? 0 : 20),
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Children',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAddChildDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Child'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        'My Children',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primaryTextColor,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddChildDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Child'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 24),
          if (_children.isEmpty)
            _buildEmptyState(
              icon: Icons.family_restroom,
              title: 'No children added yet',
              subtitle: 'Click "Add Child" to get started',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _children.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildChildTile(_children[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChildTile(Map<String, dynamic> child) {
    final childId = _getChildId(child);
    final isSelected = _selectedChildId == childId;
    final name = (child['name'] ?? 'Unknown').toString();
    final age = child['age']?.toString() ?? 'N/A';
    final username = (child['username'] ?? 'N/A').toString();

    return InkWell(
      onTap: () => _selectChild(child),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _selectedChildBg : _unselectedChildBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF43A047) : _borderColor,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  isSelected ? const Color(0xFF43A047) : Colors.grey,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Age $age • @$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildDetails() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_selectedChild == null) {
      return Container(
        margin: EdgeInsets.all(isMobile ? 0 : 20),
        padding: EdgeInsets.all(isMobile ? 18 : 28),
        decoration: _cardDecoration(),
        child: _buildEmptyState(
          icon: Icons.child_care,
          title: 'Select a child',
          subtitle: 'Choose a child to view reports and trusted contacts',
        ),
      );
    }

    final child = _selectedChild!;
    final name = (child['name'] ?? 'Unknown').toString();
    final username = (child['username'] ?? 'N/A').toString();
    final age = child['age']?.toString() ?? 'N/A';
    final alertConsent = child['alert_consent'] == true ||
        child['alertConsent'] == true ||
        child['alerts_enabled'] == true;

    return Container(
      margin: EdgeInsets.all(isMobile ? 0 : 20),
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 28 : 34,
                backgroundColor: const Color(0xFF43A047),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 22 : 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 21 : 24,
                        fontWeight: FontWeight.bold,
                        color: _primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildInfoChip(Icons.cake_outlined, 'Age $age'),
              _buildInfoChip(
                alertConsent
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                alertConsent ? 'Alerts ON' : 'Alerts OFF',
                isAlert: true,
                alertStatus: alertConsent,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Divider(color: _dividerColor),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final smallWidth = constraints.maxWidth < 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trusted Contacts',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: smallWidth ? double.infinity : null,
                        child: ElevatedButton.icon(
                          onPressed: _selectedChildId == null
                              ? null
                              : _goToParentDrawings,
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text('View Child Drawings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: smallWidth ? double.infinity : null,
                        child: ElevatedButton.icon(
                          onPressed:
                              _selectedChildId == null ? null : _goToChildReport,
                          icon: const Icon(Icons.analytics_outlined, size: 18),
                          label: const Text('View Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: smallWidth ? double.infinity : null,
                        child: ElevatedButton.icon(
                          onPressed: _selectedChildId == null
                              ? null
                              : () =>
                                  _showInviteTrustedDialog(_selectedChildId!),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Invite'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _selectedChildId == null
                            ? null
                            : () => _loadTrustedContacts(_selectedChildId!),
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          if (_trustedContacts.isEmpty)
            _buildEmptyState(
              icon: Icons.people_outline,
              title: 'No trusted contacts yet',
              subtitle: 'Invite trusted contacts to monitor this child',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _trustedContacts.length,
              separatorBuilder: (_, __) => Divider(color: _dividerColor),
              itemBuilder: (context, index) {
                return _buildTrustedContactRow(_trustedContacts[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrustedContactRow(Map<String, dynamic> contact) {
    final email = (contact['email'] ?? 'No email').toString();
    final relationship =
        (contact['relationship'] ?? 'Trusted Contact').toString();
    final status = (contact['status'] ?? 'pending').toString().toLowerCase();
    final role = (contact['role'] ?? '').toString();
    final trustedId = _getTrustedId(contact);

    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'accepted':
      case 'active':
        statusColor = const Color(0xFF16A34A);
        statusLabel = 'Accepted';
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC2626);
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Pending';
    }

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(Icons.person_outline, color: statusColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role.isEmpty ? relationship : '$relationship • $role',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: _selectedChildId == null || trustedId == null
              ? null
              : () => _showRemoveTrustedContactDialog(
                    _selectedChildId!,
                    trustedId,
                    email,
                  ),
          icon: const Icon(Icons.delete_outline),
          color: const Color(0xFFDC2626),
          tooltip: 'Remove',
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label, {
    bool isAlert = false,
    bool alertStatus = false,
  }) {
    final bgColor = isAlert
        ? (alertStatus ? const Color(0xFFF0F9F2) : const Color(0xFFFEF2F2))
        : (_isDarkMode ? _subtleSurfaceTint : const Color(0xFFF3F4F6));

    final textColor = isAlert
        ? (alertStatus ? const Color(0xFF43A047) : const Color(0xFFDC2626))
        : (_isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _emptyStateIconBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 42, color: _emptyStateIconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _secondaryTextColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _emptyStateIconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _borderColor, width: 1.3),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: _isDarkMode ? 0.25 : 0.05),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}