import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'mood_home.dart';

class MoodIntroScreen extends StatefulWidget {
  const MoodIntroScreen({super.key});

  @override
  State<MoodIntroScreen> createState() => _MoodIntroScreenState();
}

class _MoodIntroScreenState extends State<MoodIntroScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroStep> _steps = [
    IntroStep(
      title: "ඔයාට පොඩි වැඩයි කරන්න තියෙන්නෙ",
      description: "අපි ඔයාගෙන් ප්‍රශ්න 5ක් අහනවා.\n mic එක on කරලා කතා කරන්න තමා තියෙන්නෙ.",
      animationPath: "assets/lottie/Artificial Intelligence Chatbot.json",
    ),
    IntroStep(
      title: "ඔයාට හිතෙන දේ කියන්න",
      description: "හරි වැරදි කියලා දෙයක් නැහැ..\n ඔයාට හිතෙන විදිහට සරලව කියන්න..",
      animationPath: "assets/lottie/thinking_new.json",
    ),
    IntroStep(
      title: "සමහර ප්‍රශ්න Skip කරන්න පුළුවන්",
      description: "පළමු ප්‍රශ්නයට පිළිතුරු දෙන්න.\nඊට පස්සේ තව ප්‍රශ්න 2කට පිළිතුරු දුන්නොත් හරි.\nකැමතිනම් ඔක්කොම ප්‍රශ්න වලට උත්තර දෙන්නත් පුළුවන්.",
      animationPath: "assets/lottie/progerss.json",
    ),
  ];

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to mood questions
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MoodHome()),
        (route) => false,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF7FBF8),
              Color(0xFFF1F7F3),
              Color(0xFFEDF5EF),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top section with heading and progress
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 24 : 32,
                  isSmallScreen ? 20 : 28,
                  isSmallScreen ? 24 : 32,
                  12,
                ),
                child: Column(
                  children: [
                    // Friendly heading
                    Text(
                      "අද ඔයා ගැන ටිකක් දැනගමු",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2F4A3A),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    
                    // Enhanced progress indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _steps.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: _currentPage == index ? 32 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFF72B86B)
                                : const Color(0xFFDDE8E0),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: _currentPage == index
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF72B86B).withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PageView with steps
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    return _buildStepPage(_steps[index], index);
                  },
                ),
              ),

              // Navigation buttons
              Container(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 24 : 32,
                  18,
                  isSmallScreen ? 24 : 32,
                  isSmallScreen ? 24 : 32,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFFFD),
                  border: const Border(
                    top: BorderSide(
                      color: Color(0xFFE2ECE4),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8BA796).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: _previousPage,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        label: const Text(
                          "පෙර",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          foregroundColor: const Color(0xFF4E7F56),
                          side: const BorderSide(
                            color: Color(0xFFDDE8E0),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Next/Start button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _nextPage,
                        icon: Icon(
                          _currentPage == _steps.length - 1
                              ? Icons.check_circle_outline
                              : Icons.arrow_forward_ios,
                          size: 20,
                        ),
                        label: Text(
                          _currentPage == _steps.length - 1
                              ? "දැන් පටන් ගමු"
                              : "ඊළඟ",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: const Color(0xFF72B86B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: const Color(0xFF8BA796).withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ).copyWith(
                          elevation: MaterialStateProperty.all(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPage(IntroStep step, int index) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 400),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 24 : 48,
            vertical: 12,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: isSmallScreen ? 20 : 28),
              
              // Premium animation card
              Container(
                constraints: BoxConstraints(
                  maxWidth: 400,
                  maxHeight: isSmallScreen ? 220 : 260,
                ),
                padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFFFD),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFE2ECE4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8BA796).withOpacity(0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: const Color(0xFF8BA796).withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Lottie.asset(
                    step.animationPath,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 24 : 30),

              // Title
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 22 : 26,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2F4A3A),
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: isSmallScreen ? 14 : 18),

              // Description card
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 22 : 26,
                  vertical: isSmallScreen ? 18 : 22,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FCFA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFDDE8E0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8BA796).withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  step.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    color: const Color(0xFF6A7D72),
                    fontWeight: FontWeight.w600,
                    height: 1.7,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 20 : 28),
            ],
          ),
        ),
      ),
    );
  }
}

class IntroStep {
  final String title;
  final String description;
  final String animationPath;

  IntroStep({
    required this.title,
    required this.description,
    required this.animationPath,
  });
}
