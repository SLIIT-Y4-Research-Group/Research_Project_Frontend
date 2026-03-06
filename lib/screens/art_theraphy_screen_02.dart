import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ArtTherapyStep2Screen extends StatefulWidget {
  const ArtTherapyStep2Screen({super.key});

  @override
  State<ArtTherapyStep2Screen> createState() => _ArtTherapyStep2ScreenState();
}

class _ArtTherapyStep2ScreenState extends State<ArtTherapyStep2Screen> {
  Timer? _timer;
  int _secondsLeft = 10;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      setState(() => _secondsLeft--);

      if (_secondsLeft <= 0) {
        _goNext();
      }
    });
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _timer?.cancel();
    Navigator.pushReplacementNamed(context, '/art_theraphy_screen_03');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("කලා චිකිත්සාව - පියවර 02"),
        backgroundColor: const Color(0xFF4EAA57),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [

          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/step2.jpg',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  const Text(
                    "අද දවස ඔබට කොහොමද?\n"
                    "දෙමාපියන් හා යහළුවන් සමඟ සිදු වූ දේවල් මතක් කරගෙන ඒවා සිතුවිලිවලට නගන්න",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),

                  const SizedBox(height: 24),

                  Expanded(
                    child: Lottie.asset(
                      'assets/animations/stress.json',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "ඊළඟ පියවරට තත්පර $_secondsLeft කින්",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),

                  const SizedBox(height: 16),

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
                        "ඊළඟ පියවර",
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