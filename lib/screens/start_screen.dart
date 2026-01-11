import 'package:flutter/material.dart';
import 'onboarding_screen_1.dart';
import 'onboarding_lottie_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Top right eclipse image
            Positioned(
              top: -50,
              right: -50,
              child: Image.asset(
                'assets/images/Ellipse1.png',
                width: 200,
                height: 200,
              ),
            ),

            // Bottom left eclipse image
            Positioned(
              bottom: -80,
              left: -80,
              child: Image.asset(
                'assets/images/Ellipse2.png',
                width: 250,
                height: 250,
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  SizedBox(
                    width: 350,
                    height: 350,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Padding(
  padding: const EdgeInsets.symmetric(horizontal: 32),
  child: OutlinedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingLottieScreen(),
        ),
      );
    },
    icon: const Icon(Icons.auto_awesome),
    label: const Text('Start Emotional Journey'),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      foregroundColor: Colors.black87,
      side: const BorderSide(color: Colors.grey),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
  ),
),


                  const SizedBox(height: 20),
                  const Spacer(flex: 1),

                  // Continue button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OnboardingScreen1(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4EAA57),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Skip button
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen1(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4EAA57),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
