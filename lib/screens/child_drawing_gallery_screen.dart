import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/child_bottom_nav_bar.dart';

class ChildDrawingGalleryScreen extends StatefulWidget {
  const ChildDrawingGalleryScreen({super.key});

  @override
  State<ChildDrawingGalleryScreen> createState() =>
      _ChildDrawingGalleryScreenState();
}

class _ChildDrawingGalleryScreenState extends State<ChildDrawingGalleryScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _drawings = [];
  DateTime? _selectedDate;

  String get _baseUrl =>
      kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';

  @override
  void initState() {
    super.initState();
    _loadDrawings();
  }

  Future<void> _loadDrawings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.getChildDrawingsGallery();

      if (response.statusCode != 200) {
        setState(() {
          _error = 'චිත්‍ර ලබාගැනීම අසාර්ථකයි: ${response.statusCode}';
          _isLoading = false;
        });
        return;
      }

      final decoded = jsonDecode(response.body);

      List items;
      if (decoded is Map && decoded['items'] is List) {
        items = decoded['items'];
      } else if (decoded is List) {
        items = decoded;
      } else {
        items = [];
      }

      setState(() {
        _drawings = items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'දෝෂයක් ඇති විය: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredDrawings {
    if (_selectedDate == null) return _drawings;

    return _drawings.where((item) {
      final raw = item['created_at']?.toString();
      if (raw == null) return false;

      final date = DateTime.tryParse(raw);
      if (date == null) return false;

      return date.year == _selectedDate!.year &&
          date.month == _selectedDate!.month &&
          date.day == _selectedDate!.day;
    }).toList();
  }

  String _imageUrl(Map<String, dynamic> item) {
    final id = item['analysis_id']?.toString() ?? item['id']?.toString() ?? '';
    return '$_baseUrl/drawing/image/$id';
  }

  String _formatDate(dynamic raw) {
    final text = raw?.toString() ?? '';
    if (text.length < 10) return '';
    return text.substring(0, 10);
  }

  String _formatSelectedDate() {
    if (_selectedDate == null) return 'දිනයක් තෝරන්න';
    final d = _selectedDate!;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _emotionSinhala(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'happy':
        return 'සතුටු';
      case 'sad':
        return 'දුකසිත';
      default:
        return 'නොදනී';
    }
  }

  Color _emotionColor(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'happy':
        return const Color(0xFF22C55E);
      case 'sad':
        return const Color(0xFFFF4D6D);
      default:
        return Colors.grey;
    }
  }

  IconData _emotionIcon(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_satisfied_alt_rounded;
      case 'sad':
        return Icons.sentiment_dissatisfied_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF22C55E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
  }

  void _openDrawing(Map<String, dynamic> item) {
    final imageUrl = _imageUrl(item);

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: ChildDrawingViewScreen(
              item: item,
              imageUrl: imageUrl,
              heroTag: imageUrl,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleDrawings = _filteredDrawings;
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
    if (width >= 900) {
      crossAxisCount = 4;
    } else if (width >= 600) {
      crossAxisCount = 3;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const ChildBottomNavBar(currentIndex: 0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'මගේ ගැලරිය',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDrawings,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          const _SoftGalleryBackground(),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: _pickDate,
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: Color(0xFF4B5563),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _formatSelectedDate(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF4B5563),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _clearDate,
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF22C55E),
                        ),
                      )
                    : _error != null
                        ? _ErrorState(
                            message: _error!,
                            onRetry: _loadDrawings,
                          )
                        : visibleDrawings.isEmpty
                            ? _EmptyState(
                                hasFilter: _selectedDate != null,
                                onClear: _clearDate,
                              )
                            : GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 28),
                                itemCount: visibleDrawings.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                  childAspectRatio: width < 380 ? 0.74 : 0.78,
                                ),
                                itemBuilder: (context, index) {
                                  final item = visibleDrawings[index];
                                  final imageUrl = _imageUrl(item);
                                  final emotion =
                                      item['emotion_label']?.toString() ??
                                          item['emotion']?['label']?.toString();

                                  return _GalleryCard(
                                    imageUrl: imageUrl,
                                    heroTag: imageUrl,
                                    date: _formatDate(item['created_at']),
                                    emotion: emotion,
                                    emotionSinhala: _emotionSinhala(emotion),
                                    emotionColor: _emotionColor(emotion),
                                    emotionIcon: _emotionIcon(emotion),
                                    onTap: () => _openDrawing(item),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GalleryCard extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  final String date;
  final String? emotion;
  final String emotionSinhala;
  final Color emotionColor;
  final IconData emotionIcon;
  final VoidCallback onTap;

  const _GalleryCard({
    required this.imageUrl,
    required this.heroTag,
    required this.date,
    required this.emotion,
    required this.emotionSinhala,
    required this.emotionColor,
    required this.emotionIcon,
    required this.onTap,
  });

  @override
  State<_GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<_GalleryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _scale = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapCancel: () => _controller.reverse(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: widget.emotionColor.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.emotionColor.withOpacity(0.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Hero(
                          tag: widget.heroTag,
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;

                              return Container(
                                color: const Color(0xFFF3F4F6),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF3F4F6),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.grey,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: widget.emotionColor.withOpacity(0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.emotionIcon,
                                color: widget.emotionColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.emotionSinhala,
                                style: TextStyle(
                                  color: widget.emotionColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: widget.emotionColor.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class ChildDrawingViewScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final String imageUrl;
  final String heroTag;

  const ChildDrawingViewScreen({
    super.key,
    required this.item,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final emotion =
        item['emotion_label']?.toString() ?? item['emotion']?['label']?.toString();

    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const ChildBottomNavBar(currentIndex: 0),
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: 44,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          if (emotion != null)
            Positioned(
              bottom: 92,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'හඳුනාගත් හැඟීම: $emotion',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SoftGalleryBackground extends StatefulWidget {
  const _SoftGalleryBackground();

  @override
  State<_SoftGalleryBackground> createState() => _SoftGalleryBackgroundState();
}

class _SoftGalleryBackgroundState extends State<_SoftGalleryBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 7))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final v = _controller.value;

          return Stack(
            children: [
              Positioned(
                top: 100 + (v * 20),
                right: -50,
                child: _Circle(
                  size: 160,
                  color: Colors.green.withOpacity(0.16),
                ),
              ),
              Positioned(
                bottom: 90 - (v * 20),
                left: 40,
                child: _Circle(
                  size: 110,
                  color: Colors.pink.withOpacity(0.09),
                ),
              ),
              Positioned(
                bottom: 260 + (v * 16),
                right: 40,
                child: _Circle(
                  size: 80,
                  color: Colors.blue.withOpacity(0.08),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;

  const _Circle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;

  const _EmptyState({
    required this.hasFilter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilter ? Icons.calendar_month_rounded : Icons.photo_library,
              size: 60,
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'මෙම දිනයට චිත්‍ර නොමැත' : 'තවම චිත්‍ර නොමැත',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: onClear,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Filter ඉවත් කරන්න'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('නැවත උත්සාහ කරන්න'),
            ),
          ],
        ),
      ),
    );
  }
}