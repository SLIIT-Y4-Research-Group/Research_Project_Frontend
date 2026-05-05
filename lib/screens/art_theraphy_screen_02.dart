import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

import '../widgets/child_bottom_nav_bar.dart';

class ArtTherapyStep2Screen extends StatefulWidget {
  const ArtTherapyStep2Screen({super.key});

  @override
  State<ArtTherapyStep2Screen> createState() => _ArtTherapyStep2ScreenState();
}

class _ArtTherapyStep2ScreenState extends State<ArtTherapyStep2Screen> {
  Timer? _timer;
  int _secondsLeft = 10;
  bool _navigated = false;
  bool _isLoading = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startTimer();
    _playInstructionAudio();
  }

  Future<void> _playInstructionAudio() async {
    await _audioPlayer.play(
      AssetSource('audio/art02.mp3'),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _isLoading) return;

      setState(() => _secondsLeft--);

      if (_secondsLeft <= 0) {
        _goNext();
      }
    });
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;

    _navigated = true;
    _timer?.cancel();

    await _audioPlayer.stop();

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/art_theraphy_screen_03');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const ChildBottomNavBar(currentIndex: 0),
      appBar: AppBar(
        title: const Text("කලා චිකිත්සාව - පියවර 02"),
        backgroundColor: const Color(0xFF4EAA57),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fantasygreen.jpg',
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
                    "දැන් ඔබේ සිත නිදහස් කරමින්, ඔබ අත්විඳින හැඟීම් සන්සුන්ව අවධානයට ගන්න.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Lottie.asset(
                      'assets/animations/meditation.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "ඊළඟ පියවරට තත්පර $_secondsLeft කින්",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4EAA57),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}