import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;
import 'music_recommendation_screen.dart';

class EmotionPuzzleScreen extends StatefulWidget {
  final String detectedEmotion;
  final Uint8List? happyFaceImage;

  const EmotionPuzzleScreen({
    super.key,
    required this.detectedEmotion,
    this.happyFaceImage,
  });

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
  ui.Image? _decodedImage;
  bool _imageLoaded = false;
  final int _gridSize = 3; // 3x3 puzzle

  @override
  void initState() {
    super.initState();
    _correctOrder = List.generate(_gridSize * _gridSize, (index) => index);
    _puzzlePieces = List.generate(_gridSize * _gridSize, (index) => index);
    _shufflePuzzle();
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.happyFaceImage != null) {
      final codec = await ui.instantiateImageCodec(widget.happyFaceImage!);
      final frame = await codec.getNextFrame();
      setState(() {
        _decodedImage = frame.image;
        _imageLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _shufflePuzzle() {
    final random = Random();
    // Do many random swaps to ensure good shuffle
    for (int i = 0; i < 100; i++) {
      int idx1 = random.nextInt(_puzzlePieces.length);
      int idx2 = random.nextInt(_puzzlePieces.length);
      int temp = _puzzlePieces[idx1];
      _puzzlePieces[idx1] = _puzzlePieces[idx2];
      _puzzlePieces[idx2] = temp;
    }
  }

  void _onPieceTap(int tappedIndex) {
    if (_isSolved) return;

    // Find if there's an adjacent empty piece (piece at index gridSize*gridSize - 1)
    int emptyPieceValue = _gridSize * _gridSize - 1;
    int emptyIndex = _puzzlePieces.indexOf(emptyPieceValue);
    List<int> adjacentIndices = _getAdjacentIndices(tappedIndex);

    if (adjacentIndices.contains(emptyIndex)) {
      setState(() {
        // Swap pieces
        int temp = _puzzlePieces[tappedIndex];
        _puzzlePieces[tappedIndex] = _puzzlePieces[emptyIndex];
        _puzzlePieces[emptyIndex] = temp;
        _moves++;

        // Check if solved
        _checkSolved();
      });
    }
  }

  List<int> _getAdjacentIndices(int index) {
    List<int> adjacent = [];
    int row = index ~/ _gridSize;
    int col = index % _gridSize;

    if (row > 0) adjacent.add(index - _gridSize); // Top
    if (row < _gridSize - 1) adjacent.add(index + _gridSize); // Bottom
    if (col > 0) adjacent.add(index - 1); // Left
    if (col < _gridSize - 1) adjacent.add(index + 1); // Right

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
                '🎉 සුබ පැතුම්! 🎉',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'ඔබ සතුටු මුහුණ සාර්ථකව නිර්මාණය කළා!\nපියවර ගණන: $_moves',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (widget.happyFaceImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    widget.happyFaceImage!,
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'ඔබේ සතුටු මුහුණ මෙන්න! 😊',
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
                    builder: (context) =>
                        MusicRecommendationScreen(emotion: 'happy'),
                  ),
                );
              },
              child: const Text('සංගීතය අසන්න'),
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
              child: const Text('නැවත ක්‍රීඩා කරන්න'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPuzzlePiece(int pieceIndex, int displayIndex, double pieceSize) {
    bool isCorrect = _puzzlePieces[displayIndex] == _correctOrder[displayIndex];
    bool isEmpty = pieceIndex == _gridSize * _gridSize - 1;

    if (isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    if (_decodedImage == null || !_imageLoaded) {
      // Fallback to colored tiles while loading
      return Container(
        decoration: BoxDecoration(
          color: Colors.purple.shade300,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCorrect ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '${pieceIndex + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Calculate the source rectangle for this piece from the original image
    int pieceRow = pieceIndex ~/ _gridSize;
    int pieceCol = pieceIndex % _gridSize;
    double srcPieceWidth = _decodedImage!.width / _gridSize;
    double srcPieceHeight = _decodedImage!.height / _gridSize;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect ? Colors.green.shade400 : Colors.white,
          width: isCorrect ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          size: Size(pieceSize, pieceSize),
          painter: PuzzlePiecePainter(
            image: _decodedImage!,
            srcRect: Rect.fromLTWH(
              pieceCol * srcPieceWidth,
              pieceRow * srcPieceHeight,
              srcPieceWidth,
              srcPieceHeight,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double puzzleSize = MediaQuery.of(context).size.width - 48;
    double pieceSize = (puzzleSize - 16) / _gridSize;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('සතුටු මුහුණ ප්‍රහේලිකාව'),
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
                          Icons.extension,
                          color: Colors.orange.shade400,
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.grey),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.sentiment_very_satisfied,
                          color: Colors.green.shade400,
                          size: 30,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ප්‍රහේලිකාව විසඳා ඔබේ\nසතුටු මුහුණ නිර්මාණය කරන්න!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'පියවර: $_moves',
                      style: TextStyle(
                        fontSize: 18,
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
                child: _imageLoaded || widget.happyFaceImage == null
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridSize,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: _gridSize * _gridSize,
                        itemBuilder: (context, index) {
                          int pieceIndex = _puzzlePieces[index];
                          return GestureDetector(
                            onTap: () => _onPieceTap(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: _buildPuzzlePiece(
                                pieceIndex,
                                index,
                                pieceSize,
                              ),
                            ),
                          );
                        },
                      )
                    : const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      ),
              ),
              const SizedBox(height: 20),

              // Target preview - show the complete happy face
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ඉලක්කය: සතුටු මුහුණ 😊',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.happyFaceImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          widget.happyFaceImage!,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.sentiment_very_satisfied,
                            size: 60,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Shuffle button
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _moves = 0;
                        _isSolved = false;
                        _shufflePuzzle();
                      });
                    },
                    icon: const Icon(Icons.shuffle),
                    label: const Text('මිශ්‍ර කරන්න'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  // Skip button
                  TextButton.icon(
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
                    icon: const Icon(Icons.skip_next),
                    label: const Text('සංගීතයට යන්න'),
                    style: TextButton.styleFrom(foregroundColor: Colors.purple),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter to draw a portion of the image
class PuzzlePiecePainter extends CustomPainter {
  final ui.Image image;
  final Rect srcRect;

  PuzzlePiecePainter({required this.image, required this.srcRect});

  @override
  void paint(Canvas canvas, Size size) {
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant PuzzlePiecePainter oldDelegate) {
    return oldDelegate.srcRect != srcRect;
  }
}
