import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // Sample favorite items - in a real app, this would come from a database
  final List<Map<String, dynamic>> _favoriteMusic = [
    {
      'title': 'Calm Piano',
      'artist': 'Relaxation Music',
      'mood': 'calm',
      'icon': Icons.music_note,
      'color': Colors.blue.shade100,
    },
    {
      'title': 'Happy Vibes',
      'artist': 'Feel Good Beats',
      'mood': 'happy',
      'icon': Icons.music_note,
      'color': Colors.yellow.shade100,
    },
    {
      'title': 'Peaceful Mind',
      'artist': 'Meditation Sounds',
      'mood': 'neutral',
      'icon': Icons.music_note,
      'color': Colors.green.shade100,
    },
  ];

  final List<Map<String, dynamic>> _moodHistory = [
    {'date': 'අද', 'mood': 'happy', 'emoji': '😊', 'time': '10:30 AM'},
    {'date': 'ඊයේ', 'mood': 'calm', 'emoji': '😌', 'time': '3:45 PM'},
    {'date': 'ඊයේ', 'mood': 'sad', 'emoji': '😢', 'time': '9:00 AM'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'ප්‍රියතම',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Favorite Music Section
            _buildSectionHeader('ප්‍රියතම සංගීතය', Icons.music_note),
            const SizedBox(height: 12),
            _favoriteMusic.isEmpty
                ? _buildEmptyState('තවම ප්‍රියතම සංගීතයක් නැත', Icons.music_off)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _favoriteMusic.length,
                    itemBuilder: (context, index) {
                      final music = _favoriteMusic[index];
                      return _buildMusicCard(music, index);
                    },
                  ),
            const SizedBox(height: 24),

            // Mood History Section
            _buildSectionHeader('මනෝභාව ඉතිහාසය', Icons.history),
            const SizedBox(height: 12),
            _moodHistory.isEmpty
                ? _buildEmptyState(
                    'තවම මනෝභාව වාර්තා නැත',
                    Icons.sentiment_neutral,
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _moodHistory.length,
                    itemBuilder: (context, index) {
                      final mood = _moodHistory[index];
                      return _buildMoodHistoryCard(mood);
                    },
                  ),
            const SizedBox(height: 24),

            // Completed Puzzles Section
            _buildSectionHeader('සම්පූර්ණ කළ ප්‍රහේලිකා', Icons.extension),
            const SizedBox(height: 12),
            _buildPuzzleStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.purple, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicCard(Map<String, dynamic> music, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: music['color'],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(music['icon'], color: Colors.purple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  music['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  music['artist'],
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _favoriteMusic.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ප්‍රියතම ලැයිස්තුවෙන් ඉවත් කරන ලදී'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.favorite, color: Colors.red),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.play_circle_fill, color: Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodHistoryCard(Map<String, dynamic> mood) {
    Color moodColor;
    switch (mood['mood']) {
      case 'happy':
        moodColor = Colors.amber;
        break;
      case 'sad':
        moodColor = Colors.blue;
        break;
      case 'calm':
        moodColor = Colors.green;
        break;
      case 'angry':
        moodColor = Colors.red;
        break;
      default:
        moodColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: moodColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(mood['emoji'], style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood['mood'].toString().toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${mood['date']} • ${mood['time']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: moodColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              mood['mood'],
              style: TextStyle(
                color: moodColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleStats() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('සම්පූර්ණ කළ', '5', Colors.green),
              _buildStatItem('හොඳම පියවර', '12', Colors.orange),
              _buildStatItem('මුළු කාලය', '25m', Colors.purple),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ප්‍රහේලිකා මාස්ටර්!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'ඔබ ප්‍රහේලිකා 5ක් සම්පූර්ණ කළා!',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}
