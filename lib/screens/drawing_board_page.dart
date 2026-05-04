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

import 'bubble_pop_page.dart';
import 'balloon_breath_page.dart';

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

    await Share.shareXFiles([XFile(file.path)], text: 'මගේ චිත්‍රය');
  }

  // ── Core HTTP submission ─────────────────────────────────────────────────
  // sourceOverride = "drawing_board" → backend skips CV pipeline, goes direct to Gemini
  // sourceOverride = ""              → backend runs full CV pipeline (scan/upload path)

  Future<Map<String, dynamic>> _submitBytes({
    required Uint8List bytes,
    required String filename,
    required String contentType,
    String sourceOverride = '',
  }) async {
    final uri = Uri.parse('${widget.baseUrl}/drawing/analyze');

    final request = http.MultipartRequest('POST', uri);
    request.fields['child_id'] = widget.childId;
    request.fields['note'] = _noteController.text.trim();

    // Tell backend to skip CV pipeline for drawing board submissions
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
      // Drawing board goes to Gemini directly so allow a bit more time
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

  // ── Submit from drawing canvas → skip CV, go direct to Gemini ───────────

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
        sourceOverride: 'drawing_board', // ← skips CV, direct to Gemini
      );

      if (!mounted) return;
      setState(() => _lastResult = result);
      _showChildSupportDialog(result);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Submit from camera / gallery → full CV pipeline ─────────────────────

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

      // No sourceOverride → backend runs full CV pipeline
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Result dialog shown to child ─────────────────────────────────────────

  void _showChildSupportDialog(Map<String, dynamic> result) {
    final emotionRaw =
        result['emotion']?['label']?.toString().toLowerCase() ?? '';
    final isSad = emotionRaw == 'sad';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          isSad ? 'අද ඔයාගේ හැඟීම්' : 'අද ඔයාගේ සතුට',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child:
              isSad ? _sadChildSupportContent() : _happyChildSupportContent(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('හරි'),
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
      'අද ඔයා සතුටින් ඉන්නවා වගේ. ඒක හරි ලස්සන දෙයක්.',
      'ඔයාට මේ සතුටු වෙලා ඉන්න හැඟීම ගැන ටිකක් කියන්න පුළුවන්ද?',
      'සතුටු වෙලා ඉන්න එක හොඳයි. ඒත් වෙන හැඟීම් තිබුණත් ඒවාත් හරි.',
      'ඔයාට සතුටක් දෙන දේවල් මොනවද කියලා අපි හොයමු.',
      'අද වගේ දවස් තව වැඩි කරගන්න අපිට පුළුවන්.',
      'ඔයාට හොඳට දැනෙන දේවල් කරගෙන යන්න හරිද?',
      'කවදාවත් නැවත දුකක් එනවා නම්, ඒකත් කියන්න පුළුවන්.',
      'ඔයාට දැනෙන හැඟීම් හැම එකක්ම වැදගත්.',
      'අපි ටික ටික හොඳට ඉන්න පුරුදු හදමු, නිදාගන්න, කන්න, සෙල්ලම් කරන්න වගේ.',
      'ඔයාට කතා කරන්න කැමති කෙනෙක් තියෙනවද? එයාලත් එක්ක share කරන්න හොඳයි.',
      'ඔයාට අද හොඳට දැනෙන එක ගැන අපි සතුටු වෙමු.',
      'අපි එකට මේ සතුට තියාගෙන යන්න උත්සාහ කරමු.',
      'ඔයා ශක්තිමත් ළමයෙක්. මේ හැඟීම් හොඳින් handle කරනවා.',
      'ඔයාට ඕන වෙලාවක කියන්න පුළුවන්. මම ඉන්නවා.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: messages
          .map(
            (msg) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('- $msg'),
            ),
          )
          .toList(),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Column(
                  children: [
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'සටහනක් ලියන්න (අත්‍යවශ්‍ය නැත)',
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
                              width: 36,
                              height: 36,
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
                                      child: Icon(Icons.circle_outlined,
                                          size: 16),
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
                        label: const Text('චිත්‍රය යවන්න'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4EAA57),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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