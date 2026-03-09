import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:io' as io; // ignored on web (guarded by kIsWeb)

enum BrushType { pen, pencil, marker, eraser }

class Stroke {
  Stroke({
    required this.points,
    required this.paint,
  });

  final List<Offset> points;
  final Paint paint;

  Stroke copyWith({List<Offset>? points, Paint? paint}) => Stroke(
        points: points ?? this.points,
        paint: paint ?? this.paint,
      );
}

class DrawingBoardPage extends StatefulWidget {
  const DrawingBoardPage({super.key});

  @override
  State<DrawingBoardPage> createState() => _DrawingBoardPageState();
}

class _DrawingBoardPageState extends State<DrawingBoardPage> {
  // Canvas state
  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];
  Stroke? _current;

  // Tools
  Color _color = Colors.black;
  double _size = 6;
  BrushType _brush = BrushType.pen;

  // repaint key to export image
  final GlobalKey _repaintKey = GlobalKey();

  // Kid-friendly palette
  final List<Color> _palette = const [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.teal,
  ];

  Paint _makePaint() {
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (_brush) {
      case BrushType.pen:
        return base
          ..color = _color
          ..strokeWidth = _size
          ..blendMode = BlendMode.srcOver;

      case BrushType.pencil:
        // “pencil feel”: slightly transparent
        return base
          ..color = _color.withValues(alpha: 0.65)
          ..strokeWidth = max(2, _size * 0.75);

      case BrushType.marker:
        // “marker feel”: more opaque + thicker
        return base
          ..color = _color.withValues(alpha: 0.85)
          ..strokeWidth = _size * 1.4;

      case BrushType.eraser:
        // Erase by painting with background color (white).
        return base
          ..color = Colors.white
          ..strokeWidth = _size * 2.0
          ..blendMode = BlendMode.srcOver;
    }
  }

  void _startStroke(Offset p) {
    setState(() {
      _redoStack.clear();
      _current = Stroke(points: [p], paint: _makePaint());
      _strokes.add(_current!);
    });
  }

  void _addPoint(Offset p) {
    if (_current == null) return;
    setState(() {
      _current!.points.add(p);
    });
  }

  void _endStroke() {
    setState(() {
      _current = null;
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.add(_strokes.removeLast());
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _strokes.add(_redoStack.removeLast());
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _redoStack.clear();
      _current = null;
    });
  }

  Future<Uint8List> _exportPngBytes() async {
    final boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _saveOrShare() async {
    final bytes = await _exportPngBytes();

    // Web: trigger a download using browser APIs (placeholder)
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exported PNG bytes (web download code optional).'),
        ),
      );
      return;
    }

    // Mobile/Desktop: save to temp and share
    final dir = await getTemporaryDirectory();
    final file = io.File(
      '${dir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'My drawing!');
  }

  @override
  Widget build(BuildContext context) {
    final canUndo = _strokes.isNotEmpty;
    final canRedo = _redoStack.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kids Drawing Board'),
        actions: [
          IconButton(
            tooltip: 'Export / Share',
            onPressed: _saveOrShare,
            icon: const Icon(Icons.ios_share),
          ),
          IconButton(
            tooltip: 'Undo',
            onPressed: canUndo ? _undo : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: canRedo ? _redo : null,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: _clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          // TOOLBAR
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Column(
              children: [
                // brush types
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _ToolChip(
                      label: 'Pen',
                      selected: _brush == BrushType.pen,
                      onTap: () => setState(() => _brush = BrushType.pen),
                    ),
                    _ToolChip(
                      label: 'Pencil',
                      selected: _brush == BrushType.pencil,
                      onTap: () => setState(() => _brush = BrushType.pencil),
                    ),
                    _ToolChip(
                      label: 'Marker',
                      selected: _brush == BrushType.marker,
                      onTap: () => setState(() => _brush = BrushType.marker),
                    ),
                    _ToolChip(
                      label: 'Eraser',
                      selected: _brush == BrushType.eraser,
                      onTap: () => setState(() => _brush = BrushType.eraser),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // size slider
                Row(
                  children: [
                    const Icon(Icons.brush),
                    Expanded(
                      child: Slider(
                        value: _size,
                        min: 2,
                        max: 28,
                        divisions: 26,
                        label: _size.toStringAsFixed(0),
                        onChanged: (v) => setState(() => _size = v),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        _size.toStringAsFixed(0),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // colors
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, i) {
                      final c = _palette[i];
                      final selected =
                          c.value == _color.value && _brush != BrushType.eraser;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _color = c;
                          if (_brush == BrushType.eraser) _brush = BrushType.pen;
                        }),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: selected ? 3 : 1,
                              color:
                                  selected ? Colors.black : Colors.grey.shade400,
                            ),
                          ),
                          child: c == Colors.white
                              ? const Center(
                                  child: Icon(Icons.circle_outlined, size: 16),
                                )
                              : null,
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: _palette.length,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // CANVAS
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.all(12),
              child: RepaintBoundary(
                key: _repaintKey,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.white,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (d) => _startStroke(d.localPosition),
                      onPanUpdate: (d) => _addPoint(d.localPosition),
                      onPanEnd: (_) => _endStroke(),
                      child: CustomPaint(
                        painter: _StrokesPainter(_strokes),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StrokesPainter extends CustomPainter {
  _StrokesPainter(this.strokes);

  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, s.points, s.paint);
        continue;
      }

      for (int i = 0; i < s.points.length - 1; i++) {
        final p1 = s.points[i];
        final p2 = s.points[i + 1];
        canvas.drawLine(p1, p2, s.paint);
      }
    }
  }

  // ✅ FIX: Always repaint so drawing appears while dragging (web + mobile)
  @override
  bool shouldRepaint(covariant _StrokesPainter oldDelegate) => true;
}