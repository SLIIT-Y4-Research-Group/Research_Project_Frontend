import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_lottie_screen.dart';
import 'bubble_pop_page.dart';
import 'balloon_breath_page.dart';
import 'mood_home.dart';
import 'scan_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  static const String fallbackUserName = 'සිතුම්';

  bool _isLoading = false;
  String _childId = '';
  String _childName = fallbackUserName;

  @override
  void initState() {
    super.initState();
    _loadChildData();
  }

  Future<void> _loadChildData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _childId = prefs.getString('child_id') ?? '';
      _childName = prefs.getString('child_name') ?? fallbackUserName;
    });
  }

  Future<void> _navigateTo(Widget page) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName feature will be added soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7F4),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFFFD6E7),
              child: const Icon(Icons.child_care, color: Colors.brown),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ආයුබෝවන් $_childName',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_childId.isNotEmpty)
                    Text(
                      'ID: $_childId',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'ශරීරයත් පුංචි මනසත් සුවයෙන් තබාගමු.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ඉක්මන් ක්‍රියාකාරකම්',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _QuickActionCard(
                          title: 'Bubble Game',
                          animationAsset: 'assets/animations/bubble.json',
                          color: const Color(0xFF7ED6DF),
                          onTap: () => _navigateTo(const BubblePopPage()),
                        ),
                        const SizedBox(width: 12),
                        _QuickActionCard(
                          title: 'Breathing Exercise',
                          animationAsset: 'assets/animations/breathing.json',
                          color: const Color(0xFFA29BFE),
                          onTap: () => _navigateTo(const BalloonBreathPage()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'ප්‍රධාන විශේෂාංග',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MainFunctionCard(
                    title: 'කතා මිතුරා',
                    subtitle: 'Emotion triggered storytelling',
                    animationAsset: 'assets/animations/story.json',
                    color: const Color(0xFFF6B54C),
                    onTap: () {
                      _showComingSoon(context, 'කතා මිතුරා');
                    },
                  ),
                  const SizedBox(height: 16),
                  _MainFunctionCard(
                    title: 'සිතුවම් පුවරුව',
                    subtitle: "Emotion analysis from children's drawings",
                    animationAsset: 'assets/animations/drawing.json',
                    color: const Color(0xFFB86AD9),
                    onTap: () => _navigateTo(const OnboardingLottieScreen()),
                  ),
                  const SizedBox(height: 16),
                  _MainFunctionCard(
                    title: 'හඬ දිනපොත',
                    subtitle: 'Voice based emotion prediction',
                    animationAsset: 'assets/animations/voice.json',
                    color: const Color(0xFF50C2C9),
                    onTap: () => _navigateTo(const MoodHome()),
                  ),
                  const SizedBox(height: 16),
                  _MainFunctionCard(
                    title: 'සතුටු ගීත පෙට්ටිය',
                    subtitle: 'Emotion based music recommender',
                    animationAsset: 'assets/animations/face.json',
                    color: const Color(0xFFFF8FAB),
                    onTap: () => _navigateTo(const ScanScreen()),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
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

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String animationAsset;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.animationAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Lottie.asset(
                animationAsset,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainFunctionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String animationAsset;
  final Color color;
  final VoidCallback onTap;

  const _MainFunctionCard({
    required this.title,
    required this.subtitle,
    required this.animationAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: SizedBox(
                width: 64,
                height: 64,
                child: Lottie.asset(
                  animationAsset,
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}