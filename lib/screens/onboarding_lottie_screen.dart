import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingLottieScreen extends StatelessWidget {
  const OnboardingLottieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // ✅ Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/art_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // ✅ Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Text above animation
                  const Text(
                    "කලා චිකිත්සාවට සාදරයෙන් පිළිගනිමු",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Lottie animation
                  Expanded(
                    child: Lottie.asset(
                      'assets/animations/onboarding.json',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                            context, '/art_theraphy_screen_01');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4EAA57),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "ඉදිරියට යන්න",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}