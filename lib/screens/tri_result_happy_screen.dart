import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TriResultHappyScreen extends StatelessWidget {
  const TriResultHappyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Result"),
        backgroundColor: const Color(0xFF4EAA57),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📝 MAIN TEXT
              const Text(
                "ඔබ අද සතුටින් සිටිනවා.\n"
                "ඔබගේ අධ්‍යාපනික කටයුතු සාර්ථකව කරගෙන යාමටත්, "
                "ඔබගේ හැඟීම් හොඳින් කළමනාකරණය කර ගැනීමටත් සුභ පැතුම් දරුවා.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 20),

              // 🌟 HAPPY LOTTIE (IN BETWEEN)
              Center(
                child: Lottie.asset(
                  'assets/animations/happy.json',
                  height: 220,
                  repeat: true,
                ),
              ),

              const SizedBox(height: 20),

              // ⚠️ WARNING
              const Text(
                "* අපගේ App එක සම්පූර්ණයෙන්ම Machine Learning මත පදනම් වේ. "
                "වෛද්‍ය උපදෙස් සඳහා කරුණාකර වෛද්‍යවරයෙකු අමතන්න.",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
