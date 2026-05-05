import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'music_recommendation_screen.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int _gridSize = 4; // 4x4 puzzle
  late List<int> _trayPieces;
  late List<int?> _placements;
  int _moves = 0;
  bool _isSolved = false;
  bool _isSubmittingScore = false;
  bool _isLeaderboardLoading = false;
  String? _leaderboardError;
  List<LeaderboardEntry> _topEntries = [];
  String? _currentPlayerName;
  int? _currentRank;
  bool _showRankUp = false;
  int? _rankUpTo;
  late AnimationController _celebrationController;
  late AnimationController _particleController;
  ui.Image? _decodedImage;
  bool _imageLoaded = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;

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
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    _loadImage();
    _loadLeaderboardTop();
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
    _uiTimer?.cancel();
    _celebrationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _initPuzzle({int? gridSize}) {
    if (gridSize != null) {
      _gridSize = gridSize;
    }
    _trayPieces = List.generate(_gridSize * _gridSize, (index) => index);
    _trayPieces.shuffle();
    _placements = List.filled(_gridSize * _gridSize, null);
    _moves = 0;
    _isSolved = false;
    _stopwatch
      ..reset()
      ..start();
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
    _stopwatch.stop();
    _celebrationController.forward();
    _particleController.forward();
    _showCompletionDialog();
  }

  int _calculateScore() {
    final base = _gridSize * _gridSize * 100;
    final timePenalty = _stopwatch.elapsed.inSeconds * 2;
    final movePenalty = _moves * 10;
    final score = base - timePenalty - movePenalty;
    return score < 0 ? 0 : score;
  }

  Future<void> _loadLeaderboardTop() async {
    setState(() {
      _isLeaderboardLoading = true;
      _leaderboardError = null;
    });

    try {
      final results = await LeaderboardService.getTop(limit: 10);
      if (!mounted) return;
      setState(() {
        _topEntries = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _leaderboardError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLeaderboardLoading = false;
      });
    }
  }

  Future<void> _refreshRank(String playerName) async {
    try {
      final results = await LeaderboardService.getLeaderboard(
        skip: 0,
        limit: 200,
      );

      if (results.isEmpty) return;

      results.sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        final timeCompare = a.time.compareTo(b.time);
        if (timeCompare != 0) return timeCompare;
        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return aTime.compareTo(bTime);
      });

      final lowerName = playerName.toLowerCase();
      final indices = <int>[];
      for (var i = 0; i < results.length; i++) {
        if (results[i].playerName.toLowerCase() == lowerName) {
          indices.add(i);
        }
      }
      if (indices.isEmpty) return;

      final newRank = indices.first + 1;
      final previousRank = _currentRank;

      setState(() {
        _currentRank = newRank;
      });

      if (previousRank != null && newRank < previousRank) {
        _showRankUpBanner(newRank);
      }
    } catch (_) {}
  }

  void _showRankUpBanner(int newRank) {
    setState(() {
      _rankUpTo = newRank;
      _showRankUp = true;
    });

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _showRankUp = false;
      });
    });
  }

  Future<void> _submitScore() async {
    if (_isSubmittingScore) return;

    final prefs = await SharedPreferences.getInstance();
    final playerName = (prefs.getString('flutter.child_name') ?? '').trim();
    final resolvedName = playerName.isEmpty ? 'Guest' : playerName;

    setState(() {
      _isSubmittingScore = true;
      _currentPlayerName = resolvedName;
    });

    try {
      await LeaderboardService.createEntry(
        playerName: resolvedName,
        score: _calculateScore(),
        level: _gridSize,
        time: _stopwatch.elapsed.inSeconds.toDouble(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Score submitted.')));
      await _loadLeaderboardTop();
      await _refreshRank(resolvedName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingScore = false;
        });
      }
    }
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
                          color: const Color(0xFF2BB7A8),
                          width: 6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2BB7A8).withOpacity(0.4),
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
                      onPressed: _isSubmittingScore ? null : _submitScore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        _isSubmittingScore ? 'Submitting...' : 'Submit Score',
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
                        backgroundColor: const Color(0xFF2BB7A8),
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
        borderColor: isHint ? Colors.transparent : const Color(0xFF2BB7A8),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2BB7A8), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2BB7A8).withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
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
                          flatEdges: false,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildPuzzlePiece(
                          placedPiece,
                          pieceSize,
                          padding: tabPadding,
                          borderWidthOverride: isCorrect ? 0 : null,
                          flatEdges: false,
                        ),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          boxShadow: isCorrect
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2BB7A8,
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
                          flatEdges: false,
                        ),
                      ),
                    );
                  }
                  return Container(
                    decoration: candidateData.isNotEmpty
                        ? BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF2BB7A8).withOpacity(0.7),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2BB7A8).withOpacity(0.3),
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
                      flatEdges: false,
                    ),
                  );
                },
              ),
            );
          }),
        ),
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
                  ? [const Color(0xFFE5FBF9), const Color(0xFFD7F3F0)]
                  : [const Color(0xFFF7FFFE), const Color(0xFFEFFAF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF2BB7A8), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2BB7A8).withOpacity(0.2),
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
                    color: Color(0xFF2BB7A8),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'remaining pieces',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: const Color(0xFF1E3B3A),
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
                              flatEdges: false,
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.2,
                            child: _buildPuzzlePiece(
                              pieceIndex,
                              trayPieceSize,
                              padding: trayPieceSize * 0.18,
                              flatEdges: false,
                            ),
                          ),
                          child: _buildPuzzlePiece(
                            pieceIndex,
                            trayPieceSize,
                            padding: trayPieceSize * 0.18,
                            flatEdges: false,
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
                                color: const Color(0xFF2BB7A8),
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

  Widget _buildDifficultySelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF8),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          _buildDifficultyChip('Easy (4x4)', 4),
          const SizedBox(width: 8),
          _buildDifficultyChip('Normal (5x5)', 5),
          const SizedBox(width: 8),
          _buildDifficultyChip('Hard (6x6)', 6),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String label, int size) {
    final isActive = _gridSize == size;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _initPuzzle(gridSize: size);
          });
          _celebrationController.reset();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2BB7A8) : const Color(0xFFF2FBFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF2BB7A8)
                  : const Color(0xFFCFEAE6),
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : const Color(0xFF3E5B59),
            ),
          ),
        ),
      ),
    );
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _showPreviewDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF2FBFA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Preview'),
          content: SizedBox(
            width: 260,
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.happyFaceImage != null
                  ? Image.memory(widget.happyFaceImage!, fit: BoxFit.cover)
                  : (_decodedImage != null
                        ? FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _decodedImage!.width.toDouble(),
                              height: _decodedImage!.height.toDouble(),
                              child: RawImage(image: _decodedImage),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFE8F6F4),
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 56,
                                color: Color(0xFF2BB7A8),
                              ),
                            ),
                          )),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewThumb({bool isActive = false}) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? const Color(0xFF2BB7A8) : const Color(0xFFCFEAE6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox.expand(
          child: widget.happyFaceImage != null
              ? Image.memory(widget.happyFaceImage!, fit: BoxFit.cover)
              : (_decodedImage != null
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _decodedImage!.width.toDouble(),
                          height: _decodedImage!.height.toDouble(),
                          child: RawImage(image: _decodedImage),
                        ),
                      )
                    : const Icon(Icons.image, color: Color(0xFF2BB7A8))),
        ),
      ),
    );
  }

  Widget _buildPuzzleChooserCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBFA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.extension, color: Color(0xFF2BB7A8)),
              const SizedBox(width: 8),
              Text(
                'Choose Puzzle',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3B3A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPreviewThumb(isActive: true),
              _buildPreviewThumb(),
              _buildPreviewThumb(),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Jigsaw Puzzle',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B6A68),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDifficultySelector(),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard() {
    final hasData = _topEntries.isNotEmpty;
    final currentRank = _currentRank;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBFA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFF2BB7A8)),
              const SizedBox(width: 8),
              Text(
                'Leaderboard',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3B3A),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _isLeaderboardLoading ? null : _loadLeaderboardTop,
                icon: const Icon(Icons.refresh, size: 18),
                color: const Color(0xFF4B6A68),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLeaderboardLoading)
            const LinearProgressIndicator(minHeight: 4),
          if (_leaderboardError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _leaderboardError!,
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
            ),
          if (!_isLeaderboardLoading && _leaderboardError == null)
            Column(
              children: [
                if (currentRank != null && _currentPlayerName != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F6F4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCFEAE6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Color(0xFF2BB7A8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$_currentPlayerName rank: #$currentRank',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3B3A),
                            ),
                          ),
                        ),
                        Text(
                          _formatElapsed(_stopwatch.elapsed),
                          style: GoogleFonts.fredoka(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2BB7A8),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!hasData)
                  Text(
                    'No scores yet.',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4B6A68),
                    ),
                  )
                else
                  Column(
                    children: _topEntries.take(5).toList().asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F6F4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCFEAE6)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF2BB7A8),
                              foregroundColor: Colors.white,
                              radius: 14,
                              child: Text(
                                '#${index + 1}',
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.playerName,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E3B3A),
                                    ),
                                  ),
                                  Text(
                                    'Score ${item.score}  |  Level ${item.level}',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4B6A68),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              item.time.toStringAsFixed(0),
                              style: GoogleFonts.fredoka(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2BB7A8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.extension, color: Color(0xFF2BB7A8), size: 30),
            const SizedBox(width: 8),
            Text(
              'Jigsaw Puzzle',
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E3B3A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Click pieces to solve the puzzle as fast as you can!',
          style: GoogleFonts.fredoka(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4B6A68),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildControlBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Color(0xFF1E3B3A), size: 18),
              const SizedBox(width: 6),
              Text(
                _formatElapsed(_stopwatch.elapsed),
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3B3A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _initPuzzle();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2BB7A8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Shuffle'),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: _showPreviewDialog,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E3B3A),
            side: const BorderSide(color: Color(0xFFCFEAE6)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Preview'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rankUpWidget = AnimatedSlide(
      offset: _showRankUp ? const Offset(0, 0) : const Offset(0, -0.4),
      duration: const Duration(milliseconds: 250),
      child: AnimatedOpacity(
        opacity: _showRankUp ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2BB7A8),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_upward, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Rank Up! #${_rankUpTo ?? '-'}',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5FFFE),
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                final horizontalPadding = isWide ? 28.0 : 16.0;
                final maxBoard = isWide ? 520.0 : constraints.maxWidth - 32;
                final boardSize = maxBoard.clamp(320.0, 520.0);
                final trayWidth = isWide ? 320.0 : constraints.maxWidth - 32;

                final boardPanel = Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildBoard(boardSize),
                );

                final rightPanel = Column(
                  children: [
                    _buildTopHeader(),
                    const SizedBox(height: 16),
                    _buildControlBar(),
                    const SizedBox(height: 16),
                    boardPanel,
                    const SizedBox(height: 16),
                    _buildPiecesTray(trayWidth, boardSize / _gridSize),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Moves: $_moves',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3A2B1B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
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
                          icon: const Icon(Icons.music_note, size: 18),
                          label: const Text('Music'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3A2B1B),
                            side: const BorderSide(color: Color(0xFFCFEAE6)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 320,
                              child: Column(
                                children: [
                                  _buildPuzzleChooserCard(),
                                  const SizedBox(height: 20),
                                  _buildLeaderboardCard(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(child: rightPanel),
                          ],
                        )
                      : Column(
                          children: [
                            _buildTopHeader(),
                            const SizedBox(height: 16),
                            _buildPuzzleChooserCard(),
                            const SizedBox(height: 16),
                            _buildControlBar(),
                            const SizedBox(height: 16),
                            boardPanel,
                            const SizedBox(height: 16),
                            _buildPiecesTray(trayWidth, boardSize / _gridSize),
                            const SizedBox(height: 16),
                            _buildLeaderboardCard(),
                          ],
                        ),
                );
              },
            ),
            Align(alignment: Alignment.topCenter, child: rankUpWidget),
          ],
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
