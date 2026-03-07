import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final _authService = AuthService();
  List<Map<String, dynamic>> _children = [];
  String? _selectedChildId;
  Map<String, dynamic>? _selectedChild;
  List<Map<String, dynamic>> _trustedContacts = [];
  bool _isLoading = false;
  Timer? _pollingTimer;
  bool _isPolling = false;
  bool _isDarkMode = false;

  // Color helpers for theme support
  // Light mode: Refined healthcare-inspired palette with soft green tints
  // Dark mode: Deep neutral grays with high contrast
  Color get _pageBackground => _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF6F8F7);
  Color get _cardColor => _isDarkMode ? const Color(0xFF1F2937) : Colors.white;
  Color get _headerColor => _isDarkMode ? const Color(0xFF1A2332) : const Color(0xFFF1F8F4);
  Color get _primaryTextColor => _isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1F2937);
  Color get _secondaryTextColor => _isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get _borderColor => _isDarkMode ? Colors.white.withOpacity(0.1) : const Color(0xFFE3EAE5);
  Color get _emptyStateIconBg => _isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F6F4);
  Color get _emptyStateIconColor => _isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
  Color get _selectedChildBg => _isDarkMode ? const Color(0xFF1E3A2E) : const Color(0xFFEEF7EF);
  Color get _unselectedChildBg => _isDarkMode ? const Color(0xFF374151) : const Color(0xFFF8FCF9);
  Color get _fieldFillColor => _isDarkMode ? const Color(0xFF374151) : const Color(0xFFF8FAFB);
  Color get _dialogFieldFillColor => _isDarkMode ? const Color(0xFF374151) : const Color(0xFFF5F7F6);
  Color get _dividerColor => _isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFFE8ECEA);
  Color get _subtleSurfaceTint => _isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF8FCF9);

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.getChildren();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _children = data.cast<Map<String, dynamic>>();
          // Auto-select first child if available
          if (_children.isNotEmpty && _selectedChildId == null) {
            _selectedChildId = _children[0]['id'];
            _selectedChild = _children[0];
            _loadTrustedContacts(_selectedChildId!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading children: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTrustedContacts(String childId) async {
    try {
      final response = await ApiClient.getTrustedContacts(childId);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _trustedContacts = data.cast<Map<String, dynamic>>();
          });
        }
        // Start polling after initial load
        _startTrustedContactsPolling();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trusted contacts: $e')),
        );
      }
    }
  }

  void _startTrustedContactsPolling() {
    // Stop any existing polling
    _stopTrustedContactsPolling();
    
    // Only start polling if a child is selected
    if (_selectedChildId == null || !mounted) return;
    
    // Check if there are any pending contacts
    final hasPendingContacts = _trustedContacts.any(
      (contact) => (contact['status'] ?? '').toLowerCase() == 'pending'
    );
    
    // If no pending contacts, don't poll (optimization)
    if (!hasPendingContacts && _trustedContacts.isNotEmpty) return;
    
    _isPolling = true;
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
  
  Future<void> _fetchTrustedContacts(String childId) async {
    try {
      final response = await ApiClient.getTrustedContacts(childId);
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        final newContacts = data.cast<Map<String, dynamic>>();
        
        // Only update if data changed
        if (_contactsChanged(newContacts)) {
          setState(() {
            _trustedContacts = newContacts;
          });
          
          // Stop polling if no more pending contacts
          final hasPendingContacts = _trustedContacts.any(
            (contact) => (contact['status'] ?? '').toLowerCase() == 'pending'
          );
          if (!hasPendingContacts) {
            _stopTrustedContactsPolling();
          }
        }
      }
    } catch (e) {
      // Silently fail during polling to avoid spamming errors
      debugPrint('Polling error: $e');
    }
  }
  
  bool _contactsChanged(List<Map<String, dynamic>> newContacts) {
    if (_trustedContacts.length != newContacts.length) return true;
    
    for (int i = 0; i < _trustedContacts.length; i++) {
      final oldContact = _trustedContacts[i];
      final newContact = newContacts[i];
      if (oldContact['status'] != newContact['status'] ||
          oldContact['email'] != newContact['email']) {
        return true;
      }
    }
    return false;
  }

  void _selectChild(Map<String, dynamic> child) {
    // Stop polling for previous child
    _stopTrustedContactsPolling();
    
    setState(() {
      _selectedChildId = child['id'];
      _selectedChild = child;
      _trustedContacts = [];
    });
    _loadTrustedContacts(child['id']);
  }

  void _showAddChildDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final ageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: GoogleFonts.inter(fontSize: 14, color: _secondaryTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: _fieldFillColor,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    style: GoogleFonts.inter(color: _primaryTextColor),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: GoogleFonts.inter(fontSize: 14, color: _secondaryTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: _fieldFillColor,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    style: GoogleFonts.inter(color: _primaryTextColor),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: GoogleFonts.inter(fontSize: 14, color: _secondaryTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: _fieldFillColor,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: _primaryTextColor),
                    decoration: InputDecoration(
                      labelText: 'Age',
                      labelStyle: GoogleFonts.inter(fontSize: 14, color: _secondaryTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: _fieldFillColor,
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: _isDarkMode ? Colors.grey[600]! : const Color(0xFFD1D5DB),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                final response = await ApiClient.addChild(
                                  username: usernameController.text.trim(),
                                  password: passwordController.text,
                                  name: nameController.text.trim(),
                                  age: int.parse(ageController.text),
                                );

                                if (response.statusCode == 201 || response.statusCode == 200) {
                                  Navigator.pop(context);
                                  _loadChildren();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Child added successfully')),
                                    );
                                  }
                                } else {
                                  final data = jsonDecode(response.body);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(data['detail'] ?? 'Failed to add child')),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Add Child',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  void _showInviteTrustedDialog(String childId) {
    final emailController = TextEditingController();
    String? selectedRelationship;
    bool isInviting = false;
    final relationshipOptions = ['Teacher', 'Relative', 'Family Friend', 'Other'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Invite Trusted Contact',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _primaryTextColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Email Address
                Text(
                  'Email Address',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isInviting,
                  style: GoogleFonts.inter(color: _primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'contact@email.com',
                    hintStyle: TextStyle(color: _secondaryTextColor.withOpacity(0.6)),
                    filled: true,
                    fillColor: _dialogFieldFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Relationship
                Text(
                  'Relationship',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
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
                        style: TextStyle(color: _secondaryTextColor.withOpacity(0.6)),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down, color: _secondaryTextColor),
                      style: GoogleFonts.inter(color: _primaryTextColor, fontSize: 14),
                      items: relationshipOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: isInviting ? null : (String? newValue) {
                        setState(() {
                          selectedRelationship = newValue;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Info text
                Text(
                  'They will receive an email and must accept to connect.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Send Invitation Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isInviting ? null : () async {
                      if (emailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter an email address')),
                        );
                        return;
                      }
                      
                      setState(() {
                        isInviting = true;
                      });
                      
                      try {
                        final response = await ApiClient.inviteTrustedContact(
                          childId,
                          emailController.text.trim(),
                          relationship: selectedRelationship,
                        );

                        if (response.statusCode == 201 || response.statusCode == 200) {
                          Navigator.pop(context);
                          // Immediately refresh the list
                          _fetchTrustedContacts(childId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invitation sent successfully'),
                                backgroundColor: Color(0xFF22C55E),
                              ),
                            );
                          }
                        } else {
                          setState(() {
                            isInviting = false;
                          });
                          final data = jsonDecode(response.body);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(data['detail'] ?? 'Failed to send invitation')),
                            );
                          }
                        }
                      } catch (e) {
                        setState(() {
                          isInviting = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    icon: isInviting 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.email_outlined, size: 20),
                    label: Text(
                      isInviting ? 'Sending...' : 'Send Invitation Email',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43A047),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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

  void _showRemoveTrustedContactDialog(String childId, String trustedId, String email) {
    final reasonController = TextEditingController();
    String? errorText;
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remove Trusted Contact',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _primaryTextColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: isDeleting ? null : () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Contact: $email',
                  style: TextStyle(
                    fontSize: 15,
                    color: _secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Reason for removal
                Text(
                  'Reason for removal',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  enabled: !isDeleting,
                  style: GoogleFonts.inter(color: _primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'Please provide a reason for removing this contact...',
                    hintStyle: TextStyle(color: _secondaryTextColor.withOpacity(0.6)),
                    filled: true,
                    fillColor: _dialogFieldFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: errorText != null 
                          ? const BorderSide(color: Colors.red, width: 1.5)
                          : BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: errorText != null 
                          ? const BorderSide(color: Colors.red, width: 1.5)
                          : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: errorText != null ? Colors.red : const Color(0xFF43A047),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    errorText: errorText,
                  ),
                  onChanged: (value) {
                    if (errorText != null && value.trim().length >= 3) {
                      setState(() {
                        errorText = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isDeleting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: _isDarkMode ? Colors.grey[600]! : const Color(0xFFD1D5DB),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDeleting ? null : () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            setState(() {
                              errorText = 'Reason is required';
                            });
                            return;
                          }
                          if (reason.length < 3) {
                            setState(() {
                              errorText = 'Reason must be at least 3 characters';
                            });
                            return;
                          }
                          
                          setState(() {
                            isDeleting = true;
                          });
                          
                          try {
                            final response = await ApiClient.removeTrustedContact(
                              childId,
                              trustedId,
                              reason,
                            );

                            Navigator.pop(context);
                            
                            if (response.statusCode == 200) {
                              // Immediately refresh the list
                              _fetchTrustedContacts(childId);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Trusted contact removed successfully'),
                                    backgroundColor: Color(0xFF22C55E),
                                  ),
                                );
                              }
                            } else {
                              final data = jsonDecode(response.body);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to remove contact: ${data['message'] ?? 'Unknown error'}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isDeleting 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Remove',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
  void dispose() {
    _stopTrustedContactsPolling();
    super.dispose();
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;
    
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Main Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF43A047)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: _headerColor,
        border: Border(
          bottom: BorderSide(
            color: _borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.04),
            blurRadius: _isDarkMode ? 8 : 12,
            offset: Offset(0, _isDarkMode ? 2 : 3),
          ),
          if (!_isDarkMode)
            BoxShadow(
              color: const Color(0xFF43A047).withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _primaryTextColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your child profiles and trusted contacts',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _secondaryTextColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Dark Mode Toggle Button
              IconButton(
                onPressed: () {
                  setState(() {
                    _isDarkMode = !_isDarkMode;
                  });
                },
                icon: Icon(
                  _isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 22,
                ),
                tooltip: _isDarkMode ? 'Disable dark mode' : 'Enable dark mode',
                style: IconButton.styleFrom(
                  foregroundColor: _isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF6B7280),
                  backgroundColor: _isDarkMode 
                      ? const Color(0xFFFBBF24).withOpacity(0.1)
                      : const Color(0xFFE8F5E9).withOpacity(0.5),
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Logout Button
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 18),
                label: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF43A047),
                  side: const BorderSide(color: Color(0xFF43A047), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Children List
        Expanded(
          flex: 11,
          child: _buildChildrenCard(),
        ),
        
        // Right Column - Child Details
        Expanded(
          flex: 19,
          child: _buildChildDetails(),
        ),
      ],
    );
  }

  Widget _buildSingleColumnLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildChildrenCard(),
          const SizedBox(height: 20),
          if (_selectedChild != null) _buildChildDetails(),
        ],
      ),
    );
  }

  Widget _buildChildrenCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _borderColor,
          width: _isDarkMode ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
            blurRadius: _isDarkMode ? 20 : 24,
            offset: Offset(0, _isDarkMode ? 4 : 6),
          ),
          if (!_isDarkMode)
            BoxShadow(
              color: const Color(0xFF43A047).withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Children',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryTextColor,
                  letterSpacing: -0.3,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddChildDialog,
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add Child',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_children.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _emptyStateIconBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.family_restroom,
                        size: 48,
                        color: _emptyStateIconColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No children added yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click "Add Child" to get started',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _emptyStateIconColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _children.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final child = _children[index];
                return _buildChildTile(child);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChildTile(Map<String, dynamic> child) {
    final childId = child['id'];
    final isSelected = _selectedChildId == childId;
    final name = child['name'] ?? 'Unknown';
    final age = child['age'];
    final username = child['username'] ?? 'N/A';

    return InkWell(
      onTap: () => _selectChild(child),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _selectedChildBg : _unselectedChildBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF43A047) 
                : (_isDarkMode ? _borderColor : const Color(0xFFE3EAE5)),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: !_isDarkMode && isSelected ? [
            BoxShadow(
              color: const Color(0xFF43A047).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? [const Color(0xFF43A047), const Color(0xFF66BB6A)]
                      : [const Color(0xFF9CA3AF), const Color(0xFFD1D5DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  name[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _primaryTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip('Active', true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Age $age • @$username',
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

  Widget _buildStatusChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF43A047) : const Color(0xFF9CA3AF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildChildDetails() {
    if (_selectedChild == null) {
      return Container(
        margin: const EdgeInsets.only(top: 20, right: 20, bottom: 20),
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _borderColor,
            width: _isDarkMode ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
              blurRadius: _isDarkMode ? 20 : 24,
              offset: Offset(0, _isDarkMode ? 4 : 6),
            ),
            if (!_isDarkMode)
              BoxShadow(
                color: const Color(0xFF43A047).withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _emptyStateIconBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 56,
                  color: _emptyStateIconColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select a child to view details',
                style: GoogleFonts.inter(
                  color: _secondaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final name = _selectedChild!['name'] ?? 'Unknown';
    final age = _selectedChild!['age'];
    final username = _selectedChild!['username'] ?? 'N/A';
    final alertConsent = _selectedChild!['alerts_consent'] == true;

    return Container(
      margin: const EdgeInsets.only(top: 20, right: 20, bottom: 20),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _borderColor,
              width: _isDarkMode ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.05),
                blurRadius: _isDarkMode ? 20 : 24,
                offset: Offset(0, _isDarkMode ? 4 : 6),
              ),
              if (!_isDarkMode)
                BoxShadow(
                  color: const Color(0xFF43A047).withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Child Summary Section
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF43A047).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _primaryTextColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '@$username',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: _secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Info Chips
              Row(
                children: [
                  _buildInfoChip(Icons.cake_outlined, 'Age $age'),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    alertConsent ? Icons.notifications_active : Icons.notifications_off,
                    alertConsent ? 'Alerts ON' : 'Alerts OFF',
                    isAlert: true,
                    alertStatus: alertConsent,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              Divider(color: _dividerColor, height: 1),
              const SizedBox(height: 32),
              
              // Trusted Contacts Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trusted Contacts',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showInviteTrustedDialog(_selectedChildId!),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: Text(
                      'Invite',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43A047),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (_trustedContacts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _emptyStateIconBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.people_outline,
                            size: 40,
                            color: _emptyStateIconColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No trusted contacts yet',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Invite trusted contacts to monitor',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _emptyStateIconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _trustedContacts.length,
                  separatorBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: _dividerColor, height: 1),
                  ),
                  itemBuilder: (context, index) {
                    final contact = _trustedContacts[index];
                    return _buildTrustedContactRow(contact);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {bool isAlert = false, bool alertStatus = false}) {
    final bgColor = isAlert
        ? (alertStatus ? const Color(0xFFF0F9F2) : const Color(0xFFFEF2F2))
        : const Color(0xFFF3F4F6);
    final textColor = isAlert
        ? (alertStatus ? const Color(0xFF43A047) : const Color(0xFFDC2626))
        : const Color(0xFF6B7280);

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

  Widget _buildTrustedContactRow(Map<String, dynamic> contact) {
    final status = contact['status'] ?? 'pending';
    final isAccepted = status.toLowerCase() == 'accepted';
    final email = contact['email'] ?? 'N/A';
    final relationship = contact['relationship'] ?? contact['role'] ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Contact Info
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isAccepted
                        ? const Color(0xFFF0F9F2)
                        : const Color(0xFFFEF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_outline,
                      size: 22,
                      color: isAccepted
                          ? const Color(0xFF43A047)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primaryTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        relationship,
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
          const SizedBox(width: 12),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isAccepted
                  ? const Color(0xFFF0F9F2)
                  : const Color(0xFFFEF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: GoogleFonts.inter(
                color: isAccepted
                    ? const Color(0xFF43A047)
                    : const Color(0xFFF59E0B),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Delete Button
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: const Color(0xFFDC2626),
              onPressed: () => _showRemoveTrustedContactDialog(
                _selectedChildId!,
                contact['id']?.toString() ?? '',
                email,
              ),
              tooltip: 'Remove',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

}
