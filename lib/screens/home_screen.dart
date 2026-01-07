import 'package:flutter/material.dart';
import 'scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
          // --- පසුබිම් මෝස්තර (Empty space පිරවීම සඳහා විශාල කර ඇත) ---
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
            bottom: -50, // Footer එක දක්වා හිස් ඉඩ පිරවීමට
            right: -90,
            child: Image.asset(
              'assets/images/Ellipse2.png',
              width: 380,
              height: 380,
              opacity: const AlwaysStoppedAnimation(0.5),
            ),
          ),

          // --- ප්‍රධාන අන්තර්ගතය ---
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'අද ඔබට කොහොමද?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C22),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "ඔබේ මනෝභාවයට ගැළපෙනම සංගීතය තෝරා ගනිමු",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 35),

                // Scan My Face Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildEmojiStack(),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'මුහුණ ස්කෑන් කරන්න',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'ඔබේ හැඟීම්වලට ගැළපෙන ගීත',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4EAA57),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScanScreen(),
                            ),
                          ),
                          icon: const Icon(
                            Icons.face_retouching_natural,
                            size: 24,
                          ),
                          label: const Text(
                            'පරීක්ෂා කරමු',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'සන්සුන් සංගීතය',
                        'විවේකය සඳහා',
                        Icons.spa,
                        const Color(0xFFE8F5E9),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildInfoCard(
                        'සතුටු මනස',
                        'සතුටින් සිටීමට',
                        Icons.sentiment_very_satisfied,
                        const Color(0xFFFFF3E0),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "නැතිනම් ඔබේ හැඟීම තෝරන්න",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMoodChip('සතුටුයි', '😊'),
                    _buildMoodChip('කණගාටුයි', '😟'),
                    _buildMoodChip('සන්සුන්', '😌'),
                    _buildMoodChip('බියයි', '😰'),
                    _buildMoodChip('තරහයි', '😡'),
                    _buildMoodChip('සාමාන්‍යයි', '😐'),
                  ],
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiStack() {
    return SizedBox(
      width: 70,
      height: 40,
      child: Stack(
        children: const [
          Positioned(
            left: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFFD54F),
              child: Text('😊'),
            ),
          ),
          Positioned(
            left: 18,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF81C784),
              child: Text('😌'),
            ),
          ),
          Positioned(
            left: 36,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF64B5F6),
              child: Text('😐'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(String label, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
