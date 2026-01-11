import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingLottieScreen extends StatelessWidget {
  const OnboardingLottieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ✅ Text above animation
              const Text(
                "ඔබ මෑතකාලයේදී මානසික පීඩනයටත්, තනිකමටත් මුහුණ දෙමින් සිටිනවාද?එය කලා මඟින් ප්‍රකාශ කරමු.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 30),

              // ✅ Lottie animation E:\a_4th_yr\Research\a_suwa-manasa_frontend\Research_Project_Frontend\assets\animations\onboarding.json
              Expanded(
                child: Lottie.asset(
                  'assets/animations/onboarding.json',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 30),

              // ✅ Button below animation
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/art_theraphy_screen_01');
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
                    "Continue",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
