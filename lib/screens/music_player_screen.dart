import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:just_audio/just_audio.dart';
import '../config/api_config.dart';

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
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late Map<String, dynamic> _currentSong;
  late int _currentIndex;
  final List<String> _playerAnimations = const [
    'assets/animations/Music Player.json',
    'assets/animations/media player dancing.json',
    'assets/animations/alarmclock-lottie.json',
  ];

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _currentIndex = widget.playlist.indexOf(widget.song);

    _player.durationStream.listen((d) {
      if (d != null) {
        setState(() => _duration = d);
      }
    });
    _player.positionStream.listen((p) {
      setState(() => _position = p);
    });
    _player.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
        _isLoading = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
      });
    });

    _loadSong(_currentSong);
  }

  Future<void> _loadSong(Map<String, dynamic> song) async {
    Map<String, dynamic> songToPlay = song;
    final urlValue =
        (song['audio_url'] ?? song['music_url']) as String?;
    final idValue = song['id']?.toString();

    if ((urlValue == null || urlValue.isEmpty) &&
        idValue != null &&
        idValue.isNotEmpty) {
      final details = await _fetchTrackDetails(idValue);
      if (details != null) {
        songToPlay = {...song, ...details};
        _updateCurrentSong(songToPlay);
      }
    }

    final url = songToPlay['audio_url'] as String?;
    if (url == null || url.isEmpty) return;
    try {
      setState(() => _isLoading = true);
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to play this track')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchTrackDetails(String trackId) async {
    final uri = Uri.parse('${ApiConfig.BASE_URL}/music/tracks/$trackId');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'id': data['id'] ?? data['_id'] ?? trackId,
      'title': data['title'],
      'subtitle': data['artist'],
      'audio_url': data['audio_url'] ?? data['music_url'],
      'cover_url': data['cover_url'],
    };
  }

  void _updateCurrentSong(Map<String, dynamic> song) {
    setState(() {
      _currentSong = song;
      if (_currentIndex >= 0 && _currentIndex < widget.playlist.length) {
        widget.playlist[_currentIndex] = song;
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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
                  const Color(0xFF121212),
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
                        const SizedBox(height: 12),
                        _buildMusicAnimation(),
                        const SizedBox(height: 40),
                        _buildSongInfo(),
                        const SizedBox(height: 30),
                        _buildWaveformPlaceholder(),
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
    final coverUrl = _currentSong['cover_url'] as String?;
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: coverUrl != null
            ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMusicAnimation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Lottie.asset(
          _playerAnimations[_currentIndex % _playerAnimations.length],
          fit: BoxFit.contain,
        ),
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
                  _currentSong['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentSong['subtitle'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _currentSong['isFavorite'] == true
                ? Icons.favorite
                : Icons.favorite_border,
            color: _currentSong['isFavorite'] == true
                ? Colors.redAccent
                : Colors.white,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformPlaceholder() {
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
    final maxMs = _duration.inMilliseconds;
    final posMs = _position.inMilliseconds.clamp(0, maxMs);
    final value = maxMs == 0 ? 0.0 : posMs / maxMs;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 0,
              ),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              onChanged: (v) {
                final seekMs = (v * maxMs).toInt();
                _player.seek(Duration(milliseconds: seekMs));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDuration(_duration),
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
          onPressed: _playPrevious,
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
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
          onPressed: _playNext,
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
            onTap: () {
              setState(() {
                _currentIndex = index;
                _currentSong = song;
              });
              _loadSong(song);
            },
          ),
        );
      },
    );
  }

  void _togglePlay() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _playNext() {
    if (widget.playlist.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % widget.playlist.length;
    setState(() {
      _currentIndex = nextIndex;
      _currentSong = widget.playlist[nextIndex];
    });
    _loadSong(_currentSong);
  }

  void _playPrevious() {
    if (widget.playlist.isEmpty) return;
    final prevIndex = (_currentIndex - 1 + widget.playlist.length) %
        widget.playlist.length;
    setState(() {
      _currentIndex = prevIndex;
      _currentSong = widget.playlist[prevIndex];
    });
    _loadSong(_currentSong);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
