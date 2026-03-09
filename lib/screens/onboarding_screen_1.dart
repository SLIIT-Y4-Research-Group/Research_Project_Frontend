import 'package:flutter/material.dart';
import 'onboarding_screen_2.dart';

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Corner ellipses (screen 1)
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF71D483),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF71D483),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top section with logo
                Expanded(
                  flex: 6,
                  child: Center(
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Image.asset(
                        'assets/images/anim_logo.gif',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Bottom section
                Expanded(
                  flex: 4,
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  const Text(
                                    'ඔබ සාදරයෙන් පිළිගනිමු! ',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  const Text(
                                    'ඔබගේ දරුවාගේ හැඟීම්, සිතුවිලි සහ දෛනික මනෝ සුවතාවය සැලකිල්ලෙන් නිරීක්ෂණය කිරීමට සහය වන ආරක්ෂිත මිතුරා.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Page indicators
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildIndicator(true),
                                      const SizedBox(width: 8),
                                      _buildIndicator(false),
                                      const SizedBox(width: 8),
                                      _buildIndicator(false),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: _buildNavButton(
                                        icon: Icons.arrow_forward,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            _fadeRoute(
                                              const OnboardingScreen2(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for cleaner code
  Widget _buildIndicator(bool isActive) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.green, size: 28),
        onPressed: onPressed,
      ),
    );
  }

  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
