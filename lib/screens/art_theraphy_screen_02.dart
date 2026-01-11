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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Art Therapy - Step 02"),
        backgroundColor: const Color(0xFF4EAA57),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                "අද ඔබ අත්විඳි දේවල් මතක් කර ගන්න.\n"
                "ඔබ සැබවින්ම දැනුනේ කෙසේද?\n"
                "අන් අයට ඔබ පෙන්වූයේ කුමක්ද?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                "Next step in $_secondsLeft s",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
