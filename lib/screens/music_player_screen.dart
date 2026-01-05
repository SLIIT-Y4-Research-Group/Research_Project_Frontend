import 'dart:ui';
import 'package:flutter/material.dart';

class MusicPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> song;
  final List<Map<String, dynamic>> playlist;
  final String emotion;

  const MusicPlayerScreen({
    super.key,
    required this.song,
    required this.playlist,
    required this.emotion,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  bool _isPlaying = true;
  double _currentPosition = 0.35; // Example progress
  late Map<String, dynamic> _currentSong;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _currentIndex = widget.playlist.indexOf(widget.song);
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> songColors = (_currentSong['colors'] as List<Color>);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Dynamic Background Gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  songColors[0].withOpacity(0.8),
                  songColors[1].withOpacity(0.6),
                  const Color(0xFF121212), // Deep dark base
                ],
              ),
            ),
          ),

          // 2. Glassmorphic Overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildHeroAlbumArt(songColors),
                        const SizedBox(height: 40),
                        _buildSongInfo(),
                        const SizedBox(height: 30),
                        _buildWaveformPlaceholder(), // 2026 Design Trend
                        _buildModernProgressBar(),
                        _buildMainControls(),
                        const SizedBox(height: 40),
                        _buildQueueHeader(),
                        _buildModernPlaylist(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.expand_more, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                'PLAYING FROM MOOD',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              Text(
                widget.emotion.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeroAlbumArt(List<Color> colors) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.5),
            blurRadius: 50,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSongInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentSong['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentSong['subtitle'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _currentSong['isFavorite'] ? Icons.favorite : Icons.favorite_border,
            color: _currentSong['isFavorite'] ? Colors.redAccent : Colors.white,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformPlaceholder() {
    // In 2026, real-time waveforms are standard.
    // This is a visual representation.
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          30,
          (i) => Container(
            width: 3,
            height: (i % 5 * 10.0) + 10,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 0,
              ), // Minimalist
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
            ),
            child: Slider(
              value: _currentPosition,
              onChanged: (v) => setState(() => _currentPosition = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "1:24",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _currentSong['duration'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shuffle, color: Colors.white54),
          onPressed: () {},
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(
            Icons.skip_previous_rounded,
            color: Colors.white,
            size: 45,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () => setState(() => _isPlaying = !_isPlaying),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.black,
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(
            Icons.skip_next_rounded,
            color: Colors.white,
            size: 45,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.repeat, color: Colors.white54),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildQueueHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Up Next",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildModernPlaylist() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.playlist.length,
      itemBuilder: (context, index) {
        final song = widget.playlist[index];
        bool isSelected = index == _currentIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: song['colors']),
                ),
              ),
            ),
            title: Text(
              song['title'],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              song['subtitle'],
              style: const TextStyle(color: Colors.white38),
            ),
            trailing: isSelected
                ? const Icon(Icons.bar_chart, color: Colors.white)
                : const Text("3:45", style: TextStyle(color: Colors.white38)),
          ),
        );
      },
    );
  }
}
