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

  @override
  Widget build(BuildContext context) {
    // Get songs based on emotion
    final songs = _getSongsForEmotion(widget.emotion);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('MoodTunes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Music for when you feel ${widget.emotion}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We picked these songs to help you feel better',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return _buildSongTile(song, index, songs);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Scan'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
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
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => _navigateToPlayer(song, allSongs),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovered ? Colors.purple.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Album art / Play button
              GestureDetector(
                onTap: () => _navigateToPlayer(song, allSongs),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: song['colors'] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: isHovered || song['isPlayButton'] == true
                      ? const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
              // Duration
              Text(
                song['duration'] as String,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              // Favorite button
              IconButton(
                icon: Icon(
                  song['isFavorite'] == true
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: song['isFavorite'] == true ? Colors.red : Colors.grey,
                ),
                onPressed: () {},
              ),
            ],
          ),
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
    // Different songs for different emotions
    switch (emotion.toLowerCase()) {
      case 'anxious':
        return [
          {
            'title': 'Deep Breathing',
            'subtitle': 'Calm Mind',
            'duration': '6:00',
            'colors': [Colors.orange.shade300, Colors.pink.shade200],
            'isFavorite': false,
            'isPlayButton': false,
          },
          {
            'title': 'Safe Space',
            'subtitle': 'Anxiety Relief',
            'duration': '5:30',
            'colors': [Colors.purple.shade300, Colors.blue.shade300],
            'isFavorite': false,
            'isPlayButton': true,
          },
          {
            'title': 'Everything Is Okay',
            'subtitle': 'Reassurance',
            'duration': '4:00',
            'colors': [Colors.orange.shade200, Colors.yellow.shade200],
            'isFavorite': false,
            'isPlayButton': false,
          },
        ];
      case 'happy':
        return [
          {
            'title': 'Good Vibes',
            'subtitle': 'Upbeat Energy',
            'duration': '4:30',
            'colors': [Colors.yellow.shade300, Colors.orange.shade300],
            'isFavorite': true,
            'isPlayButton': false,
          },
          {
            'title': 'Celebration',
            'subtitle': 'Joy & Happiness',
            'duration': '3:45',
            'colors': [Colors.pink.shade300, Colors.purple.shade300],
            'isFavorite': false,
            'isPlayButton': true,
          },
          {
            'title': 'Sunshine Day',
            'subtitle': 'Feel Good',
            'duration': '5:00',
            'colors': [Colors.blue.shade200, Colors.cyan.shade200],
            'isFavorite': false,
            'isPlayButton': false,
          },
        ];
      case 'sad':
        return [
          {
            'title': 'Gentle Comfort',
            'subtitle': 'Emotional Healing',
            'duration': '6:30',
            'colors': [Colors.blue.shade300, Colors.purple.shade200],
            'isFavorite': false,
            'isPlayButton': false,
          },
          {
            'title': 'You\'re Not Alone',
            'subtitle': 'Support & Care',
            'duration': '5:15',
            'colors': [Colors.teal.shade300, Colors.blue.shade300],
            'isFavorite': true,
            'isPlayButton': true,
          },
          {
            'title': 'Healing Journey',
            'subtitle': 'Inner Peace',
            'duration': '7:00',
            'colors': [Colors.indigo.shade200, Colors.purple.shade200],
            'isFavorite': false,
            'isPlayButton': false,
          },
        ];
      default:
        return [
          {
            'title': 'Peaceful Mind',
            'subtitle': 'Relaxation',
            'duration': '5:00',
            'colors': [Colors.green.shade300, Colors.teal.shade300],
            'isFavorite': false,
            'isPlayButton': false,
          },
          {
            'title': 'Balance',
            'subtitle': 'Harmony',
            'duration': '4:30',
            'colors': [Colors.purple.shade300, Colors.pink.shade300],
            'isFavorite': false,
            'isPlayButton': true,
          },
          {
            'title': 'Serenity',
            'subtitle': 'Calm Vibes',
            'duration': '6:00',
            'colors': [Colors.blue.shade200, Colors.green.shade200],
            'isFavorite': false,
            'isPlayButton': false,
          },
        ];
    }
  }
}
