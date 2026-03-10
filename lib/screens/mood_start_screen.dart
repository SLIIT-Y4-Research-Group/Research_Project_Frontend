import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'mood_home.dart';

class MoodStartScreen extends StatefulWidget {
  const MoodStartScreen({super.key});

  @override
  State<MoodStartScreen> createState() => _MoodStartScreenState();
}

class _MoodStartScreenState extends State<MoodStartScreen> {
  bool goingNext = false;

  Future<void> _go() async {
    setState(() => goingNext = true);

    // Small delay so animation feels smooth
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MoodHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF22C55E), Color(0xFF86EFAC), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 14),

                      // Top logo row (optional)
                      Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/images/sidephoto.jpg',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "සුව මනස",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 35),

                      // Welcome text
                      const Text(
                        "අචින්ත,\nඅද දවසේ මොනවද වුණේ? 😊",
                        style: TextStyle(
                          fontSize: 30,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "ටිකක් කතා කරලා බලමු.\nඔයාගේ මූඩ් එක හඳුනාගෙන, හොඳ උපදෙස් ටිකක් දෙන්නම් 💚",
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.35,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Big animation card
                      Card(
                        elevation: 0,
                        color: Colors.white.withOpacity(0.92),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 210,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: goingNext
                                      ? Lottie.asset(
                                          "assets/lottie/thinking.json",
                                          key: const ValueKey("thinking"),
                                        )
                                      : Lottie.asset(
                                          "assets/lottie/welcome.json",
                                          key: const ValueKey("welcome"),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                goingNext ? "සූදානම් කරනවා..." : "අරඹමුද?",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                goingNext
                                    ? "ඔයාට ප්‍රශ්න 5ක් තියෙනවා"
                                    : "මයික් එක ඔන් කරලා කතා කරන්න පුළුවන් 🎙️",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.3,
                                  color: Colors.black.withOpacity(0.65),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Button pinned at bottom
              Padding(
                padding: const EdgeInsets.all(18),
                child: ElevatedButton(
                  onPressed: goingNext ? null : _go,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    goingNext ? "ආරම්භ වෙමින්..." : "පටන්ගමු",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
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
