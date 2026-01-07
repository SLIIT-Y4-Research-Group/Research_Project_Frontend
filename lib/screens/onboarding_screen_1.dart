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
          // Green background at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/onboardBG.png',
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            ),
          ),
          // Main content
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Top section with logo - Increased flex to push content down
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    // Bottom section
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Spacer pushes text further down within this flex area
                            const SizedBox(height: 20),
                            const Text(
                              'සුව මනස වෙත සාදරයෙන්\nපිළිගනිමු!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26, // Increased size
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'සෑම දිනකම සතුටින්, සන්සුන්ව සහ\nඅපූරුව දැනීම සඳහා ඔබේ මිත්‍රශීලී\nසහයක',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16, // Increased size
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 30),
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
                            // Pushes the button to the very bottom of the Column
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 40.0,
                              ), // Moves button down
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
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
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.green,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const OnboardingScreen2(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
}
