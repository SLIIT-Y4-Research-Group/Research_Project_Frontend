import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
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
  late Future<List<Map<String, dynamic>>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _tracksFuture = _fetchTracks(widget.emotion);
  }

  Future<List<Map<String, dynamic>>> _fetchTracks(String emotion) async {
    final uri = Uri.parse(
      '${ApiConfig.BASE_URL}/music/tracks?emotion=${Uri.encodeComponent(emotion)}',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load tracks');
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return {
        'id': map['id'] ?? map['_id'],
        'title': map['title'] ?? 'Unknown Title',
        'subtitle': map['artist'] ?? 'Unknown Artist',
        'audio_url': map['audio_url'] ?? map['music_url'],
        'cover_url': map['cover_url'],
        'duration': '3:00',
        'colors': _colorsForEmotion(emotion),
        'isFavorite': false,
      };
    }).toList();
  }

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

  List<Color> _colorsForEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return [Colors.orange.shade300, Colors.yellow.shade300];
      case 'sad':
        return [Colors.blue.shade300, Colors.indigo.shade300];
      case 'anxious':
        return [Colors.purple.shade300, Colors.blueGrey.shade300];
      case 'calm':
        return [Colors.teal.shade300, Colors.green.shade300];
      case 'angry':
        return [Colors.red.shade300, Colors.deepOrange.shade300];
      default:
        return [Colors.green.shade300, Colors.teal.shade300];
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _tracksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load tracks',
                          style: TextStyle(color: Colors.red.shade300),
                        ),
                      );
                    }
                    final songs = snapshot.data ?? [];
                    if (songs.isEmpty) {
                      return const Center(
                        child: Text('No tracks found for this emotion'),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return _buildSongTile(song, index, songs);
                      },
                    );
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: song['cover_url'] != null
                ? Image.network(
                    song['cover_url'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 35,
                      );
                    },
                  )
                : const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 35,
                  ),
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
}
