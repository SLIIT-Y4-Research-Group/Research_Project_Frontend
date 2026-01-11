import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ArtTherapyStep3Screen extends StatelessWidget {
  const ArtTherapyStep3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Art Therapy - Step 03"),
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
                "සුදු කඩදාසි පත්‍රයක් ගෙන, ඔබ අත්විඳි දේවල් ඇඳිමින් ප්‍රකාශ කරන්න.\n"
                "අද ඔබට දැනෙන හැඟීම්වලට ගැලපෙන වර්ණ තෝරන්න.\n"
                "ඔබ සම්පූර්ණ කළ පසු “Continue” බොත්තම ඔබන්න.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                  onPressed: () {
                    // Change this route to your next screen
                    Navigator.pushNamed(context, '/tri_fusion');
                  },
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
