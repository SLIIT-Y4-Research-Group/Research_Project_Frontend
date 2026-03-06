import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'balloon_breath_page.dart';
import 'bubble_pop_page.dart';
import 'onboarding_lottie_screen.dart';   // NEW IMPORT

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MoodTunes')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to MoodTunes!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Discover music tailored to your mood.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Get Started button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              },
              child: const Text('Get Started'),
            ),

            const SizedBox(height: 20),

            // Breathing Exercise button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BalloonBreathPage(),
                  ),
                );
              },
              child: const Text('Breathing Exercise'),
            ),

            const SizedBox(height: 20),

            // Bubble Pop Game button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BubblePopPage(),
                  ),
                );
              },
              child: const Text('Bubble Pop Game'),
            ),

            const SizedBox(height: 20),

            // NEW Onboarding Lottie Screen button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingLottieScreen(),
                  ),
                );
              },
              child: const Text('Art Therapy Intro'),
            ),
          ],
        ),
      ),
    );
  }
}