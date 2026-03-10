import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:io' as io;

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
  const DrawingBoardPage({
    super.key,
    required this.childId,
    String? baseUrl,
  }) : baseUrl = baseUrl ??
            (kIsWeb
                ? 'http://localhost:8000'
                : 'http://10.0.2.2:8000');

  final int childId;
  final String baseUrl;

  @override
  State<DrawingBoardPage> createState() => _DrawingBoardPageState();
}

class _DrawingBoardPageState extends State<DrawingBoardPage> {
  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];
  Stroke? _current;

  Color _color = Colors.black;
  double _size = 6;
  BrushType _brush = BrushType.pen;

  final GlobalKey _repaintKey = GlobalKey();
  final TextEditingController _noteController = TextEditingController();

  bool _isSubmitting = false;
  Map<String, dynamic>? _lastResult;

  final ImagePicker _picker = ImagePicker();

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
        return base
          ..color = _color.withValues(alpha: 0.65)
          ..strokeWidth = max(2, _size * 0.75);

      case BrushType.marker:
        return base
          ..color = _color.withValues(alpha: 0.85)
          ..strokeWidth = _size * 1.4;

      case BrushType.eraser:
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

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exported PNG bytes')),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = io.File(
      '${dir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'My drawing!');
  }

  Future<Map<String, dynamic>> _submitBytes({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final uri = Uri.parse('${widget.baseUrl}/drawing/analyze');
    print('Submitting to: $uri');
    print('Filename: $filename');
    print('Content-Type: $contentType');

    final request = http.MultipartRequest('POST', uri);
    request.fields['child_id'] = widget.childId.toString();
    request.fields['note'] = _noteController.text.trim();

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      ),
    );

    http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw Exception(
        kIsWeb
            ? 'Connection timed out. Make sure backend is running on http://localhost:8000 and CORS is enabled.'
            : 'Connection timed out. Check that the backend is running and reachable.',
      );
    }

    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Submit failed: ${response.statusCode} ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> _submitDrawingBoard() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw something first.')),
      );
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      final bytes = await _exportPngBytes();
      final result = await _submitBytes(
        bytes: bytes,
        filename: 'drawing_board.png',
        contentType: 'image/png',
      );

      if (!mounted) return;
      setState(() => _lastResult = result);
      _showResultDialog(result);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _scanOrUploadAndSubmit() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Scan using camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 95,
      );

      if (picked == null) return;

      setState(() => _isSubmitting = true);

      final bytes = await picked.readAsBytes();

      final ext = picked.name.toLowerCase();
      String type = 'image/jpeg';
      if (ext.endsWith('.png')) {
        type = 'image/png';
      } else if (ext.endsWith('.webp')) {
        type = 'image/webp';
      }

      final result = await _submitBytes(
        bytes: bytes,
        filename: picked.name,
        contentType: type,
      );

      if (!mounted) return;
      setState(() => _lastResult = result);
      _showResultDialog(result);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    final emotion = result['emotion'] ?? {};
    final objects = result['objects'] ?? {};
    final detections = (objects['detections'] as List?) ?? [];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Analysis Complete'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analysis ID: ${result['analysis_id']}'),
              const SizedBox(height: 8),
              Text('Emotion: ${emotion['label'] ?? '-'}'),
              Text(
                'Confidence: ${((emotion['confidence'] ?? 0.0) as num).toStringAsFixed(3)}',
              ),
              const SizedBox(height: 8),
              Text('Detected objects: ${objects['count'] ?? 0}'),
              const SizedBox(height: 8),
              if (detections.isNotEmpty) ...[
                const Text('Top detections:'),
                const SizedBox(height: 4),
                ...detections.take(5).map((d) {
                  final label = d['label'] ?? '-';
                  final score = ((d['score'] ?? 0.0) as num).toStringAsFixed(2);
                  return Text('• $label ($score)');
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Column(
                  children: [
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
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
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, i) {
                          final c = _palette[i];
                          final selected =
                              c.value == _color.value &&
                              _brush != BrushType.eraser;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _color = c;
                              if (_brush == BrushType.eraser) {
                                _brush = BrushType.pen;
                              }
                            }),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: selected ? 3 : 1,
                                  color: selected ? Colors.black : Colors.grey.shade400,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitDrawingBoard,
                        icon: const Icon(Icons.send),
                        label: const Text('Submit Drawing'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _scanOrUploadAndSubmit,
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: const Text('Scan / Upload & Submit'),
                      ),
                    ),
                    if (_lastResult != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Last result: ${_lastResult!['emotion']?['label'] ?? '-'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
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

  @override
  bool shouldRepaint(covariant _StrokesPainter oldDelegate) => true;
}