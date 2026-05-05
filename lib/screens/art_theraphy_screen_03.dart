import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_app/screens/drawing_board_page.dart';
import '../widgets/child_bottom_nav_bar.dart';

class ArtTherapyStep3Screen extends StatefulWidget {
  const ArtTherapyStep3Screen({super.key});

  @override
  State<ArtTherapyStep3Screen> createState() => _ArtTherapyStep3ScreenState();
}

class _ArtTherapyStep3ScreenState extends State<ArtTherapyStep3Screen> {
  bool _isLoading = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playInstructionAudio();
  }

  Future<void> _playInstructionAudio() async {
    await _audioPlayer.play(
      AssetSource('audio/art03.mp3'),
    );
  }

  Future<void> _goToDrawingBoard() async {
    if (_isLoading) return;

    await _audioPlayer.stop();

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final childId = prefs.getString('child_id') ?? '';

    if (childId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('දරුවාගේ හැඳුනුම් අංකය හමු නොවීය. නැවත login වන්න.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingBoardPage(childId: childId),
      ),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const ChildBottomNavBar(currentIndex: 0),
      appBar: AppBar(
        title: const Text("කලා චිකිත්සාව - පියවර 03"),
        backgroundColor: const Color(0xFF4EAA57),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/step3.jpg',
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
                    "සුදු කඩදාසි පත්‍රයක් ගෙන, ඔබ අත්විඳි දේවල් ඇඳිමින් ප්‍රකාශ කරන්න.\n"
                    "අද ඔබට දැනෙන හැඟීම්වලට ගැලපෙන වර්ණ තෝරන්න.\n"
                    "සිතුවම් පුවරුව භාවිතා කිරීමට “Continue” බොත්තම ඔබන්න.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Lottie.asset(
                      'assets/animations/draw.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goToDrawingBoard,
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