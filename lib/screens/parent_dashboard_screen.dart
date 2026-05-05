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

          if (_children.isEmpty) {
            _selectedChild = null;
            _selectedChildId = null;
            _trustedContacts = [];
          } else if (_selectedChildId == null ||
              !_children.any((c) => _getChildId(c) == _selectedChildId)) {
            _selectedChild = _children.first;
            _selectedChildId = _getChildId(_children.first);
          } else {
            _selectedChild = _children.firstWhere(
              (c) => _getChildId(c) == _selectedChildId,
              orElse: () => _children.first,
            );
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

  Widget _buildHeader() {
    final isCompact = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 20 : 32,
        vertical: isCompact ? 20 : 24,
      ),
      decoration: BoxDecoration(
        color: _headerColor,
        border: Border(
          bottom: BorderSide(color: _borderColor),
        ),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _primaryTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your child profiles and trusted contacts',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isDarkMode = !_isDarkMode;
                        });
                      },
                      icon: Icon(
                        _isDarkMode
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _primaryTextColor,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isDarkMode = !_isDarkMode;
                        });
                      },
                      icon: Icon(
                        _isDarkMode
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                    ),
                  ],
                ),
              ],
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
                  ? const Center(child: CircularProgressIndicator())
                  : isWideScreen
                      ? _buildTwoColumnLayout()
                      : _buildSingleColumnLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      children: [
        Expanded(flex: 1, child: _buildChildrenCard()),
        Expanded(flex: 2, child: _buildChildDetails()),
      ],
    );
  }

  Widget _buildSingleColumnLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildChildrenCard(),
          const SizedBox(height: 16),
          _buildChildDetails(),
        ],
      ),
    );
  }