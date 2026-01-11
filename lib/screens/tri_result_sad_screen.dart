import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TriResultSadScreen extends StatelessWidget {
  const TriResultSadScreen({super.key});

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
                "App Model Fusion අනුව අද ඔබට මනෝභාවය හොඳ නැති බව පෙන්වයි.\n"
                "යෞවන වියේ දරුවන්ට මෙවැනි මනෝභාව වෙනස්වීම් නිතරම ඇති වීම සාමාන්‍යයි.\n"
                "කනගාටු විය යුතු නැහැ, අපි ඔබ ගැන සැලකිලිමත් වෙමු.\n\n"
                "ඔබගේ මනෝභාවය වැඩි දියුණු කර ගැනීමට, "
                "කරුණාකර අපගේ චිකිත්සා (Therapy) සැසි වලින් එකකට සහභාගී වන්න.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 20),

              // 💙 CARE LOTTIE (IN BETWEEN)
              Center(
                child: Lottie.asset(
                  'assets/animations/care.json',
                  height: 220,
                  repeat: true,
                ),
              ),

              const SizedBox(height: 20),

              // 🧠 THERAPY OPTIONS
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, "/art_theraphy_screen_01"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4EAA57),
                ),
                child: const Text("Art Therapy Session"),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, "/therapy_option_2"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4EAA57),
                ),
                child: const Text("Therapy Option 2"),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, "/therapy_option_3"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4EAA57),
                ),
                child: const Text("Therapy Option 3"),
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
