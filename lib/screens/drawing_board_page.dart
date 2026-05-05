import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' as io;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/child_bottom_nav_bar.dart';
import 'balloon_breath_page.dart';
import 'bubble_pop_page.dart';
import 'main_home_screen.dart';

enum BrushType { pen, pencil, marker, eraser }

class Stroke {
  Stroke({
    required this.points,
    required this.paint,
  });

  final List<Offset> points;
  final Paint paint;
}

class DrawingBoardPage extends StatefulWidget {
  const DrawingBoardPage({
    super.key,
    required this.childId,
    String? baseUrl,
  }) : baseUrl = baseUrl ??
            (kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000');

  final String childId;
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
      _lastResult = null;
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
        const SnackBar(content: Text('PNG ලෙස සූදානම් කර ඇත')),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = io.File(
      '${dir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'මගේ චිත්‍රය',
    );
  }

  Future<Map<String, dynamic>> _submitBytes({
    required Uint8List bytes,
    required String filename,
    required String contentType,
    String sourceOverride = '',
  }) async {
    final uri = Uri.parse('${widget.baseUrl}/drawing/analyze');

    final request = http.MultipartRequest('POST', uri);
    request.fields['child_id'] = widget.childId;
    request.fields['note'] = 'child_drawing_submission';

    if (sourceOverride.isNotEmpty) {
      request.fields['source_override'] = sourceOverride;
    }

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
      final timeout = sourceOverride == 'drawing_board'
          ? const Duration(seconds: 120)
          : const Duration(seconds: 90);

      streamed = await request.send().timeout(timeout);
    } on TimeoutException {
      throw Exception(
        kIsWeb
            ? 'සම්බන්ධතාවය කාලය ඉක්මවා ගියේය. Backend http://localhost:8000 මත ක්‍රියාත්මකද බලන්න.'
            : 'සම්බන්ධතාවය කාලය ඉක්මවා ගියේය. Backend සේවාව ක්‍රියාත්මකද බලන්න.',
      );
    }

    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('යැවීම අසාර්ථකයි: ${response.statusCode} ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> _submitDrawingBoard() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('කරුණාකර මුලින්ම චිත්‍රයක් අඳින්න.')),
      );
      return;
    }

    if (widget.childId.isEmpty) {
      _showError('දරුවාගේ හැඳුනුම් අංකය නොමැත. නැවත Login වන්න.');
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      final bytes = await _exportPngBytes();

      final result = await _submitBytes(
        bytes: bytes,
        filename: 'drawing_board.png',
        contentType: 'image/png',
        sourceOverride: 'drawing_board',
      );

      if (!mounted) return;

      setState(() => _lastResult = result);
      _showChildSupportDialog(result);
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
    if (widget.childId.isEmpty) {
      _showError('දරුවාගේ හැඳුනුම් අංකය නොමැත. නැවත Login වන්න.');
      return;
    }

    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('කැමරාවෙන් Scan කරන්න'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery එකෙන් තෝරන්න'),
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

      if (ext.endsWith('.png')) type = 'image/png';
      if (ext.endsWith('.webp')) type = 'image/webp';

      final result = await _submitBytes(
        bytes: bytes,
        filename: picked.name,
        contentType: type,
      );

      if (!mounted) return;

      setState(() => _lastResult = result);
      _showChildSupportDialog(result);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showChildSupportDialog(Map<String, dynamic> result) {
    final emotionRaw =
        result['emotion']?['label']?.toString().toLowerCase() ?? '';
    final isSad = emotionRaw == 'sad';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(
          isSad ? 'අද ඔයාගේ හැඟීම්' : 'අද ඔයා සතුටින් වගේ',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: isSad ? _sadChildSupportContent() : _happyChildSupportContent(),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                if (!isSad) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainHomeScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EAA57),
                foregroundColor: Colors.white,
              ),
              child: const Text('හරි'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sadChildSupportContent() {
    final tips = [
      'විශ්වාසය තියෙන කෙනෙකුට, අම්මා, තාත්තා, ගුරුතුමිය, ගුරුතුමා හෝ යාලුවෙක්ට ඔබේ හැඟීම් කියන්න.',
      'දුක්වෙන්න එක සාමාන්‍ය දෙයක් කියලා මතක තියාගන්න.',
      'හුස්ම ගැඹුරු ලෙස ගන්න සහ ශරීරය සැහැල්ලු කරන්න.',
      'ඔබ කැමති දෙයක් කරන්න, චිත්‍ර ඇඳීම, ක්‍රීඩා, සංගීතය ඇසීම හෝ පොත් කියවීම වගේ.',
      'ටිකක් පිටතට ගිහින් තෙත් වායුව ගන්න.',
      'ඔබේ හැඟීම් ලියන්න හෝ ඇඳන්න.',
      'කැමති ගීත අහන්න හෝ සතුටු කරන දෙයක් බලන්න.',
      'යාලුවන් හෝ පවුලේ අය සමඟ කාලය ගත කරන්න.',
      'හොඳට නිදාගන්න සහ සුවදායී ආහාර ගන්න.',
      'අන් අය සමඟ ඔබව සසඳන්න එපා.',
      'අද දවසේ හොඳ දෙයක් එකක් හරි මතක් කරන්න.',
      'ලොකු ප්‍රශ්න කුඩා පියවර වලට බෙදා ගන්න.',
      'පාඩම් වලට ආතතියක් තියෙනවා නම් උදව් ඉල්ලන්න.',
      'ඔබට ඔබම කරුණාවෙන් හැසිරෙන්න, ඔබට ඔබම දොස් නොදෙන්න.',
      'දිගටම දුක්වෙලා ඉන්නවා නම් ගුරුතුමිය, ගුරුතුමා හෝ උපදේශකවරයෙකු සමඟ කතා කරන්න.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'අද ඔයාගේ හැඟීම් ටිකක් දුකින් වගේ. ඒක හරි. අපි ටිකක් සන්සුන් වෙමු.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BubblePopPage()),
              );
            },
            child: const Text('Bubble Pop ක්‍රීඩාවට යන්න'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BalloonBreathPage()),
              );
            },
            child: const Text('හුස්ම ගැනීමේ ක්‍රියාකාරකමට යන්න'),
          ),
        ),
        const SizedBox(height: 16),
        ...tips.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('- $tip'),
          ),
        ),
      ],
    );
  }

  Widget _happyChildSupportContent() {
    final messages = [
      'අද ඔයා සතුටින් වගේ 😊',
      'ඒක හරි ලස්සන දෙයක්.',
      'ඔයාට සතුටක් දෙන දේවල් කරගෙන යන්න.',
      'ඔයාගේ හැඟීම් හොඳින් ප්‍රකාශ කළා.',
      'ඔයා ශක්තිමත් ළමයෙක් ❤️',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 130,
          child: Lottie.asset(
            'assets/lottie/man.json',
            fit: BoxFit.contain,
            repeat: true,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'අද ඔයා සතුටින් වගේ 😊',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 14),
        ...messages.map(
          (msg) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '- $msg',
                style: const TextStyle(fontSize: 14.5, height: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canUndo = _strokes.isNotEmpty;
    final canRedo = _redoStack.isNotEmpty;

    return Scaffold(
      bottomNavigationBar: const ChildBottomNavBar(currentIndex: 0),
      appBar: AppBar(
        title: const Text('සිතුවම් පුවරුව'),
        backgroundColor: const Color(0xFF4EAA57),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'බෙදාගන්න',
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
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Column(
                  children: [
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
                          onTap: () =>
                              setState(() => _brush = BrushType.pencil),
                        ),
                        _ToolChip(
                          label: 'Marker',
                          selected: _brush == BrushType.marker,
                          onTap: () =>
                              setState(() => _brush = BrushType.marker),
                        ),
                        _ToolChip(
                          label: 'Eraser',
                          selected: _brush == BrushType.eraser,
                          onTap: () =>
                              setState(() => _brush = BrushType.eraser),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, i) {
                          final c = _palette[i];
                          final selected = c.value == _color.value &&
                              _brush != BrushType.eraser;

                          return GestureDetector(
                            onTap: () => setState(() {
                              _color = c;
                              if (_brush == BrushType.eraser) {
                                _brush = BrushType.pen;
                              }
                            }),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: selected ? 3 : 1,
                                  color: selected
                                      ? Colors.black
                                      : Colors.grey.shade400,
                                ),
                              ),
                              child: c == Colors.white
                                  ? const Center(
                                      child: Icon(
                                        Icons.circle_outlined,
                                        size: 16,
                                      ),
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
              Expanded(
                child: Container(
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.all(10),
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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitDrawingBoard,
                        icon: const Icon(Icons.send),
                        label: const Text('චිත්‍රය යවන්න'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4EAA57),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isSubmitting ? null : _scanOrUploadAndSubmit,
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: const Text('Scan / Upload කර යවන්න'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4EAA57),
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
        canvas.drawLine(s.points[i], s.points[i + 1], s.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter oldDelegate) => true;
}