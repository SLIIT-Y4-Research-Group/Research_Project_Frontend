import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const ScanScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'ප්‍රධාන',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_rounded),
              label: 'ස්කෑන්',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded),
              label: 'ප්‍රියතම',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'ගිණුම',
            ),
          ],
        ),
      ),
    );
  }
}

// HomeContent is the home screen without its own bottom navigation bar
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'සුව මනස',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: 120,
            left: -80,
            child: Image.asset(
              'assets/images/Ellipse1.png',
              width: 280,
              height: 280,
              opacity: const AlwaysStoppedAnimation(0.4),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -90,
            child: Image.asset(
              'assets/images/Ellipse2.png',
              width: 380,
              height: 380,
              opacity: const AlwaysStoppedAnimation(0.5),
            ),
          ),
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Greeting section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Colors.purple),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'ආයුබෝවන්! 👋',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'අද ඔබට කෙසේද?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        context,
                        'මුහුණ ස්කෑන්',
                        Icons.camera_alt,
                        Colors.orange.shade100,
                        () {
                          // Navigate to scan tab
                          final navState = context
                              .findAncestorStateOfType<_MainNavigationState>();
                          navState?.setState(() {
                            navState._currentIndex = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickAction(
                        context,
                        'ප්‍රියතම',
                        Icons.favorite,
                        Colors.pink.shade100,
                        () {
                          // Navigate to favorites tab
                          final navState = context
                              .findAncestorStateOfType<_MainNavigationState>();
                          navState?.setState(() {
                            navState._currentIndex = 2;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Today's mood section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'අද ඔබේ මනෝභාවය කුමක්ද?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMoodOption('😊', 'සතුටු'),
                          _buildMoodOption('😢', 'දුක'),
                          _buildMoodOption('😠', 'කෝප'),
                          _buildMoodOption('😌', 'සන්සුන්'),
                          _buildMoodOption('😰', 'කනස්සල්ල'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Features section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'විශේෂාංග',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  'මනෝභාව හඳුනාගැනීම',
                  'ඔබේ මුහුණ ස්කෑන් කර මනෝභාවය හඳුනාගන්න',
                  Icons.face,
                  Colors.blue.shade100,
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  'සංගීත නිර්දේශ',
                  'ඔබේ මනෝභාවයට ගැලපෙන සංගීතය අසන්න',
                  Icons.music_note,
                  Colors.green.shade100,
                ),
                const SizedBox(height: 12),
                _buildFeatureCard(
                  'ප්‍රහේලිකා ක්‍රීඩාව',
                  'සතුටු මුහුණ ප්‍රහේලිකාව විසඳන්න',
                  Icons.extension,
                  Colors.orange.shade100,
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.black87),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodOption(String emoji, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
