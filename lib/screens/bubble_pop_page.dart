import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/leaderboard_service.dart';
import '../widgets/child_bottom_nav_bar.dart';

class BubblePopPage extends StatefulWidget {
  const BubblePopPage({
    super.key,
    this.triggeredByEmotion,
  });

  final String? triggeredByEmotion;

  @override
  State<BubblePopPage> createState() => _BubblePopPageState();
}

class _BubblePopPageState extends State<BubblePopPage> {
  final Random _random = Random();
  final List<_Bubble> bubbles = [];

  int score = 0;
  int timeLeft = 30;
  bool gameRunning = false;
  bool _isLoading = false;
  bool _isSubmitting = false;

  Timer? spawnTimer;
  Timer? moveTimer;
  Timer? gameTimer;

  DateTime? _gameStartTime;

  Size screenSize = Size.zero;

  static const List<Color> _bubbleColors = [
    Color(0xFFFF3CAC),
    Color(0xFF784BA0),
    Color(0xFF2B86C5),
    Color(0xFF00C9FF),
    Color(0xFF00F2A9),
    Color(0xFFFFD700),
    Color(0xFFFF6B35),
    Color(0xFFFF1744),
    Color(0xFF00E5FF),
    Color(0xFFAEEA00),
    Color(0xFFFF6EC7),
    Color(0xFF651FFF),
  ];

