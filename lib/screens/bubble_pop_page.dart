import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class BubblePopPage extends StatefulWidget {
  const BubblePopPage({super.key});

  @override
  State<BubblePopPage> createState() => _BubblePopPageState();
}

class _BubblePopPageState extends State<BubblePopPage> {
  final Random _random = Random();
  final List<_Bubble> bubbles = [];

  int score = 0;
  int timeLeft = 30;
  bool gameRunning = false;

  Timer? spawnTimer;
  Timer? moveTimer;
  Timer? gameTimer;

  Size screenSize = Size.zero;

  // Vivid, saturated bubble colour palette
  static const List<Color> _bubbleColors = [
    Color(0xFFFF3CAC), // hot pink
    Color(0xFF784BA0), // purple
    Color(0xFF2B86C5), // ocean blue
    Color(0xFF00C9FF), // cyan
    Color(0xFF00F2A9), // mint green
    Color(0xFFFFD700), // golden yellow
    Color(0xFFFF6B35), // vivid orange
    Color(0xFFFF1744), // red
    Color(0xFF00E5FF), // electric cyan
    Color(0xFFAEEA00), // lime
    Color(0xFFFF6EC7), // bubblegum pink
    Color(0xFF651FFF), // deep violet
  ];

  void startGame() {
    if (gameRunning) return;

    setState(() {
      score = 0;
      timeLeft = 30;
      bubbles.clear();
      gameRunning = true;
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

      setState(() {
        timeLeft--;
      });

      if (timeLeft <= 0) {
        stopGame();
      }
    });
  }

  void stopGame() {
    spawnTimer?.cancel();
    moveTimer?.cancel();
    gameTimer?.cancel();

    setState(() {
      gameRunning = false;
    });
  }

  void spawnBubble() {
    if (screenSize == Size.zero) return;

    final size = 40 + _random.nextDouble() * 60;

    final x = _random.nextDouble() * (screenSize.width - size);
    final y = screenSize.height + 8;

    // upward speed
    final vy = 1.2 + _random.nextDouble() * 2.2;

    // slanted drift: some bubbles more slanted than others
    final vx = (_random.nextDouble() * 2 - 1) * (0.3 + _random.nextDouble() * 0.9);

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

        // normal floating
        b.y -= b.vy;

        // slanted drift while floating
        b.x += b.vx;

        // gentle bounce on side walls
        if (b.x <= 0) {
          b.x = 0;
          b.vx = -b.vx;
        } else if (b.x + b.size >= w) {
          b.x = w - b.size;
          b.vx = -b.vx;
        }

        // pop animation progress (if popped)
        if (b.popped) {
          b.popProgress = (b.popProgress + 0.08).clamp(0.0, 1.0);
          if (b.popProgress >= 1.0) {
            b.removed = true;
          }
        }
      }

      // remove bubbles off top or finished popping
      bubbles.removeWhere((b) => b.removed || b.y < -120);
    });
  }

  void popBubble(_Bubble bubble) {
    if (!gameRunning) return;
    if (bubble.popped) return;

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
      appBar: AppBar(
        title: const Text("බුබුළු පුපුරවන්න"),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE3F2FD), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Bubbles
          ...bubbles.map((bubble) {
            // Pop animation: expands + fades
            final double scale = bubble.popped ? (1.0 + 0.9 * bubble.popProgress) : 1.0;
            final double opacity = bubble.popped ? (1.0 - bubble.popProgress) : 1.0;

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
                          )
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

          // Score & Timer
          Positioned(
            top: 20,
            left: 20,
            child: _InfoBox("ලකුණු : $score"),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: _InfoBox("වේලාව : $timeLeft"),
          ),

          // Start Button (only show if not running and not game over)
          if (!gameRunning && timeLeft > 0)
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(76, 175, 80, 1),
                  foregroundColor: Colors.white,
                ),
                onPressed: startGame,
                child: const Text("ක්‍රීඩාව ආරම්භ කරන්න"),
              ),
            ),

          // Game Over
          if (!gameRunning && timeLeft == 0)
            Center(
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "වේලාව අවසන්!",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text("ඔබගේ ලකුණු: $score"),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(76, 175, 80, 1),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            timeLeft = 30;
                          });
                          startGame();
                        },
                        child: const Text("නැවත ක්‍රීඩා කරන්න"),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble {
  final int id;

  double x;
  double y;
  final double size;

  // movement
  double vx; // horizontal drift (slanted movement)
  double vy; // upward speed

  final Color color;
  final Color borderColor;

  // pop animation
  bool popped = false;
  double popProgress = 0.0; // 0..1
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
        color: Color.fromRGBO(76, 175, 80, 1),
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