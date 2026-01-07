import 'package:flutter/material.dart';
import 'main_navigation.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- පසුබිම් මෝස්තර (Background Ellipses) ---

          // ඉහළ දකුණු පස Ellipse
          Positioned(
            top: -50,
            right: -50,
            child: Image.asset(
              'assets/images/Ellipse1.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),

          // පහළ වම් පස Ellipse
          Positioned(
            bottom: -80,
            left: -80,
            child: Image.asset(
              'assets/images/Ellipse2.png',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
          ),

          // --- ප්‍රධාන අන්තර්ගතය (Main Content) ---
          SafeArea(
            child: Center(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo එක (StartScreen එකට සමාන ප්‍රමාණය)
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const Spacer(flex: 1),

                  // සිංහල භාෂාවෙන් අකුරු පෙළ
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        const Text(
                          'සුව මනස වෙත සාදරයෙන් පිළිගනිමු!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28, // ටිකක් විශාල අකුරු
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'ඔබේ මනෝභාවයට ගැළපෙන සහනයක් සහ සතුටක් සොයා ගන්න.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // ආරම්භ කිරීමේ බොත්තම (Get Started Button)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainNavigation(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF4EAA57,
                          ), // තේමා වර්ණය (කොළ)
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ආරම්භ කරමු',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
