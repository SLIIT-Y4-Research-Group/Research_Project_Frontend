import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'child_report_screen.dart';

// ─────────────────────────────────────────────────────────────
// Parent Drawing List Screen
// ─────────────────────────────────────────────────────────────

class ParentDrawingsScreen extends StatefulWidget {
  final String childId;
  final String? childName;

  const ParentDrawingsScreen({
    super.key,
    required this.childId,
    this.childName,
  });

  @override
  State<ParentDrawingsScreen> createState() => _ParentDrawingsScreenState();
}

class _ParentDrawingsScreenState extends State<ParentDrawingsScreen> {
  List<Map<String, dynamic>> drawings = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDrawings();
  }

  Future<void> fetchDrawings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final res = await ApiClient.getParentDrawingReports();

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List items = data is Map ? (data['items'] ?? []) : data;

        final filtered = items
            .where((d) => d['child_id']?.toString() == widget.childId)
            .map((d) => Map<String, dynamic>.from(d))
            .toList();

        setState(() => drawings = filtered);
      } else {
        setState(() {
          errorMessage = 'වාර්තා ලබාගැනීම අසාර්ථකයි: ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() => errorMessage = 'දෝෂයක් ඇති විය: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _goToChildReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildReportScreen(
          childId: widget.childId,
          childName: widget.childName,
        ),
      ),
    );
  }

  Color _emotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'sad':
        return const Color(0xFFDC2626);
      case 'happy':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _emotionSinhala(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'sad':
        return 'දුකසිත';
      case 'happy':
        return 'සතුටු';
      default:
        return 'නොදනී';
    }
  }

  String _formatDate(dynamic value) {
    try {
      final dt = DateTime.parse(value?.toString() ?? '');
      return '${dt.year} / ${dt.month.toString().padLeft(2, '0')} / ${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      final text = value?.toString() ?? '';
      return text.length >= 10 ? text.substring(0, 10) : text;
    }
  }

  String _sourceModeSinhala(String? mode) {
    switch (mode) {
      case 'drawing_board':
        return 'ඩිජිටල් ඇඳීම';
      case 'photo_scan':
        return 'ඡායාරූප / Scan';
      default:
        return 'නොදනී';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.childName == null || widget.childName!.isEmpty)
        ? 'දරුවාගේ චිත්‍ර වාර්තා'
        : '${widget.childName}ගේ චිත්‍ර වාර්තා';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _goToChildReport,
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'සම්පූර්ණ වාර්තාව බලන්න',
          ),
          IconButton(
            onPressed: fetchDrawings,
            icon: const Icon(Icons.refresh),
            tooltip: 'නැවුම් කරන්න',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF43A047)),
            )
          : errorMessage != null
              ? _ErrorView(message: errorMessage!)
              : drawings.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: fetchDrawings,
                      color: const Color(0xFF43A047),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: drawings.length,
                        itemBuilder: (context, index) {
                          final d = drawings[index];
                          final analysisId =
                              d['analysis_id']?.toString() ?? '';
                          final imageUrl =
                              ApiClient.getDrawingImageUrl(analysisId);
                          final emotion =
                              d['emotion']?['label']?.toString() ?? 'unknown';
                          final confidence =
                              d['emotion']?['confidence']?.toString() ?? '';
                          final conditionSi =
                              d['emotional_condition_si']?.toString() ??
                                  d['description_si']?.toString() ??
                                  d['emotional_condition']?.toString() ??
                                  '';

                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ParentDrawingDetailScreen(drawing: d),
                              ),
                            ),
                            child: _DrawingCard(
                              imageUrl: imageUrl,
                              emotion: emotion,
                              emotionSinhala: _emotionSinhala(emotion),
                              emotionColor: _emotionColor(emotion),
                              confidence: confidence,
                              date: _formatDate(d['created_at']),
                              sourceMode: _sourceModeSinhala(
                                d['source_mode']?.toString(),
                              ),
                              conditionPreview: conditionSi,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Card Widget
// ─────────────────────────────────────────────────────────────

class _DrawingCard extends StatelessWidget {
  final String imageUrl;
  final String emotion;
  final String emotionSinhala;
  final Color emotionColor;
  final String confidence;
  final String date;
  final String sourceMode;
  final String conditionPreview;

  const _DrawingCard({
    required this.imageUrl,
    required this.emotion,
    required this.emotionSinhala,
    required this.emotionColor,
    required this.confidence,
    required this.date,
    required this.sourceMode,
    required this.conditionPreview,
  });

  String _confidenceSinhala(String c) {
    switch (c.toLowerCase()) {
      case 'high':
        return 'ඉහළ';
      case 'medium':
        return 'මධ්‍යම';
      case 'low':
        return 'අඩු';
      default:
        return c;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade100,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _EmotionBadge(
                      label: emotionSinhala,
                      color: emotionColor,
                      icon: emotion.toLowerCase() == 'happy'
                          ? Icons.sentiment_satisfied_alt
                          : Icons.sentiment_dissatisfied,
                    ),
                    const SizedBox(width: 8),
                    if (confidence.isNotEmpty)
                      _SmallChip(
                        label: 'විශ්වාසය: ${_confidenceSinhala(confidence)}',
                        color: Colors.grey.shade600,
                      ),
                    const Spacer(),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.draw_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sourceMode,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (conditionPreview.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    conditionPreview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      height: 1.45,
                      fontSize: 13.5,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'සම්පූර්ණ වාර්තාව බලන්න',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Detail Screen
// ─────────────────────────────────────────────────────────────

class ParentDrawingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> drawing;

  const ParentDrawingDetailScreen({super.key, required this.drawing});

  String _formatDate(dynamic value) {
    try {
      final dt = DateTime.parse(value?.toString() ?? '');
      return '${dt.year} / ${dt.month.toString().padLeft(2, '0')} / ${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      final text = value?.toString() ?? '';
      return text.length >= 10 ? text.substring(0, 10) : text;
    }
  }

  String _emotionSinhala(String e) {
    switch (e.toLowerCase()) {
      case 'happy':
        return 'සතුටු 😊';
      case 'sad':
        return 'දුකසිත 😔';
      default:
        return e;
    }
  }

  String _confidenceSinhala(String c) {
    switch (c.toLowerCase()) {
      case 'high':
        return 'ඉහළ';
      case 'medium':
        return 'මධ්‍යම';
      case 'low':
        return 'අඩු';
      default:
        return c;
    }
  }

  String _sourceModeSinhala(String? mode) {
    switch (mode) {
      case 'drawing_board':
        return 'ඩිජිටල් ඇඳීම (Drawing Board)';
      case 'photo_scan':
        return 'ඡායාරූප / Scan';
      default:
        return mode ?? 'නොදනී';
    }
  }

  Color _emotionColor(String e) {
    switch (e.toLowerCase()) {
      case 'sad':
        return const Color(0xFFDC2626);
      case 'happy':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisId = drawing['analysis_id']?.toString() ?? '';
    final imageUrl = ApiClient.getDrawingImageUrl(analysisId);

    final childName = drawing['child_name']?.toString() ?? 'දරුවා';
    final date = _formatDate(drawing['created_at']);
    final note = drawing['note']?.toString() ?? '';

    final emotion = drawing['emotion']?['label']?.toString() ?? 'unknown';
    final confidence = drawing['emotion']?['confidence']?.toString() ?? '';
    final sourceMode = _sourceModeSinhala(drawing['source_mode']?.toString());

    final descriptionSi = drawing['description_si']?.toString() ?? '';
    final descriptionEn = drawing['description']?.toString() ?? '';

    final objects = drawing['objects'] is List ? drawing['objects'] as List : [];

    final guidance =
        drawing['parent_guidance'] is Map ? drawing['parent_guidance'] as Map : {};
    final keyObservations = guidance['key_observations'] is List
        ? guidance['key_observations'] as List
        : [];
    final suggestedQuestions = guidance['suggested_questions'] is List
        ? guidance['suggested_questions'] as List
        : [];
    final followUpNeeded = guidance['follow_up_needed'] == true;
    final followUpReason = guidance['follow_up_reason']?.toString() ?? '';

    final devNotes = drawing['developmental_notes'] is Map
        ? drawing['developmental_notes'] as Map
        : {};
    final devObservations = devNotes['observations']?.toString() ?? '';

    final emotionColor = _emotionColor(emotion);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: const Text('චිත්‍ර වාර්තාව'),
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: emotionColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: emotionColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  emotion.toLowerCase() == 'happy'
                      ? Icons.sentiment_satisfied_alt
                      : Icons.sentiment_dissatisfied,
                  color: emotionColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'දරුවාගේ හැඟීම: ${_emotionSinhala(emotion)}',
                        style: TextStyle(
                          color: emotionColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (confidence.isNotEmpty)
                        Text(
                          'විශ්වාස මට්ටම: ${_confidenceSinhala(confidence)}',
                          style: TextStyle(
                            color: emotionColor.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.info_outline,
            title: 'මූලික තොරතුරු',
            child: Column(
              children: [
                _InfoRow(label: 'දරුවා', value: childName),
                _InfoRow(label: 'දිනය', value: date),
                _InfoRow(label: 'ඉදිරිපත් කළ ආකාරය', value: sourceMode),
                if (note.isNotEmpty)
                  _InfoRow(label: 'දරුවාගේ සටහන', value: note),
              ],
            ),
          ),
          if (descriptionSi.isNotEmpty || descriptionEn.isNotEmpty)
            _SectionCard(
              icon: Icons.article_outlined,
              title: 'සම්පූර්ණ චිත්‍ර වාර්තාව',
              child: Text(
                descriptionSi.isNotEmpty ? descriptionSi : descriptionEn,
                style: const TextStyle(height: 1.7, fontSize: 14.5),
              ),
            ),
          if (objects.isNotEmpty)
            _SectionCard(
              icon: Icons.search,
              title: 'චිත්‍රයේ ඇති දේවල්',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: objects.map((obj) {
                  if (obj is! Map) return const SizedBox.shrink();

                  final label = obj['label']?.toString() ?? '';
                  final evidence = obj['evidence']?.toString() ?? '';
                  final symbolism = obj['symbolism']?.toString() ?? '';
                  final weight = obj['emotional_weight']?.toString() ?? '';

                  Color weightColor = Colors.grey.shade600;
                  String weightSi = '';

                  if (weight == 'positive') {
                    weightColor = const Color(0xFF16A34A);
                    weightSi = 'හොඳ ලකුණු';
                  } else if (weight == 'concerning') {
                    weightColor = const Color(0xFFDC2626);
                    weightSi = 'අවධානය අවශ්‍ය';
                  } else if (weight == 'neutral') {
                    weightSi = 'සාමාන්‍ය';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (weightSi.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: weightColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  weightSi,
                                  style: TextStyle(
                                    color: weightColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (evidence.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            '📍 $evidence',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (symbolism.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            '💭 $symbolism',
                            style: const TextStyle(fontSize: 13.5, height: 1.45),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          _ColorAnalysisCard(drawing: drawing),
          _SpatialAnalysisCard(drawing: drawing),
          _StrokeAnalysisCard(drawing: drawing),
          if (devObservations.isNotEmpty)
            _SectionCard(
              icon: Icons.child_care,
              title: 'වයසට ගැළපෙනවාද?',
              child: Text(
                devObservations,
                style: const TextStyle(height: 1.6, fontSize: 14.5),
              ),
            ),
          if (keyObservations.isNotEmpty ||
              suggestedQuestions.isNotEmpty ||
              followUpNeeded)
            _SectionCard(
              icon: Icons.favorite_outline,
              title: 'දෙමාපියන් සදහා මඟ පෙන්වීම',
              accentColor: const Color(0xFF7C3AED),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (keyObservations.isNotEmpty) ...[
                    const Text(
                      'ප්‍රධාන නිරීක්ෂණ:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...keyObservations.map(
                      (obs) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                obs.toString(),
                                style: const TextStyle(height: 1.5, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (suggestedQuestions.isNotEmpty) ...[
                    const Text(
                      'දරුවාගෙන් අසන්න පුළුවන් ප්‍රශ්න:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...suggestedQuestions.map(
                      (q) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF7C3AED).withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Text('🗣️ ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  '"${q.toString()}"',
                                  style: const TextStyle(
                                    height: 1.45,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (followUpNeeded)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚠️ ', style: TextStyle(fontSize: 18)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'වැඩිදුර අවධානය අවශ්‍ය විය හැක',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (followUpReason.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    followUpReason,
                                    style: const TextStyle(
                                      height: 1.5,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    'මෙය මෘදුකාංග ආධාරයෙන් සකසූ නිරීක්ෂණ වාර්තාවකි. '
                    'වෛද්‍ය හෝ මනෝ විද්‍යාත්මක රෝග නිර්ණයක් ලෙස සලකන්නේ නැත. '
                    'දරුවාගේ හැසිරීමේ සැලකිය යුතු වෙනස් කම් ඔබ දුටුවහොත් '
                    'සුදුසු වෘත්තිකයෙකු හමුවීම නිර්දේශ කෙරේ.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Color Analysis Card
// ─────────────────────────────────────────────────────────────

class _ColorAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> drawing;
  const _ColorAnalysisCard({required this.drawing});

  Map _getColorData() {
    final llm = drawing['llm_review'];
    if (llm is Map && llm['color_analysis'] is Map) {
      return llm['color_analysis'] as Map;
    }
    if (drawing['color_analysis'] is Map) {
      return drawing['color_analysis'] as Map;
    }
    return {};
  }

  Color _colorSwatch(String name) {
    final n = name.toLowerCase();
    if (n.contains('red') || n.contains('රතු')) return Colors.red.shade400;
    if (n.contains('blue') || n.contains('නිල්')) return Colors.blue.shade400;
    if (n.contains('green') || n.contains('කොළ')) return Colors.green.shade500;
    if (n.contains('yellow') || n.contains('කහ')) return Colors.yellow.shade600;
    if (n.contains('orange') || n.contains('තැඹිලි')) {
      return Colors.orange.shade400;
    }
    if (n.contains('purple') || n.contains('දම්')) return Colors.purple.shade400;
    if (n.contains('pink') || n.contains('රෝස')) return Colors.pink.shade300;
    if (n.contains('brown') || n.contains('දුඹුරු')) return Colors.brown.shade400;
    if (n.contains('black') || n.contains('කළු')) return Colors.black87;
    if (n.contains('white') || n.contains('සුදු')) return Colors.grey.shade300;
    if (n.contains('grey') || n.contains('gray') || n.contains('අළු')) {
      return Colors.grey.shade500;
    }
    return Colors.grey.shade400;
  }

  String _pressureSinhala(String p) {
    switch (p.toLowerCase()) {
      case 'light':
        return 'සැහැල්ලු පීඩනය';
      case 'medium':
        return 'මධ්‍යම පීඩනය';
      case 'heavy':
        return 'දැඩි පීඩනය';
      case 'mixed':
        return 'මිශ්‍ර පීඩනය';
      default:
        return p;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _getColorData();
    if (data.isEmpty) return const SizedBox.shrink();

    final colors = data['dominant_colors'] is List
        ? (data['dominant_colors'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final mood = data['palette_mood']?.toString() ?? '';
    final warmCool = data['warm_cool_balance']?.toString() ?? '';
    final pressure = data['pressure_observations']?.toString() ?? '';
    final interpretations = data['interpretation'] is List
        ? (data['interpretation'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return _SectionCard(
      icon: Icons.palette_outlined,
      title: 'වර්ණ විශ්ලේෂණය',
      accentColor: Colors.deepPurple.shade400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (colors.isNotEmpty) ...[
            const Text(
              'භාවිත කළ වර්ණ:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.map((c) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _colorSwatch(c),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(c, style: const TextStyle(fontSize: 13)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          if (mood.isNotEmpty)
            _AnalysisRow(icon: '🎨', label: 'වර්ණ මනෝභාවය', value: mood),
          if (warmCool.isNotEmpty)
            _AnalysisRow(
              icon: '🌡️',
              label: 'උණුසුම් / සීතල වර්ණ',
              value: warmCool,
            ),
          if (pressure.isNotEmpty)
            _AnalysisRow(
              icon: '✏️',
              label: 'ඇඳීමේ පීඩනය',
              value: _pressureSinhala(pressure),
            ),
          if (interpretations.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'විශ්ලේෂකයාගේ නිරීක්ෂණ:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
            const SizedBox(height: 6),
            ...interpretations.map(
              (obs) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Expanded(
                      child: Text(
                        obs,
                        style: const TextStyle(fontSize: 13.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Spatial Analysis Card
// ─────────────────────────────────────────────────────────────

class _SpatialAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> drawing;
  const _SpatialAnalysisCard({required this.drawing});

  Map _getSpatialData() {
    final llm = drawing['llm_review'];
    if (llm is Map && llm['spatial_analysis'] is Map) {
      return llm['spatial_analysis'] as Map;
    }
    if (drawing['spatial_analysis'] is Map) {
      return drawing['spatial_analysis'] as Map;
    }
    return {};
  }

  String _layoutSinhala(String layout) {
    switch (layout.toLowerCase()) {
      case 'centered':
        return 'මධ්‍යගත';
      case 'peripheral':
        return 'මායිම් ප්‍රදේශයේ';
      case 'divided':
        return 'බෙදී ඇති';
      case 'scattered':
        return 'විසිරී ඇති';
      default:
        return layout;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _getSpatialData();
    if (data.isEmpty) return const SizedBox.shrink();

    final layout = data['layout_type']?.toString() ?? '';
    final figureSizes = data['figure_sizes']?.toString() ?? '';
    final connections = data['connections']?.toString() ?? '';
    final emptySpace = data['empty_space']?.toString() ?? '';
    final placementNotes = data['placement_notes'] is List
        ? (data['placement_notes'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final relationshipNotes = data['relationship_notes'] is List
        ? (data['relationship_notes'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return _SectionCard(
      icon: Icons.grid_view_outlined,
      title: 'අවකාශ සැකැස්ම',
      accentColor: Colors.teal.shade600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (layout.isNotEmpty)
            _AnalysisRow(
              icon: '📐',
              label: 'සැකැස්ම ආකාරය',
              value: _layoutSinhala(layout),
            ),
          if (figureSizes.isNotEmpty)
            _AnalysisRow(icon: '📏', label: 'රූප ප්‍රමාණ', value: figureSizes),
          if (connections.isNotEmpty)
            _AnalysisRow(icon: '🔗', label: 'රූප සම්බන්ධතා', value: connections),
          if (emptySpace.isNotEmpty)
            _AnalysisRow(icon: '⬜', label: 'හිස් අවකාශය', value: emptySpace),
          if (placementNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'ස්ථානගත කිරීමේ නිරීක්ෂණ:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
            const SizedBox(height: 6),
            ...placementNotes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(fontSize: 13.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (relationshipNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'සම්බන්ධතා නිරීක්ෂණ:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
            const SizedBox(height: 6),
            ...relationshipNotes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(fontSize: 13.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stroke Analysis Card
// ─────────────────────────────────────────────────────────────

class _StrokeAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> drawing;
  const _StrokeAnalysisCard({required this.drawing});

  Map _getStrokeData() {
    final llm = drawing['llm_review'];
    if (llm is Map && llm['stroke_analysis'] is Map) {
      return llm['stroke_analysis'] as Map;
    }
    if (drawing['stroke_analysis'] is Map) {
      return drawing['stroke_analysis'] as Map;
    }
    return {};
  }

  String _pressureSinhala(String p) {
    switch (p.toLowerCase()) {
      case 'light':
        return 'සැහැල්ලු';
      case 'medium':
        return 'මධ්‍යම';
      case 'heavy':
        return 'දැඩි';
      case 'mixed':
        return 'මිශ්‍ර';
      default:
        return p;
    }
  }

  String _controlSinhala(String c) {
    switch (c.toLowerCase()) {
      case 'controlled':
        return 'පාලිත / සියුම්';
      case 'chaotic':
        return 'අවිධිමත් / සසල';
      case 'mixed':
        return 'මිශ්‍ර';
      default:
        return c;
    }
  }

  String _detailSinhala(String d) {
    switch (d.toLowerCase()) {
      case 'minimal':
        return 'සරල / අවම';
      case 'moderate':
        return 'මධ්‍යම';
      case 'detailed':
        return 'සවිස්තරාත්මක';
      default:
        return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _getStrokeData();
    if (data.isEmpty) return const SizedBox.shrink();

    final pressure = data['pressure']?.toString() ?? '';
    final control = data['control']?.toString() ?? '';
    final detail = data['detail_level']?.toString() ?? '';
    final notable = data['notable_marks']?.toString() ?? '';

    if (pressure.isEmpty &&
        control.isEmpty &&
        detail.isEmpty &&
        (notable.isEmpty ||
            notable.toLowerCase() == 'none' ||
            notable.toLowerCase() == 'no notable marks')) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      icon: Icons.gesture,
      title: 'රේඛා සහ ඇඳීමේ ශෛලිය',
      accentColor: Colors.orange.shade700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pressure.isNotEmpty)
            _AnalysisRow(
              icon: '🖊️',
              label: 'රේඛා පීඩනය',
              value: _pressureSinhala(pressure),
            ),
          if (control.isNotEmpty)
            _AnalysisRow(
              icon: '🎯',
              label: 'රේඛා පාලනය',
              value: _controlSinhala(control),
            ),
          if (detail.isNotEmpty)
            _AnalysisRow(
              icon: '🔍',
              label: 'සවිස්තරාත්මකභාවය',
              value: _detailSinhala(detail),
            ),
          if (notable.isNotEmpty &&
              notable.toLowerCase() != 'none' &&
              notable.toLowerCase() != 'no notable marks') ...[
            const SizedBox(height: 8),
            _AnalysisRow(icon: '📝', label: 'විශේෂ ලකුණු', value: notable),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shared helper row widget
// ─────────────────────────────────────────────────────────────

class _AnalysisRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _AnalysisRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color accentColor;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.accentColor = const Color(0xFF43A047),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DefaultTextStyle(
              style: const TextStyle(
                fontSize: 14.5,
                color: Colors.black87,
                height: 1.5,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _EmotionBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_search, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'මෙම දරුවා සදහා\nතවම චිත්‍ර වාර්තා නොමැත.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}