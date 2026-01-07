import 'package:flutter/material.dart';
import 'music_player_screen.dart';

class MusicRecommendationScreen extends StatefulWidget {
  final String emotion;

  const MusicRecommendationScreen({super.key, required this.emotion});

  @override
  State<MusicRecommendationScreen> createState() =>
      _MusicRecommendationScreenState();
}

class _MusicRecommendationScreenState extends State<MusicRecommendationScreen> {
  int? _hoveredIndex;

  // Emotion label mapping for Sinhala
  String _getSinhalaEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return 'සතුටුයි';
      case 'sad':
        return 'කණගාටුයි';
      case 'anxious':
        return 'බියයි';
      case 'calm':
        return 'සන්සුන්';
      case 'angry':
        return 'තරහයි';
      default:
        return 'සාමාන්‍යයි';
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = _getSongsForEmotion(widget.emotion);
    final sinhalaEmotion = _getSinhalaEmotion(widget.emotion);

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
          // --- පසුබිම් මෝස්තර (Background Ellipses) ---
          Positioned(
            top: -50,
            left: -100,
            child: Image.asset(
              'assets/images/Ellipse1.png',
              width: 400,
              height: 400,
              opacity: const AlwaysStoppedAnimation(0.3),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -100,
            child: Image.asset(
              'assets/images/Ellipse2.png',
              width: 450,
              height: 450,
              opacity: const AlwaysStoppedAnimation(0.4),
            ),
          ),

          // --- ප්‍රධාන අන්තර්ගතය ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ඔබට $sinhalaEmotion විට...',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C22),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ඔබේ සිත සන්සුන් කිරීමට අපි මේ ගීත තෝරා ගත්තෙමු',
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return _buildSongTile(song, index, songs);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(
    Map<String, dynamic> song,
    int index,
    List<Map<String, dynamic>> allSongs,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        onTap: () => _navigateToPlayer(song, allSongs),
        leading: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: song['colors'] as List<Color>,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 35,
          ),
        ),
        title: Text(
          song['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text(
          song['subtitle'] as String,
          style: const TextStyle(
            color: Color(0xFF4EAA57),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              song['duration'] as String,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(width: 8),
            Icon(
              song['isFavorite'] == true
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: song['isFavorite'] == true ? Colors.red : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPlayer(
    Map<String, dynamic> song,
    List<Map<String, dynamic>> allSongs,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicPlayerScreen(
          song: song,
          playlist: allSongs,
          emotion: widget.emotion,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSongsForEmotion(String emotion) {
    // තෝරාගත් මනෝභාවය අනුව ගීත ලැයිස්තුව
    switch (emotion.toLowerCase()) {
      case 'anxious':
        return [
          {
            'title': 'සන්සුන් හුස්ම',
            'subtitle': 'Calm Mind',
            'duration': '6:00',
            'colors': [Colors.orange.shade300, Colors.pink.shade200],
            'isFavorite': false,
          },
          {
            'title': 'නිදහස් සිත',
            'subtitle': 'Relief',
            'duration': '5:30',
            'colors': [Colors.green.shade300, Colors.blue.shade300],
            'isFavorite': true,
          },
          {
            'title': 'සියල්ල යහපත් වේ',
            'subtitle': 'Peace',
            'duration': '4:00',
            'colors': [Colors.yellow.shade400, Colors.orange.shade200],
            'isFavorite': false,
          },
        ];
      case 'happy':
        return [
          {
            'title': 'සතුටු සිත',
            'subtitle': 'Good Vibes',
            'duration': '4:30',
            'colors': [Colors.yellow.shade300, Colors.orange.shade300],
            'isFavorite': true,
          },
          {
            'title': 'ප්‍රීතිමත් දිනයක්',
            'subtitle': 'Joy',
            'duration': '3:45',
            'colors': [Colors.pink.shade300, Colors.purple.shade300],
            'isFavorite': false,
          },
        ];
      case 'sad':
        return [
          {
            'title': 'සෙනෙහස',
            'subtitle': 'Comfort',
            'duration': '6:30',
            'colors': [Colors.blue.shade300, Colors.purple.shade200],
            'isFavorite': false,
          },
          {
            'title': 'ඔබ තනිවම නොවේ',
            'subtitle': 'Support',
            'duration': '5:15',
            'colors': [Colors.teal.shade300, Colors.blue.shade300],
            'isFavorite': true,
          },
        ];
      default:
        return [
          {
            'title': 'සාමකාමී සිත',
            'subtitle': 'Serenity',
            'duration': '5:00',
            'colors': [Colors.green.shade300, Colors.teal.shade300],
            'isFavorite': false,
          },
          {
            'title': 'සමබරතාවය',
            'subtitle': 'Balance',
            'duration': '4:30',
            'colors': [Colors.purple.shade300, Colors.pink.shade300],
            'isFavorite': false,
          },
        ];
    }
  }
}
