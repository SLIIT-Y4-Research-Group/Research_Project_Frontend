import 'package:flutter/material.dart';

import '../screens/main_home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/balloon_breath_page.dart';
import '../screens/mood_home.dart';

class ChildBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const ChildBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;

    if (index == 0) {
      page = const MainHomeScreen();
    } else if (index == 1) {
      page = const ProfileScreen();
    } else if (index == 2) {
      page = const BalloonBreathPage();
    } else {
      page = const MoodHome();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF4EAA57);
    const inactiveColor = Color(0xFF9CA3AF);

    final items = [
      _ChildNavItem(icon: Icons.home_rounded, label: 'මුල් පිටුව'),
      _ChildNavItem(icon: Icons.person_rounded, label: 'පැතිකඩ'),
      _ChildNavItem(icon: Icons.sports_esports_rounded, label: 'ක්‍රීඩා'),
      _ChildNavItem(icon: Icons.music_note_rounded, label: 'සංගීත'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _navigate(context, index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? activeColor.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            item.icon,
                            color: isSelected ? activeColor : inactiveColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? activeColor : inactiveColor,
                            fontSize: 10.5,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ChildNavItem {
  final IconData icon;
  final String label;

  const _ChildNavItem({
    required this.icon,
    required this.label,
  });
}