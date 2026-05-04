import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'main_home_screen.dart';

class ChildLoginScreen extends StatefulWidget {
  const ChildLoginScreen({super.key});

  @override
  State<ChildLoginScreen> createState() => _ChildLoginScreenState();
}

class _ChildLoginScreenState extends State<ChildLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.loginChild(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        await _authService.saveToken(token, 'child');

        final prefs = await SharedPreferences.getInstance();

        final String childId = (
  data['child']?['id'] ??
  data['child_id'] ??
  data['id'] ??
  data['student_id'] ??
  ''
).toString();

final String childName = (
  data['child']?['name'] ??
  data['child_name'] ??
  data['name'] ??
  data['student_name'] ??
  _usernameController.text.trim()
).toString();

await prefs.setString('child_id', childId);
await prefs.setString('child_name', childName);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainHomeScreen()),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['detail'] ?? 'Login failed'),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    final cardWidth = isWeb ? 450.0 : screenWidth * 0.9;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB3E5FC),
                  Color(0xFFB2DFDB),
                  Color(0xFFFFF9C4),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Lottie.asset(
              'assets/lottie/Blue Bubbles Animation.json',
              fit: BoxFit.cover,
              repeat: true,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 30,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: cardWidth,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text(
                                        'Student Login',
                                        style: GoogleFonts.poppins(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E88E5),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: Text(
                                        'Welcome back! Let\'s see how you feel today.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.nunito(
                                          fontSize: 15,
                                          color: const Color(0xFF5E35B1),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    TextFormField(
                                      controller: _usernameController,
                                      enabled: !_isLoading,
                                      decoration: InputDecoration(
                                        labelText: 'Username',
                                        labelStyle: GoogleFonts.nunito(
                                          color: const Color(0xFF5E35B1),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.person_rounded,
                                          color: Color(0xFF1E88E5),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withValues(alpha: 0.7),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF1E88E5),
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter username';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      enabled: !_isLoading,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: GoogleFonts.nunito(
                                          color: const Color(0xFF5E35B1),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.lock_rounded,
                                          color: Color(0xFF1E88E5),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            color: const Color(0xFF1E88E5),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withValues(alpha: 0.7),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF1E88E5),
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter password';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 28),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: _isLoading
                                                  ? [Colors.grey, Colors.grey]
                                                  : [
                                                      const Color(0xFF42A5F5),
                                                      const Color(0xFF1E88E5),
                                                    ],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 3,
                                                    ),
                                                  )
                                                : Text(
                                                    'Login',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    )
                                        .animate(
                                          onPlay: (controller) =>
                                              controller.repeat(reverse: true),
                                        )
                                        .shimmer(
                                          duration: 2000.ms,
                                          color: Colors.white.withValues(alpha: 0.3),
                                        ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: TextButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Please contact your teacher for password help',
                                                style: GoogleFonts.nunito(),
                                              ),
                                              backgroundColor: const Color(0xFF1E88E5),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Forgot password?',
                                          style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            color: const Color(0xFF5E35B1),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}