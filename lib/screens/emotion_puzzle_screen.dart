import 'package:flutter/material.dart';
import 'dart:math';
import 'music_recommendation_screen.dart';

class EmotionPuzzleScreen extends StatefulWidget {
  final String detectedEmotion;

  const EmotionPuzzleScreen({super.key, required this.detectedEmotion});

  @override
  State<EmotionPuzzleScreen> createState() => _EmotionPuzzleScreenState();
}

class _EmotionPuzzleScreenState extends State<EmotionPuzzleScreen>
    with TickerProviderStateMixin {
  late List<int> _puzzlePieces;
  late List<int> _correctOrder;
  int _moves = 0;
  bool _isSolved = false;
  late AnimationController _celebrationController;

  // Emotion icons for the puzzle
  final List<IconData> _sadIcons = [
    Icons.sentiment_very_dissatisfied,
    Icons.cloud,
    Icons.water_drop,
    Icons.nightlight_round,
    Icons.sentiment_dissatisfied,
    Icons.thunderstorm,
    Icons.dark_mode,
    Icons.heart_broken,
    Icons.sentiment_neutral,
  ];

  final List<IconData> _happyIcons = [
    Icons.sentiment_very_satisfied,
    Icons.wb_sunny,
    Icons.favorite,
    Icons.star,
    Icons.emoji_emotions,
    Icons.celebration,
    Icons.light_mode,
    Icons.favorite_border,
    Icons.mood,
  ];

  final List<Color> _sadColors = [
    Colors.blue.shade300,
    Colors.grey.shade400,
    Colors.indigo.shade300,
    Colors.blueGrey.shade400,
    Colors.blue.shade400,
    Colors.grey.shade500,
    Colors.indigo.shade400,
    Colors.blueGrey.shade300,
    Colors.blue.shade200,
  ];

  final List<Color> _happyColors = [
    Colors.yellow.shade400,
    Colors.orange.shade300,
    Colors.pink.shade300,
    Colors.amber.shade400,
    Colors.green.shade400,
    Colors.purple.shade300,
    Colors.red.shade300,
    Colors.teal.shade300,
    Colors.lime.shade400,
  ];

  @override
  void initState() {
    super.initState();
    _correctOrder = List.generate(9, (index) => index);
    _puzzlePieces = List.generate(9, (index) => index);
    _shufflePuzzle();
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _shufflePuzzle() {
    final random = Random();
    for (int i = _puzzlePieces.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      int temp = _puzzlePieces[i];
      _puzzlePieces[i] = _puzzlePieces[j];
      _puzzlePieces[j] = temp;
    }
  }

  void _onPieceTap(int index) {
    if (_isSolved) return;

    // Find empty adjacent position to swap
    int emptyIndex = _puzzlePieces.indexOf(8);
    List<int> adjacentIndices = _getAdjacentIndices(index);

    if (adjacentIndices.contains(emptyIndex)) {
      setState(() {
        // Swap pieces
        int temp = _puzzlePieces[index];
        _puzzlePieces[index] = _puzzlePieces[emptyIndex];
        _puzzlePieces[emptyIndex] = temp;
        _moves++;

        // Check if solved
        _checkSolved();
      });
    }
  }

  List<int> _getAdjacentIndices(int index) {
    List<int> adjacent = [];
    int row = index ~/ 3;
    int col = index % 3;

    if (row > 0) adjacent.add(index - 3); // Top
    if (row < 2) adjacent.add(index + 3); // Bottom
    if (col > 0) adjacent.add(index - 1); // Left
    if (col < 2) adjacent.add(index + 1); // Right

    return adjacent;
  }

  void _checkSolved() {
    bool solved = true;
    for (int i = 0; i < _puzzlePieces.length; i++) {
      if (_puzzlePieces[i] != _correctOrder[i]) {
        solved = false;
        break;
      }
    }

    if (solved) {
      setState(() {
        _isSolved = true;
      });
      _celebrationController.forward();
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    Future.delayed(const Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                '🎉 Great Job! 🎉',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'You transformed sadness into happiness!\nCompleted in $_moves moves.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Remember: Every dark cloud has a silver lining! ☀️',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MusicRecommendationScreen(
                      emotion: widget.detectedEmotion,
                    ),
                  ),
                );
              },
              child: const Text('Listen to Music'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isSolved = false;
                  _moves = 0;
                  _shufflePuzzle();
                });
                _celebrationController.reset();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Play Again'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Transform Your Mood'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Instructions
              Container(
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sentiment_dissatisfied,
                          color: Colors.blue.shade400,
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.grey),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.sentiment_very_satisfied,
                          color: Colors.amber.shade400,
                          size: 30,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Solve the puzzle to transform\nsadness into happiness!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Moves: $_moves',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Puzzle Grid
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    int pieceIndex = _puzzlePieces[index];
                    bool isCorrect =
                        _puzzlePieces[index] == _correctOrder[index];
                    bool isEmpty = pieceIndex == 8;

                    return GestureDetector(
                      onTap: () => _onPieceTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isEmpty
                              ? Colors.grey.shade200
                              : (_isSolved
                                    ? _happyColors[pieceIndex]
                                    : (isCorrect
                                          ? _happyColors[pieceIndex]
                                          : _sadColors[pieceIndex])),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCorrect && !isEmpty
                                ? Colors.green.shade300
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isEmpty
                              ? null
                              : [
                                  BoxShadow(
                                    color:
                                        (_isSolved
                                                ? _happyColors[pieceIndex]
                                                : _sadColors[pieceIndex])
                                            .withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: isEmpty
                            ? null
                            : Center(
                                child: Icon(
                                  _isSolved || isCorrect
                                      ? _happyIcons[pieceIndex]
                                      : _sadIcons[pieceIndex],
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Target preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Target: Happy State 😊',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 9,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: _happyColors[index],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Icon(
                                _happyIcons[index],
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Skip button
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MusicRecommendationScreen(
                        emotion: widget.detectedEmotion,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Skip to Music →',
                  style: TextStyle(color: Colors.purple, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
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
}
