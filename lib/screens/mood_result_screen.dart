import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'main_home_screen.dart';

class MoodResultScreen extends StatelessWidget {
  final String mood;

  const MoodResultScreen({super.key, required this.mood});

  Map<String, dynamic> _getMoodContent() {
    final moodLower = mood.toLowerCase();
    
    if (moodLower.contains('happy') || moodLower.contains('සතුටුයි')) {
      return {
        'animation': 'assets/lottie/happyandnormal.json',
        'title': 'Happy',
        'message': 'ඔයා අද හරිම සතුටෙන් කියලා මට පේනවා\n\n'
            'එහෙම දවසක් තියෙන එක හරිම ලස්සන දෙයක්.\n'
            'ඔයා හොඳට උත්සාහ කරලා තියෙනවා, ඒ නිසාම මේ සතුට ලැබිලා තියෙන්න ඇති.\n\n'
            'හෙටත් මේ වගේ හොඳ හිතක්, හොඳ සිතුවිලි, හොඳ ක්‍රියාවල් කරගෙන යන්න පුළුවන් කියලා මම විශ්වාස කරනවා',
        'emoji': '😊',
        'color': Color(0xFF22C55E),
        'gradient': [Color(0xFF22C55E), Color(0xFF16A34A)],
      };
    } else if (moodLower.contains('normal') || moodLower.contains('සාමාන්‍ය')) {
      return {
        'animation': 'assets/lottie/happyandnormal.json',
        'title': 'Normal',
        'message': 'ඔයා අද සාමාන්‍ය විදිහට දවස ගත කරලා තියෙනවා කියලා පේනවා\n\n'
            'ඒකත් හරිම සාමාන්‍ය දෙයක්. හැම දවසක්ම එකම වගේ සතුටු වෙන්න ඕනේ නෑ.\n\n'
            'ටිකක් විවේක ගන්න, හොඳට හුස්ම ගන්න,\n'
            'ඔයාට කැමති දෙයක් කරලා බලන්න — සින්දුවක් අහන්න, පොතක් කියවන්න, යාලුවෙක් එක්ක කතා කරන්න.\n\n'
            'හෙට දවස අදට වඩා ලස්සන දවසක් වෙයි කියලා මම හිතනවා 💙',
        'emoji': '😊',
        'color': Color(0xFF3B82F6),
        'gradient': [Color(0xFF3B82F6), Color(0xFF2563EB)],
      };
    } else {
      // Bad mood
      return {
        'animation': 'assets/lottie/bad.json',
        'title': 'Bad',
        'message': 'ඔයාට අද ටිකක් අමාරු දවසක් වුණා වගේ මට තේරෙනවා\n\n'
            'ඒක හරිම සාමාන්‍යයි. හැමෝටම එහෙම දවස් තියෙනවා.\n\n'
            'ඔයා තනි නෑ. ඔයාට හිතෙන දේවල් වැදගත්.\n'
            'කෙනෙකුට කතා කරලා බලන්න අම්මා, තාත්තා, ටීචර් කෙනෙක්, හෝ හොඳ යාලුවෙක්.\n\n'
            'හෙට දවස අදට වඩා හොඳ දවසක් වෙයි.\n'
            'ඔයාට පුළුවන්. ඔයා ශක්තිමත්.💜',
        'emoji': '😔',
        'color': Color(0xFFEF4444),
        'gradient': [Color(0xFFEF4444), Color(0xFFDC2626)],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _getMoodContent();
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (content['color'] as Color).withOpacity(0.1),
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Animated Header with gradient
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: content['gradient'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (content['color'] as Color).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/sidephoto.jpg',
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      "සුව මනස",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      
                      // Title with decorative elements
                      Column(
                        children: [
                          Text(
                            "✨",
                            style: TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "ඔබේ අද දවසේ තත්ත්වය",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: content['gradient'],
                                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 35),
                      
                      // Enhanced Animation Container
                      Container(
                        height: size.height * 0.35,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: (content['color'] as Color).withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Background gradient circle
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  width: size.width * 0.6,
                                  height: size.width * 0.6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        (content['color'] as Color).withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Animation
                            Center(
                              child: Lottie.asset(
                                content['animation'],
                                fit: BoxFit.contain,
                                repeat: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Enhanced Mood Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (content['color'] as Color).withOpacity(0.15),
                              (content['color'] as Color).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: content['color'],
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (content['color'] as Color).withOpacity(0.25),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              content['emoji'],
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              content['title'],
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: content['color'],
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 35),
                      
                      // Enhanced Message Card
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              (content['color'] as Color).withOpacity(0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              // Decorative line
                              Container(
                                width: 50,
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: content['gradient']),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                content['message'],
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 2,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),

              // Enhanced Bottom Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: (content['color'] as Color).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to home screen and clear navigation stack
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const MainHomeScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home_rounded, size: 26),
                    label: const Text(
                      "අවසන්",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: content['color'],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      minimumSize: const Size(double.infinity, 60),
                      elevation: 0,
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
