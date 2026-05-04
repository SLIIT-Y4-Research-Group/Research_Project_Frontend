import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_client.dart';

class ChildReportScreen extends StatefulWidget {
  final String childId;
  final String? childName;

  const ChildReportScreen({
    super.key,
    required this.childId,
    this.childName,
  });

  @override
  State<ChildReportScreen> createState() => _ChildReportScreenState();
}

class _ChildReportScreenState extends State<ChildReportScreen> {
  Map<String, dynamic>? _report;
  bool _isLoading = true;
  String? _error;
  int _selectedDays = 30;
  bool _isExporting = false;

  final GlobalKey _reportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.getChildReport(
        childId: widget.childId,
        days: _selectedDays,
      );

      if (res.statusCode == 200) {
        setState(() => _report = jsonDecode(res.body));
      } else {
        setState(() {
          _error = 'වාර්තාව ලබාගැනීම අසාර්ථකයි (${res.statusCode})';
        });
      }
    } catch (e) {
      setState(() => _error = 'දෝෂයක් ඇති විය: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportAsPng() async {
    setState(() => _isExporting = true);

    try {
      final boundary =
          _reportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return;

      final img = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final name =
          '${widget.childName ?? "child"}_report_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = io.File('${dir.path}/$name');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.childName ?? "දරුවා"}ගේ චිත්‍ර හැඟීම් වාර්තාව',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export අසාර්ථකයි: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.childName != null
        ? '${widget.childName}ගේ වාර්තාව'
        : 'දරුවාගේ වාර්තාව';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            tooltip: 'කාල සීමාව',
            onSelected: (v) {
              _selectedDays = v;
              _fetchReport();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text('සති 1')),
              PopupMenuItem(value: 30, child: Text('මාස 1')),
              PopupMenuItem(value: 90, child: Text('මාස 3')),
            ],
          ),
          IconButton(
            tooltip: 'Export',
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: (_report != null && !_isExporting) ? _exportAsPng : null,
          ),
          IconButton(
            tooltip: 'නැවුම් කරන්න',
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF43A047)),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _report == null
                  ? const Center(child: Text('දත්ත නොමැත'))
                  : SingleChildScrollView(
                      child: RepaintBoundary(
                        key: _reportKey,
                        child: _ReportBody(report: _report!),
                      ),
                    ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  final Map<String, dynamic> report;

  const _ReportBody({required this.report});

  @override
  Widget build(BuildContext context) {
    final summary = report['summary'] as Map? ?? {};
    final emotionTimeline = report['emotion_timeline'] as List? ?? [];
    final weeklyEmotion = report['weekly_emotion'] as List? ?? [];
    final therapySummary = report['therapy_summary'] as Map? ?? {};
    final therapyWeekly = report['therapy_weekly'] as List? ?? [];
    final therapySessions = report['therapy_sessions'] as List? ?? [];
    final childName = report['child_name']?.toString() ?? 'දරුවා';
    final days = report['report_period_days']?.toString() ?? '30';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ReportHeader(
            childName: childName,
            days: days,
            generatedAt: report['generated_at']?.toString() ?? '',
          ),
          const SizedBox(height: 12),
          _StatCardsRow(summary: summary),
          const SizedBox(height: 16),

          if (summary['total_drawings'] != null &&
              (summary['total_drawings'] as int) > 0)
            _ChartCard(
              icon: Icons.pie_chart_outline,
              title: 'හැඟීම් බෙදාහැරීම',
              accentColor: const Color(0xFF43A047),
              child: _EmotionDonutChart(
                happyCount: (summary['happy_count'] ?? 0) as int,
                sadCount: (summary['sad_count'] ?? 0) as int,
                happyPct: (summary['happy_pct'] ?? 0.0).toDouble(),
                sadPct: (summary['sad_pct'] ?? 0.0).toDouble(),
              ),
            ),

          if (emotionTimeline.isNotEmpty)
            _ChartCard(
              icon: Icons.show_chart,
              title: 'හැඟීම් කාල රේඛාව',
              accentColor: const Color(0xFF1976D2),
              child: _EmotionTimelineChart(timeline: emotionTimeline),
            ),

          if (weeklyEmotion.isNotEmpty)
            _ChartCard(
              icon: Icons.bar_chart,
              title: 'සාප්තාහික හැඟීම් සාරාංශය',
              accentColor: const Color(0xFF7B1FA2),
              child: _WeeklyEmotionBarChart(weekly: weeklyEmotion),
            ),

          _ChartCard(
            icon: Icons.self_improvement,
            title: 'ශිල්පකාම ක්‍රියාකාරකම් සාරාංශය',
            accentColor: const Color(0xFFF57C00),
            child: _TherapySummaryWidget(summary: therapySummary),
          ),

          if (therapyWeekly.isNotEmpty)
            _ChartCard(
              icon: Icons.sports_esports_outlined,
              title: 'සාප්තාහික ක්‍රියාකාරකම් සහභාගීත්වය',
              accentColor: const Color(0xFFF57C00),
              child: _TherapyWeeklyBarChart(weekly: therapyWeekly),
            ),

          if (therapySessions.isNotEmpty)
            _ChartCard(
              icon: Icons.list_alt,
              title: 'ශිල්පකාම වාර්තා ඉතිහාසය',
              accentColor: const Color(0xFF0097A7),
              child: _TherapySessionsList(sessions: therapySessions),
            ),

          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 16),
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
                    'වෛද්‍ය හෝ මනෝ විද්‍යාත්මක රෝග නිර්ණයක් ලෙස සලකන්නේ නැත.',
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

class _ReportHeader extends StatelessWidget {
  final String childName;
  final String days;
  final String generatedAt;

  const _ReportHeader({
    required this.childName,
    required this.days,
    required this.generatedAt,
  });

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$childName ගේ',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Text(
            'හැඟීම් හා ශිල්පකාම වාර්තාව',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'කාල සීමාව: දින $days  •  ජනනය කළ දිනය: ${_formatDate(generatedAt)}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatCardsRow extends StatelessWidget {
  final Map summary;

  const _StatCardsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final totalDrawings = summary['total_drawings'] ?? 0;
    final happyPct = (summary['happy_pct'] ?? 0.0).toDouble();
    final sadPct = (summary['sad_pct'] ?? 0.0).toDouble();
    final therapySessions = summary['total_therapy_sessions'] ?? 0;
    final therapyMinutes = (summary['total_therapy_minutes'] ?? 0.0).toDouble();
    final engagementRate =
        (summary['therapy_engagement_rate_pct'] ?? 0.0).toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.brush,
                value: '$totalDrawings',
                label: 'මුළු\nචිත්‍ර',
                color: const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.sentiment_satisfied_alt,
                value: '$happyPct%',
                label: 'සතුටු\nහැඟීම්',
                color: const Color(0xFF43A047),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.sentiment_dissatisfied,
                value: '$sadPct%',
                label: 'දුකසිත\nහැඟීම්',
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.self_improvement,
                value: '$therapySessions',
                label: 'ශිල්පකාම\nවාර',
                color: const Color(0xFFF57C00),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.timer_outlined,
                value: '${therapyMinutes.toStringAsFixed(1)}m',
                label: 'ශිල්පකාම\nකාලය',
                color: const Color(0xFF0097A7),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up,
                value: '$engagementRate%',
                label: 'සහභාගීත්ව\nඅනුපාතය',
                color: const Color(0xFF7B1FA2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 95,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmotionDonutChart extends StatelessWidget {
  final int happyCount;
  final int sadCount;
  final double happyPct;
  final double sadPct;

  const _EmotionDonutChart({
    required this.happyCount,
    required this.sadCount,
    required this.happyPct,
    required this.sadPct,
  });

  @override
  Widget build(BuildContext context) {
    final total = happyCount + sadCount;

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: _DonutPainter(
                  slices: [
                    _DonutSlice(
                      value: happyCount.toDouble(),
                      color: const Color(0xFF43A047),
                    ),
                    _DonutSlice(
                      value: sadCount.toDouble(),
                      color: const Color(0xFFDC2626),
                    ),
                  ],
                  centerText: '$total',
                  centerLabel: 'මුළු',
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(
                  color: const Color(0xFF43A047),
                  label: 'සතුටු',
                  value: '$happyCount ($happyPct%)',
                ),
                const SizedBox(height: 12),
                _LegendItem(
                  color: const Color(0xFFDC2626),
                  label: 'දුකසිත',
                  value: '$sadCount ($sadPct%)',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sadPct > 30)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF57C00)),
            ),
            child: const Row(
              children: [
                Text('💡 ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    'දුකසිත හැඟීම් 30%ට වඩා ඉහළ ය. දරුවා සමඟ ගැමිවල හෝ ස්වභාව ධර්මය තුළ කාලය ගත කිරීම නිර්දේශ කෙරේ.',
                    style: TextStyle(fontSize: 12.5, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DonutSlice {
  final double value;
  final Color color;

  const _DonutSlice({
    required this.value,
    required this.color,
  });
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSlice> slices;
  final String centerText;
  final String centerLabel;

  const _DonutPainter({
    required this.slices,
    required this.centerText,
    required this.centerLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeW = 32.0;
    const startAngle = -3.14159 / 2;

    double currentAngle = startAngle;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    for (final slice in slices) {
      final sweep = (slice.value / total) * 2 * 3.14159;
      paint.color = slice.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweep,
        false,
        paint,
      );
      currentAngle += sweep;
    }

    final valuePainter = TextPainter(
      text: TextSpan(
        text: centerText,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    valuePainter.paint(
      canvas,
      center - Offset(valuePainter.width / 2, valuePainter.height / 2 + 8),
    );

    final labelPainter = TextPainter(
      text: TextSpan(
        text: centerLabel,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    labelPainter.paint(
      canvas,
      center - Offset(labelPainter.width / 2, -valuePainter.height / 2 + 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
          ],
        ),
      ],
    );
  }
}

class _EmotionTimelineChart extends StatelessWidget {
  final List timeline;

  const _EmotionTimelineChart({required this.timeline});

  @override
  Widget build(BuildContext context) {
    final data =
        timeline.length > 20 ? timeline.sublist(timeline.length - 20) : timeline;

    if (data.isEmpty) {
      return const Text('දත්ත නොමැත');
    }

    final firstDate = data.first['date']?.toString() ?? '';
    final lastDate = data.last['date']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'සෑම ලක්ෂ්‍යක්ම එක් චිත්‍ර සැසියකි. 🟢 = සතුටු, 🔴 = දුකසිත',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          width: double.infinity,
          child: CustomPaint(
            painter: _TimelinePainter(data: data),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              firstDate.length >= 10 ? firstDate.substring(5) : '',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              lastDate.length >= 10 ? lastDate.substring(5) : '',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List data;

  const _TimelinePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final n = data.length;
    final spacing = size.width / (n > 1 ? n - 1 : 1);
    const happyY = 25.0;
    const sadY = 85.0;

    final linePaint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    Offset? prev;

    for (int i = 0; i < n; i++) {
      final emotion = data[i]['emotion']?.toString().toLowerCase() ?? 'unknown';
      final x = i * spacing;
      final y = emotion == 'happy' ? happyY : sadY;
      final curr = Offset(x, y);

      if (prev != null) {
        linePaint.color = Colors.grey.shade300;
        canvas.drawLine(prev, curr, linePaint);
      }

      prev = curr;
    }

    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final emotion = data[i]['emotion']?.toString().toLowerCase() ?? 'unknown';
      final x = i * spacing;
      final y = emotion == 'happy' ? happyY : sadY;

      dotPaint.color =
          emotion == 'happy' ? const Color(0xFF43A047) : const Color(0xFFDC2626);
      canvas.drawCircle(Offset(x, y), 7, dotPaint);

      dotPaint.color = Colors.white;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }

    final tpHappy = TextPainter(
      text: const TextSpan(
        text: 'සතුටු',
        style: TextStyle(fontSize: 10, color: Colors.grey),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tpHappy.paint(canvas, Offset(0, happyY - 18));

    final tpSad = TextPainter(
      text: const TextSpan(
        text: 'දුකසිත',
        style: TextStyle(fontSize: 10, color: Colors.grey),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tpSad.paint(canvas, Offset(0, sadY + 6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WeeklyEmotionBarChart extends StatelessWidget {
  final List weekly;

  const _WeeklyEmotionBarChart({required this.weekly});

  @override
  Widget build(BuildContext context) {
    final maxTotal = weekly.fold<int>(
      0,
      (m, w) => ((w['total'] ?? 0) as int) > m ? (w['total'] as int) : m,
    );

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: const [
            _LegendItem(
              color: Color(0xFF43A047),
              label: 'සතුටු',
              value: '',
            ),
            _LegendItem(
              color: Color(0xFFDC2626),
              label: 'දුකසිත',
              value: '',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 155,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekly.map((w) {
                final total = (w['total'] ?? 1) as int;
                final happy = (w['happy'] ?? 0) as int;
                final sad = (w['sad'] ?? 0) as int;
                final maxH = 115.0;
                final barH = maxTotal > 0 ? (total / maxTotal) * maxH : 0.0;
                final happyH = total > 0 ? (happy / total) * barH : 0.0;
                final sadH = barH - happyH;
                final week = (w['week']?.toString() ?? '').replaceAll('W', ' W');

                return SizedBox(
                  width: 46,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (happyH > 0)
                              Container(
                                height: happyH,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF43A047),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            if (sadH > 0)
                              Container(
                                height: sadH,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.vertical(
                                    top: happyH == 0
                                        ? const Radius.circular(4)
                                        : Radius.zero,
                                    bottom: const Radius.circular(4),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          week.length > 7 ? week.substring(week.length - 4) : week,
                          style: const TextStyle(fontSize: 8, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _TherapySummaryWidget extends StatelessWidget {
  final Map summary;

  const _TherapySummaryWidget({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary['total_sessions'] ?? 0;
    final bubbleSessions = summary['bubble_pop_sessions'] ?? 0;
    final breathSessions = summary['breath_game_sessions'] ?? 0;
    final minutes = (summary['total_duration_minutes'] ?? 0.0).toDouble();
    final avgScore = summary['avg_bubble_pop_score'];

    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'තෝරාගත් කාල සීමාවේදී ශිල්පකාම ක්‍රියාකාරකම් සිදු කර නොමැත.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActivityGauge(
                icon: '🫧',
                label: 'බුබුළු ක්‍රීඩාව',
                count: bubbleSessions,
                total: total,
                color: const Color(0xFF2B86C5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActivityGauge(
                icon: '🌬️',
                label: 'හුස්ම ව්‍යායාමය',
                count: breathSessions,
                total: total,
                color: const Color(0xFF00C9FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _TherapyInfoRow(
          icon: '⏱️',
          label: 'මුළු ශිල්පකාම කාලය',
          value: '${minutes.toStringAsFixed(1)} මිනිත්තු',
        ),
        if (avgScore != null)
          _TherapyInfoRow(
            icon: '🎯',
            label: 'සාමාන්‍ය බුබුළු ලකුණු',
            value: avgScore.toString(),
          ),
        if (summary['last_session_at'] != null)
          _TherapyInfoRow(
            icon: '📅',
            label: 'අවසාන සැසිය',
            value: summary['last_session_at'].toString().substring(0, 10),
          ),
      ],
    );
  }
}

class _ActivityGauge extends StatelessWidget {
  final String icon;
  final String label;
  final int count;
  final int total;
  final Color color;

  const _ActivityGauge({
    required this.icon,
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;

    return Container(
      constraints: const BoxConstraints(minHeight: 145),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(pct * 100).round()}%',
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TherapyInfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _TherapyInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _TherapyWeeklyBarChart extends StatelessWidget {
  final List weekly;

  const _TherapyWeeklyBarChart({required this.weekly});

  @override
  Widget build(BuildContext context) {
    final maxVal = weekly.fold<int>(0, (m, w) {
      final bp = (w['bubble_pop'] ?? 0) as int;
      final bg = (w['breath_game'] ?? 0) as int;
      return (bp + bg) > m ? (bp + bg) : m;
    });

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: const [
            _LegendItem(
              color: Color(0xFF2B86C5),
              label: 'බුබුළු',
              value: '',
            ),
            _LegendItem(
              color: Color(0xFF00C9FF),
              label: 'හුස්ම',
              value: '',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekly.map((w) {
                final bp = (w['bubble_pop'] ?? 0) as int;
                final bg = (w['breath_game'] ?? 0) as int;
                final total = bp + bg;
                final maxH = 100.0;
                final barH = maxVal > 0 ? (total / maxVal) * maxH : 0.0;
                final bpH = total > 0 ? (bp / total) * barH : 0.0;
                final bgH = barH - bpH;
                final week = w['week']?.toString() ?? '';

                return SizedBox(
                  width: 46,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (total > 0)
                          Text(
                            '$total',
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (bpH > 0)
                              Container(
                                height: bpH,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2B86C5),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            if (bgH > 0)
                              Container(
                                height: bgH,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C9FF),
                                  borderRadius: BorderRadius.vertical(
                                    top: bpH == 0
                                        ? const Radius.circular(4)
                                        : Radius.zero,
                                    bottom: const Radius.circular(4),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          week.length >= 4 ? week.substring(week.length - 3) : week,
                          style: const TextStyle(fontSize: 8, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _TherapySessionsList extends StatelessWidget {
  final List sessions;

  const _TherapySessionsList({required this.sessions});

  String _activityName(String type) {
    switch (type) {
      case 'bubble_pop':
        return 'බුබුළු ක්‍රීඩාව 🫧';
      case 'breath_game':
        return 'හුස්ම ව්‍යායාමය 🌬️';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown =
        sessions.length > 10 ? sessions.sublist(sessions.length - 10) : sessions;

    return Column(
      children: shown.map((s) {
        final type = s['activity_type']?.toString() ?? '';
        final date = s['date']?.toString() ?? '';
        final dur = (s['duration_seconds'] ?? 0) as int;
        final score = s['score'];
        final rounds = s['rounds_completed'];
        final triggered = s['triggered_by_emotion']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Text(
                type == 'bubble_pop' ? '🫧' : '🌬️',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activityName(type),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$date  •  ${(dur / 60).toStringAsFixed(1)} min'
                      '${score != null ? '  •  ලකුණු: $score' : ''}'
                      '${rounds != null ? '  •  රවුන්ඩ්: $rounds' : ''}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    if (triggered.isNotEmpty)
                      Text(
                        'සිදු කළ හේතුව: $triggered',
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color accentColor;

  const _ChartCard({
    required this.icon,
    required this.title,
    required this.child,
    required this.accentColor,
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}