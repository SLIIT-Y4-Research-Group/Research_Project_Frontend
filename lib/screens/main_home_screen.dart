import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'child_drawing_gallery_screen.dart';
import 'onboarding_lottie_screen.dart';
import 'bubble_pop_page.dart';
import 'balloon_breath_page.dart';
import 'mood_home.dart';
import 'mood_intro_screen.dart';
import 'scan_screen.dart';
import 'student_dashboard_screen.dart';
import 'settings_screen.dart';
import '../services/api_client.dart';
import 'story/home_screen.dart' as StoryHome;

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
    _checkAndShowFirstLoginDialog();
  }

  Future<void> _loadChildData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _childId = prefs.getString('child_id') ?? '';
      _childName = prefs.getString('child_name') ?? fallbackUserName;
    });
  }

  Future<void> _checkAndShowFirstLoginDialog() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // First check local storage for immediate feedback
    final prefs = await SharedPreferences.getInstance();
    final localHasSeen = prefs.getBool('has_seen_first_login_dialog') ?? false;
    
    if (localHasSeen) {
      debugPrint('[FirstLogin] Already seen locally, skipping dialog');
      return;
    }
    
    try {
      // Check with backend if user has seen the prompt
      final response = await ApiClient.getChildInfo();
      
      debugPrint('[FirstLogin] Backend response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hasSeenPrompt = data['has_seen_first_login_prompt'] ?? false;
        
        debugPrint('[FirstLogin] Backend has_seen_first_login_prompt: $hasSeenPrompt');
        
        // Show dialog only if backend says they haven't seen it
        if (!hasSeenPrompt && mounted) {
          debugPrint('[FirstLogin] Showing dialog');
          _showFirstLoginDialog();
        } else {
          // Backend says they've seen it, update local storage
          await prefs.setBool('has_seen_first_login_dialog', true);
        }
      }
    } catch (e) {
      debugPrint('[FirstLogin] Error checking first login status: $e');
      // Don't show dialog if API call fails
    }
  }

  void _showFirstLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final media = MediaQuery.of(dialogContext);
        final isSmallScreen = media.size.width < 360;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: media.size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Welcome animation
                    SizedBox(
                      height: isSmallScreen ? 90 : 120,
                      child: Lottie.asset(
                        'assets/lottie/welcome.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'සුවමනසට සාදරයෙන් පිළිගනිමු! 🎉',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF22C55E),
                      ),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'මෙහි ඔබට:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTipItem('📝', 'ඔබේ mood එක දිනපතා පරීක්ෂා කරන්න'),
                          const SizedBox(height: 8),
                          _buildTipItem('🎨', 'අඳින්න සහ හැඟීම් ප්‍රකාශ කරන්න'),
                          const SizedBox(height: 8),
                          _buildTipItem('🎮', 'සතුටු ක්‍රීඩා සහ අභ්‍යාස'),
                          const SizedBox(height: 8),
                          _buildTipItem('🎵', 'ඔබේ මනෝභාවය සඳහා සංගීතය'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ඔයාගෙ මේ ගිණුම හදල තියෙන්නෙ ඔයාගේ දෙමාපියො හරි ඔයාගේ භාරකාරයෝ හරි, ඉතින් සුව මනස අපි කැමතියි ඔයාගේ පෞද්ගලිකත්වය ආරක්ෂා කිරීම වෙනුවෙන් ඔයා ඔයාගේ මුරපදය මාරු කරනවනම් ඒ වගේම අපේ Email Alert එක සක්‍රිය කිරීමෙන් ඔයාගේ මූඩ් එක අවුල් ගියපු වෙලාවක ඔයාගේ අවසරය ඇතිව අපිට ලේසියෙන්ම ඔයාගෙ දෙමාපියො හරි භාරකාරය හරි දැනුවත් කරන්න පුළුවන්',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      debugPrint('[FirstLogin] Go to Settings clicked');
                      
                      // Mark as seen in local storage
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('has_seen_first_login_dialog', true);
                      
                      // Notify backend that user has seen the prompt
                      try {
                        final response = await ApiClient.markFirstLoginPromptSeen();
                        debugPrint('[FirstLogin] Backend response: ${response.statusCode}');
                      } catch (e) {
                        debugPrint('[FirstLogin] Error marking first login seen: $e');
                      }
                      
                      Navigator.of(dialogContext).pop();
                      
                      // Navigate to Settings
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go to Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      debugPrint('[FirstLogin] Skip clicked');
                      
                      // Mark as seen in local storage
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('has_seen_first_login_dialog', true);
                      
                      // Notify backend that user has seen the prompt
                      try {
                        final response = await ApiClient.markFirstLoginPromptSeen();
                        debugPrint('[FirstLogin] Backend response: ${response.statusCode}');
                      } catch (e) {
                        debugPrint('[FirstLogin] Error marking first login seen: $e');
                      }
                      
                      Navigator.of(dialogContext).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
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

  Future<void> _handleMoodCheckNavigation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check today's mood status before navigating
      final response = await ApiClient.getTodayMoodStatus();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool todayCompleted = data['completed'] ?? false;
        
        if (todayCompleted) {
          // Already completed today
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ඔබ අද දවසේ මනෝභාව පරීක්ෂාව දැනටමත් සම්පූර්ණ කර ඇත.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      
      // Not completed, proceed to mood check
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MoodIntroScreen(),
        ),
      );
    } catch (e) {
      print('[HOME] Error checking mood status: $e');
      // If check fails, allow navigation (fail-safe)
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MoodIntroScreen(),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_rounded, color: Color(0xFF22C55E), size: 22),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentDashboardScreen(),
                  ),
                );
              },
              tooltip: 'My Profile',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_rounded, color: Color(0xFF22C55E), size: 22),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF4FBF6),
              Color(0xFFE8F5E9),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF66BB6A).withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF66BB6A).withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              top: 250,
              right: 20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF66BB6A).withOpacity(0.06),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isWideScreen ? 32 : 20,
                      isWideScreen ? 24 : 16,
                      isWideScreen ? 32 : 20,
                      24,
                    ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF66BB6A),
                              Color(0xFF43A047),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emoji_emotions_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ආයුබෝවන් $_childName',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ශරීරයත් පුංචි මනසත් සුවයෙන් තබාගමු.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'ඉක්මන් ක්‍රියාකාරකම්',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final isCompact = screenWidth < 480;
                          final cardWidth = isCompact
                              ? (screenWidth * 0.56).clamp(180.0, 220.0)
                              : (screenWidth * 0.35).clamp(220.0, 280.0);

                          if (isWideScreen) {
                            return Row(
                              children: [
                                Expanded(
                                  child: _QuickActionCard(
                                    title: 'Bubble Game',
                                    animationAsset: 'assets/animations/bubble.json',
                                    color: const Color(0xFF7ED6DF),
                                    backgroundColor: const Color(0xFFE3F2FD),
                                    onTap: () => _navigateTo(const BubblePopPage()),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _QuickActionCard(
                                    title: 'Breathing Exercise',
                                    animationAsset: 'assets/animations/breathing.json',
                                    color: const Color(0xFFA29BFE),
                                    backgroundColor: const Color(0xFFEDE7F6),
                                    onTap: () => _navigateTo(const BalloonBreathPage()),
                                  ),
                                ),
                              ],
                            );
                          }

                          return SizedBox(
                            height: 140,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: _QuickActionCard(
                                      title: 'Bubble Game',
                                      animationAsset: 'assets/animations/bubble.json',
                                      color: const Color(0xFF7ED6DF),
                                      backgroundColor: const Color(0xFFE3F2FD),
                                      onTap: () => _navigateTo(const BubblePopPage()),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _QuickActionCard(
                                      title: 'Breathing Exercise',
                                      animationAsset: 'assets/animations/breathing.json',
                                      color: const Color(0xFFA29BFE),
                                      backgroundColor: const Color(0xFFEDE7F6),
                                      onTap: () => _navigateTo(const BalloonBreathPage()),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 36),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'ප්‍රධාන විශේෂාංග',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _MainFunctionCard(
                        title: 'කතා මිතුරා',
                        subtitle: 'Emotion triggered storytelling',
                        animationAsset: 'assets/animations/story.json',
                        color: const Color(0xFFF6B54C),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StoryHome.HomeScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _MainFunctionCard(
                        title: 'සිතුවම් පුවරුව',
                        subtitle: "Emotion analysis from children's drawings",
                        animationAsset: 'assets/animations/drawing.json',
                        color: const Color(0xFFB86AD9),
                        onTap: () => _navigateTo(const OnboardingLottieScreen()),
                      ),
                      const SizedBox(height: 12),
_MainFunctionCard(
  title: 'මගේ චිත්‍ර ගැලරිය',
  subtitle: 'ඔබ යවා ඇති චිත්‍ර බලන්න',
  animationAsset: 'assets/animations/gallery.json',
  color: const Color(0xFF2563EB),
  onTap: () => _navigateTo(const ChildDrawingGalleryScreen()),
),
                      const SizedBox(height: 12),
                      _MainFunctionCard(
                        title: 'හඬ දිනපොත',
                        subtitle: 'Voice based emotion prediction',
                        animationAsset: 'assets/animations/voice.json',
                        color: const Color(0xFF50C2C9),
                        onTap: _handleMoodCheckNavigation,
                      ),
                      const SizedBox(height: 12),
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
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String animationAsset;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.animationAsset,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 360;
    final double iconSize = isCompact ? 44 : 48;
    final double tileSize = isCompact ? 56 : 64;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Lottie.asset(
                    animationAsset,
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: TextStyle(
                  fontSize: isCompact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  color: color.withOpacity(0.9),
                  letterSpacing: 0.2,
                ),
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Lottie.asset(
                  animationAsset,
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: Colors.black.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}