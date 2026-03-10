import 'package:flutter/material.dart';

class MoodBadge extends StatelessWidget {
  final String moodText; // comes from API: "Bad"/"Normal"/"Happy" or Sinhala
  const MoodBadge({super.key, required this.moodText});

  @override
  Widget build(BuildContext context) {
    final m = moodText.toLowerCase();

    Color bg;
    String emoji;
    String si;

    if (m.contains("happy") || m.contains("සතුට")) {
      bg = const Color(0xFF22C55E);
      emoji = "😄";
      si = "සතුටුයි";
    } else if (m.contains("normal") || m.contains("සාමාන්‍ය")) {
      bg = const Color(0xFF3B82F6);
      emoji = "🙂";
      si = "සාමාන්‍යයි";
    } else if (m.contains("bad") || m.contains("දුක") || m.contains("හොඳ නැහැ")) {
      bg = const Color(0xFF8B5CF6);
      emoji = "😔";
      si = "දුකයි / හොඳ නැහැ";
    } else {
      bg = Colors.grey;
      emoji = "🤔";
      si = moodText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bg.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              si,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: bg,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