  Future<void> startGame() async {
    if (gameRunning || _isLoading) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    _gameStartTime = DateTime.now();

    setState(() {
      score = 0;
      timeLeft = 30;
      bubbles.clear();
      gameRunning = true;
      _isLoading = false;
    });

    spawnTimer?.cancel();
    spawnTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (!gameRunning) return;
      if (bubbles.where((b) => !b.removed).length < 12) {
        spawnBubble();
      }
    });

    moveTimer?.cancel();
    moveTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!gameRunning) return;
      moveBubbles();
    });

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!gameRunning) return;

      setState(() => timeLeft--);

      if (timeLeft <= 0) {
        stopGame();
      }
    });
  }

  void stopGame() {
    spawnTimer?.cancel();
    moveTimer?.cancel();
    gameTimer?.cancel();

    setState(() => gameRunning = false);

    _logSession();
  }

  Future<void> _logSession() async {
    if (_gameStartTime == null) return;

    final duration =
        DateTime.now().difference(_gameStartTime!).inSeconds.clamp(1, 300);

    try {
      await ApiClient.logTherapySession(
        activityType: 'bubble_pop',
        durationSeconds: duration,
        score: score,
        triggeredByEmotion: widget.triggeredByEmotion,
      );
    } catch (_) {}
  }

  void spawnBubble() {
    if (screenSize == Size.zero) return;

    final size = 40 + _random.nextDouble() * 60;
    final x = _random.nextDouble() * (screenSize.width - size);
    final y = screenSize.height + 8;
    final vy = 1.2 + _random.nextDouble() * 2.2;
    final vx =
        (_random.nextDouble() * 2 - 1) * (0.3 + _random.nextDouble() * 0.9);
    final baseColor = _bubbleColors[_random.nextInt(_bubbleColors.length)];

    setState(() {
      bubbles.add(
        _Bubble(
          id: _random.nextInt(1 << 31),
          x: x,
          y: y,
          size: size,
          vx: vx,
          vy: vy,
          color: baseColor.withValues(alpha: 0.55),
          borderColor: baseColor.withValues(alpha: 0.9),
        ),
      );
    });
  }

  void moveBubbles() {
    final w = screenSize.width;

    setState(() {
      for (final b in bubbles) {
        if (b.removed) continue;

        b.y -= b.vy;
        b.x += b.vx;

        if (b.x <= 0) {
          b.x = 0;
          b.vx = -b.vx;
        } else if (b.x + b.size >= w) {
          b.x = w - b.size;
          b.vx = -b.vx;
        }

        if (b.popped) {
          b.popProgress = (b.popProgress + 0.08).clamp(0.0, 1.0);
          if (b.popProgress >= 1.0) {
            b.removed = true;
          }
        }
      }

      bubbles.removeWhere((b) => b.removed || b.y < -120);
    });
  }

  void popBubble(_Bubble bubble) {
    if (!gameRunning || bubble.popped) return;

    setState(() {
      bubble.popped = true;
      bubble.popProgress = 0.0;
      score++;
    });
  }

  @override
  void dispose() {
    spawnTimer?.cancel();
    moveTimer?.cancel();
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;

    return Scaffold(
      bottomNavigationBar: const ChildBottomNavBar(currentIndex: 2),
      appBar: AppBar(
        title: const Text('බුබුළු පුපුරවන්න'),
        backgroundColor: const Color(0xFF4EAA57),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE3F2FD),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          ...bubbles.map((bubble) {
            final double scale =
                bubble.popped ? (1.0 + 0.9 * bubble.popProgress) : 1.0;
            final double opacity =
                bubble.popped ? (1.0 - bubble.popProgress) : 1.0;

            return Positioned(
              left: bubble.x,
              top: bubble.y,
              child: Opacity(
                opacity: opacity,
                child: GestureDetector(
                  onTap: () => popBubble(bubble),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: bubble.size,
                      height: bubble.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bubble.color,
                        border: Border.all(
                          color: bubble.borderColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: bubble.borderColor.withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Align(
                        alignment: const Alignment(-0.3, -0.3),
                        child: Container(
                          width: bubble.size * 0.25,
                          height: bubble.size * 0.25,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          Positioned(
            top: 20,
            left: 20,
            child: _InfoBox('ලකුණු : $score'),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: _InfoBox('වේලාව : $timeLeft'),
          ),

          if (!gameRunning && timeLeft > 0 && !_isLoading)
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4EAA57),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: startGame,
                child: const Text('ක්‍රීඩාව ආරම්භ කරන්න'),
              ),
            ),

          if (!gameRunning && timeLeft == 0 && !_isLoading)
            Center(
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'වේලාව අවසන්!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('ඔබගේ ලකුණු: $score'),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitLeaderboardScore(context),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('ලකුණු ඉදිරිපත් කරන්න'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4EAA57),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async => startGame(),
                        child: const Text('නැවත ක්‍රීඩා කරන්න'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4EAA57),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submitLeaderboardScore(BuildContext context) async {
    if (_isSubmitting) return;

    final nameController = TextEditingController();
    final levelController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('ලකුණු ඉදිරිපත් කරන්න'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ක්‍රීඩකයාගේ නම',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'නම ඇතුළත් කරන්න'
                      : null,
                ),
                TextFormField(
                  controller: levelController,
                  decoration: const InputDecoration(
                    labelText: 'මට්ටම',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => (int.tryParse(v ?? '') == null)
                      ? 'වලංගු මට්ටමක් ඇතුළත් කරන්න'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('අවලංගු කරන්න'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(dialogContext, true);
              },
              child: const Text('ඉදිරිපත් කරන්න'),
            ),
          ],
        ),
      );

      if (result != true) return;

      setState(() => _isSubmitting = true);

      final timePlayed = (30 - timeLeft).clamp(0, 30).toDouble();

      await LeaderboardService.createEntry(
        playerName: nameController.text.trim(),
        score: score,
        level: int.parse(levelController.text.trim()),
        time: timePlayed,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ලකුණු ඉදිරිපත් කරන ලදී.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ඉදිරිපත් කිරීම අසාර්ථකයි: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
      nameController.dispose();
      levelController.dispose();
    }
  }
}

class _Bubble {
  final int id;
  double x;
  double y;
  final double size;
  double vx;
  double vy;
  final Color color;
  final Color borderColor;
  bool popped = false;
  double popProgress = 0.0;
  bool removed = false;

  _Bubble({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.vx,
    required this.vy,
    required this.color,
    required this.borderColor,
  });
}

class _InfoBox extends StatelessWidget {
  final String text;

  const _InfoBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4EAA57),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}