import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:typed_data';
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

class _DragPayload {
  final int piece;
  final int? fromSlot;

  const _DragPayload({required this.piece, this.fromSlot});
}

class _EmotionPuzzleScreenState extends State<EmotionPuzzleScreen>
    with TickerProviderStateMixin {
  final int _gridSize = 4; // 4x4 puzzle
  late List<int> _trayPieces;
  late List<int?> _placements;
  int _moves = 0;
  bool _isSolved = false;
  late AnimationController _celebrationController;
  late AnimationController _particleController;
  ui.Image? _decodedImage;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _initPuzzle();
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _particleController = AnimationController(
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
    _particleController.dispose();
    super.dispose();
  }

  void _initPuzzle() {
    _trayPieces = List.generate(_gridSize * _gridSize, (index) => index);
    _trayPieces.shuffle();
    _placements = List.filled(_gridSize * _gridSize, null);
    _moves = 0;
    _isSolved = false;
  }

  void _checkSolved() {
    if (_placements.any((piece) => piece == null)) {
      return;
    }
    for (int i = 0; i < _placements.length; i++) {
      if (_placements[i] != i) {
        return;
      }
    }
    _isSolved = true;
    _celebrationController.forward();
    _particleController.forward();
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    Future.delayed(const Duration(milliseconds: 300), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 20,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                ScaleTransition(
                  scale: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _celebrationController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    size: 120,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '🎉 සුබ පැතුම්! 🎉',
                  style: GoogleFonts.fredoka(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF6B6B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'ඔබ සතුටු මුහුණ සම්පූර්ණ කළා!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.happyFaceImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF4ECDC4),
                          width: 6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4ECDC4).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.memory(
                        widget.happyFaceImage!,
                        height: 180,
                        width: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'Moves: $_moves 🏆',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFB700),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ECDC4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        '🎵 සංගීතය අසන්න',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _initPuzzle();
                        });
                        _celebrationController.reset();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFFF6B6B),
                          width: 3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        '🔄 නැවත ක්‍රීඩා කරන්න',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF6B6B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPuzzlePiece(
    int pieceIndex,
    double pieceSize, {
    bool isHint = false,
    double padding = 0,
    double? borderWidthOverride,
    bool flatEdges = false,
  }) {
    final double visualSize = pieceSize + padding * 2;
    if (_decodedImage == null || !_imageLoaded) {
      return Container(
        width: visualSize,
        height: visualSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade200, Colors.cyan.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    }

    int pieceRow = pieceIndex ~/ _gridSize;
    int pieceCol = pieceIndex % _gridSize;
    double srcPieceWidth = _decodedImage!.width / _gridSize;
    double srcPieceHeight = _decodedImage!.height / _gridSize;

    return CustomPaint(
      size: Size(visualSize, visualSize),
      painter: JigsawPiecePainter(
        image: _decodedImage!,
        srcRect: Rect.fromLTWH(
          pieceCol * srcPieceWidth,
          pieceRow * srcPieceHeight,
          srcPieceWidth,
          srcPieceHeight,
        ),
        row: pieceRow,
        col: pieceCol,
        gridSize: _gridSize,
        borderColor: isHint ? Colors.transparent : const Color(0xFF4ECDC4),
        borderWidth: borderWidthOverride ?? (isHint ? 0 : 2.5),
        opacity: isHint ? 0.35 : 1.0,
        padding: padding,
        flatEdges: flatEdges,
      ),
    );
  }

  Widget _buildBoard(double boardSize) {
    final double pieceSize = boardSize / _gridSize;
    final double tabPadding = pieceSize * 0.18;
    final double visualSize = pieceSize + tabPadding * 2;

    return Container(
      width: boardSize + tabPadding * 2,
      height: boardSize + tabPadding * 2,
      padding: EdgeInsets.all(tabPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFF5E1), const Color(0xFFE8F8F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF4ECDC4), width: 5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(_gridSize * _gridSize, (index) {
          int row = index ~/ _gridSize;
          int col = index % _gridSize;
          final int? placedPiece = _placements[index];

          return Positioned(
            left: col * pieceSize - tabPadding,
            top: row * pieceSize - tabPadding,
            width: visualSize,
            height: visualSize,
            child: DragTarget<_DragPayload>(
              onWillAccept: (payload) => payload != null,
              onAccept: (payload) {
                setState(() {
                  if (payload.fromSlot == null) {
                    final existing = _placements[index];
                    if (existing != null) {
                      _trayPieces.add(existing);
                    }
                    _trayPieces.remove(payload.piece);
                    _placements[index] = payload.piece;
                  } else if (payload.fromSlot != index) {
                    final existing = _placements[index];
                    _placements[index] = payload.piece;
                    _placements[payload.fromSlot!] = existing;
                  }
                  _moves++;
                  _checkSolved();
                });
              },
              builder: (context, candidateData, rejectedData) {
                if (placedPiece != null) {
                  final isCorrect = placedPiece == index;
                  return Draggable<_DragPayload>(
                    data: _DragPayload(piece: placedPiece, fromSlot: index),
                    feedback: Material(
                      color: Colors.transparent,
                      child: _buildPuzzlePiece(
                        placedPiece,
                        pieceSize,
                        padding: tabPadding,
                        borderWidthOverride: isCorrect ? 0 : null,
                        flatEdges: isCorrect,
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildPuzzlePiece(
                        placedPiece,
                        pieceSize,
                        padding: tabPadding,
                        borderWidthOverride: isCorrect ? 0 : null,
                        flatEdges: isCorrect,
                      ),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        boxShadow: isCorrect
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4ECDC4,
                                  ).withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: _buildPuzzlePiece(
                        placedPiece,
                        pieceSize,
                        padding: tabPadding,
                        borderWidthOverride: isCorrect ? 0 : null,
                        flatEdges: isCorrect,
                      ),
                    ),
                  );
                }
                return Container(
                  decoration: candidateData.isNotEmpty
                      ? BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF4ECDC4).withOpacity(0.7),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4ECDC4).withOpacity(0.3),
                              blurRadius: 12,
                            ),
                          ],
                        )
                      : null,
                  child: _buildPuzzlePiece(
                    index,
                    pieceSize,
                    isHint: true,
                    padding: tabPadding,
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPiecesTray(double width, double boardPieceSize) {
    final double trayPieceSize = boardPieceSize * 0.8;

    return DragTarget<_DragPayload>(
      onWillAccept: (payload) => payload?.fromSlot != null,
      onAccept: (payload) {
        setState(() {
          _placements[payload.fromSlot!] = null;
          _trayPieces.add(payload.piece);
          _moves++;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: width,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: candidateData.isNotEmpty
                  ? [const Color(0xFFE8F8F5), const Color(0xFFD4F1F4)]
                  : [const Color(0xFFFFF9F0), const Color(0xFFFFEFE0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF4ECDC4), width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4ECDC4).withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.extension,
                    size: 28,
                    color: Color(0xFF4ECDC4),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'අremaining pieces',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: _trayPieces.isNotEmpty
                    ? _trayPieces.map((pieceIndex) {
                        return Draggable<_DragPayload>(
                          data: _DragPayload(piece: pieceIndex),
                          feedback: Material(
                            color: Colors.transparent,
                            child: _buildPuzzlePiece(
                              pieceIndex,
                              boardPieceSize,
                              padding: boardPieceSize * 0.18,
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.2,
                            child: _buildPuzzlePiece(
                              pieceIndex,
                              trayPieceSize,
                              padding: trayPieceSize * 0.18,
                            ),
                          ),
                          child: _buildPuzzlePiece(
                            pieceIndex,
                            trayPieceSize,
                            padding: trayPieceSize * 0.18,
                          ),
                        );
                      }).toList()
                    : [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Text(
                              '✨ සියල්ල සිටිනවා! ✨',
                              style: GoogleFonts.fredoka(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4ECDC4),
                              ),
                            ),
                          ),
                        ),
                      ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final horizontalPadding = isWide ? 24.0 : 16.0;
            final baseBoardSize = isWide
                ? (constraints.maxWidth - horizontalPadding * 2) * 0.58
                : constraints.maxWidth - horizontalPadding * 2;
            final boardSize = baseBoardSize * 0.9;
            final trayWidth = isWide
                ? (constraints.maxWidth - horizontalPadding * 2) * 0.34
                : constraints.maxWidth - horizontalPadding * 2;

            final content = isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBoard(boardSize),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildPiecesTray(
                          trayWidth,
                          boardSize / _gridSize,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildBoard(boardSize),
                      const SizedBox(height: 24),
                      _buildPiecesTray(trayWidth, boardSize / _gridSize),
                    ],
                  );

            return SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with instruction
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFFBE9F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.extension,
                            color: Color(0xFFFF6B6B),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'පුපුරන්න කතාව!',
                                style: GoogleFonts.fredoka(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'පිටපතවල ඔබේ සතුටු මුහුණ සම්පූර්ණ කරන්න',
                                style: GoogleFonts.fredoka(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 20),
                  // Top bar with back, title, and moves counter
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          color: const Color(0xFF4ECDC4),
                          iconSize: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '😊 සතුටු මුහුණ ප්‍රහේලිකාව',
                          style: GoogleFonts.fredoka(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2D3436),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFBE9F), Color(0xFFFF6B6B)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          '🎯 $_moves moves',
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Main puzzle content
                  content
                      .animate()
                      .fadeIn(duration: 350.ms, delay: 80.ms)
                      .slideY(begin: 0.15, end: 0),
                  const SizedBox(height: 22),
                  // Bottom action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _initPuzzle();
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 22),
                          label: Text(
                            'නැවත අරඹන්න',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
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
                          icon: const Icon(Icons.music_note, size: 22),
                          label: Text(
                            'සංගීතයට යන්න',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDC4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class JigsawPiecePainter extends CustomPainter {
  final ui.Image image;
  final Rect srcRect;
  final int row;
  final int col;
  final int gridSize;
  final Color borderColor;
  final double borderWidth;
  final double opacity;
  final double padding;
  final bool flatEdges;

  JigsawPiecePainter({
    required this.image,
    required this.srcRect,
    required this.row,
    required this.col,
    required this.gridSize,
    required this.borderColor,
    required this.borderWidth,
    this.opacity = 1.0,
    this.padding = 0,
    this.flatEdges = false,
  });

  int _rightDir(int r, int c) => (r + c) % 2 == 0 ? 1 : -1;
  int _bottomDir(int r, int c) => (r + c) % 2 == 0 ? -1 : 1;

  Path _buildPiecePath(Size size) {
    final w = size.width;
    final h = size.height;
    final tabDepth = w * 0.18;

    final topDir = flatEdges ? 0 : (row == 0 ? 0 : -_bottomDir(row - 1, col));
    final leftDir = flatEdges ? 0 : (col == 0 ? 0 : -_rightDir(row, col - 1));
    final rightDir = flatEdges
        ? 0
        : (col == gridSize - 1 ? 0 : _rightDir(row, col));
    final bottomDir = flatEdges
        ? 0
        : (row == gridSize - 1 ? 0 : _bottomDir(row, col));

    final path = Path();
    path.moveTo(0, 0);

    // Top edge
    if (topDir == 0) {
      path.lineTo(w, 0);
    } else {
      path.lineTo(w * 0.33, 0);
      path.cubicTo(
        w * 0.38,
        topDir * -tabDepth,
        w * 0.62,
        topDir * -tabDepth,
        w * 0.67,
        0,
      );
      path.lineTo(w, 0);
    }

    // Right edge
    if (rightDir == 0) {
      path.lineTo(w, h);
    } else {
      path.lineTo(w, h * 0.33);
      path.cubicTo(
        w + rightDir * tabDepth,
        h * 0.38,
        w + rightDir * tabDepth,
        h * 0.62,
        w,
        h * 0.67,
      );
      path.lineTo(w, h);
    }

    // Bottom edge
    if (bottomDir == 0) {
      path.lineTo(0, h);
    } else {
      path.lineTo(w * 0.67, h);
      path.cubicTo(
        w * 0.62,
        h + bottomDir * tabDepth,
        w * 0.38,
        h + bottomDir * tabDepth,
        w * 0.33,
        h,
      );
      path.lineTo(0, h);
    }

    // Left edge
    if (leftDir == 0) {
      path.close();
    } else {
      path.lineTo(0, h * 0.67);
      path.cubicTo(
        leftDir * -tabDepth,
        h * 0.62,
        leftDir * -tabDepth,
        h * 0.38,
        0,
        h * 0.33,
      );
      path.close();
    }

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final innerSize = Size(size.width - padding * 2, size.height - padding * 2);
    final path = _buildPiecePath(innerSize).shift(Offset(padding, padding));

    if (opacity == 1.0) {
      canvas.drawShadow(path, Colors.black.withOpacity(0.25), 4, false);
    }

    canvas.save();
    canvas.clipPath(path);
    final dstRect = Rect.fromLTWH(
      padding,
      padding,
      innerSize.width,
      innerSize.height,
    );

    final paint = Paint();
    if (opacity < 1.0) {
      paint.color = Colors.white.withOpacity(opacity);
      paint.blendMode = BlendMode.dstIn;
      canvas.saveLayer(dstRect, Paint());
      canvas.drawImageRect(image, srcRect, dstRect, Paint());
      canvas.drawRect(dstRect, paint);
      canvas.restore();
    } else {
      canvas.drawImageRect(image, srcRect, dstRect, paint);
    }
    canvas.restore();

    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = borderColor
        ..strokeWidth = borderWidth;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant JigsawPiecePainter oldDelegate) {
    return oldDelegate.srcRect != srcRect ||
        oldDelegate.row != row ||
        oldDelegate.col != col ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.opacity != opacity ||
        oldDelegate.padding != padding ||
        oldDelegate.flatEdges != flatEdges;
  }
}
