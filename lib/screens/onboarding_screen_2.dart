import 'package:flutter/material.dart';
import 'onboarding_screen_3.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

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
                    // Top section with logo - flex 6 to push content down
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
                            const SizedBox(height: 20),
                            const Text(
                              'ඔබේ හැඟීම් ගැන ඉගෙනගන්න',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26, // Increased Font
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'ඔබ සතුටු, කම්පනය හෝ බිය\nවෙන්නේ කුමක් දැයි කර ඉගෙන ගන්න.\nඔබේ හැඟීම් වඩාත් හොඳින් තේරුම් ගැනීමට අපි ඔබට උපකාර කරමු',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16, // Increased Font
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Page indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildIndicator(false),
                                const SizedBox(width: 8),
                                _buildIndicator(true), // Middle circle active
                                const SizedBox(width: 8),
                                _buildIndicator(false),
                              ],
                            ),

                            // This Spacer pushes the buttons to the bottom of the screen
                            const Spacer(),

                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 40.0,
                              ), // Moves buttons down
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Back button
                                  _buildNavButton(
                                    icon: Icons.arrow_back,
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  // Next button
                                  _buildNavButton(
                                    icon: Icons.arrow_forward,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const OnboardingScreen3(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
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

  // Helper for cleaner code: Page Indicators
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

  // Helper for cleaner code: Circular Navigation Buttons
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
}
