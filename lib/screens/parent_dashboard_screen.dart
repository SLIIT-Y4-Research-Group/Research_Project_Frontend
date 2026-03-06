import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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
      builder: (context) => AlertDialog(
        title: const Text('Add Child'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            child: const Text('Add'),
          ),
        ],
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
            borderRadius: BorderRadius.circular(16),
          ),
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
                    const Text(
                      'Invite Trusted Contact',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                const Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isInviting,
                  decoration: InputDecoration(
                    hintText: 'contact@email.com',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
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
                const Text(
                  'Relationship',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRelationship,
                      isExpanded: true,
                      hint: Text(
                        'Select relationship',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
            borderRadius: BorderRadius.circular(16),
          ),
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
                    const Text(
                      'Remove Trusted Contact',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Reason for removal
                const Text(
                  'Reason for removal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  enabled: !isDeleting,
                  decoration: InputDecoration(
                    hintText: 'Please provide a reason for removing this contact...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
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
                        color: errorText != null ? Colors.red : const Color(0xFF22C55E),
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
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
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
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                            : const Text(
                                'Remove',
                                style: TextStyle(
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
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF22C55E),
                      side: const BorderSide(color: Color(0xFF22C55E)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Content
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Children List
        Expanded(
          flex: 2,
          child: _buildChildrenList(),
        ),
        
        // Right Column - Child Details
        Expanded(
          flex: 3,
          child: _buildChildDetails(),
        ),
      ],
    );
  }

  Widget _buildSingleColumnLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildChildrenList(),
          if (_selectedChild != null) _buildChildDetails(),
        ],
      ),
    );
  }

  Widget _buildChildrenList() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              const Text(
                'My Children',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddChildDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Child'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_children.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No children added yet.\nClick "Add Child" to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _children.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final child = _children[index];
                final childId = child['id'];
                final isSelected = _selectedChildId == childId;

                return InkWell(
                  onTap: () => _selectChild(child),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF22C55E) : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    child['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Age: ${child['age'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Username: ${child['username'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChildDetails() {
    if (_selectedChild == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Select a child to view details',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child Details Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Child Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Information Section
                  const Text(
                    'Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Name:', _selectedChild!['name'] ?? 'N/A'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Age:', _selectedChild!['age']?.toString() ?? 'N/A'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Username:', _selectedChild!['username'] ?? 'N/A'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Alerts consent status:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (_selectedChild!['alerts_consent'] == true)
                              ? const Color(0xFFE8F5E9)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (_selectedChild!['alerts_consent'] == true) ? 'ON' : 'OFF',
                          style: TextStyle(
                            color: (_selectedChild!['alerts_consent'] == true)
                                ? const Color(0xFF22C55E)
                                : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Trusted Contacts Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trusted Contacts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showInviteTrustedDialog(_selectedChildId!),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Invite'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_trustedContacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No trusted contacts invited yet.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _trustedContacts.length,
                      separatorBuilder: (context, index) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final contact = _trustedContacts[index];
                        final status = contact['status'] ?? 'pending';
                        final isAccepted = status.toLowerCase() == 'accepted';
                        
                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact['email'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    contact['relationship'] ?? contact['role'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAccepted 
                                        ? const Color(0xFFE8F5E9)
                                        : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    status[0].toUpperCase() + status.substring(1),
                                    style: TextStyle(
                                      color: isAccepted 
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFFFF9800),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  color: Colors.red[400],
                                  onPressed: () => _showRemoveTrustedContactDialog(
                                    _selectedChildId!,
                                    contact['id']?.toString() ?? '',
                                    contact['email'] ?? 'N/A',
                                  ),
                                  tooltip: 'Delete',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
