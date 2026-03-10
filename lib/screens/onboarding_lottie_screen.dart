import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

class OnboardingLottieScreen extends StatefulWidget {
  const OnboardingLottieScreen({super.key});

  @override
  State<OnboardingLottieScreen> createState() => _OnboardingLottieScreenState();
}

class _OnboardingLottieScreenState extends State<OnboardingLottieScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playWelcomeAudio();
  }

  Future<void> _playWelcomeAudio() async {
    await _audioPlayer.play(
      AssetSource('audio/artwelcome.mp3'),
    );
  }

  Future<void> _goNext() async {
    await _audioPlayer.stop();
    if (!mounted) return;
    Navigator.pushNamed(context, '/art_theraphy_screen_01');
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/art_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
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
                  Expanded(
                    child: Lottie.asset(
                      'assets/animations/onboarding.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goNext,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
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
    );
  }
}