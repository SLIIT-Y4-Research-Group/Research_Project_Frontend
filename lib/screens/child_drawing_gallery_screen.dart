import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../services/api_client.dart';

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

  String get _baseUrl =>
      kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data is Map ? (data['items'] ?? []) : data;

        setState(() {
          _drawings = items.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() {
          _error = 'චිත්‍ර ලබාගැනීම අසාර්ථකයි: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'දෝෂයක් ඇති විය: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _imageUrl(Map<String, dynamic> item) {
    final id = item['analysis_id']?.toString() ?? item['id']?.toString() ?? '';
    return '$_baseUrl/drawing/image/$id';
  }

  void _openDrawing(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildDrawingViewScreen(
          item: item,
          imageUrl: _imageUrl(item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF6),
      appBar: AppBar(
        title: const Text('මගේ චිත්‍ර ගැලරිය'),
        backgroundColor: const Color(0xFF4EAA57),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadDrawings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4EAA57)),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _drawings.isEmpty
                  ? const Center(child: Text('තවම චිත්‍ර නොමැත.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _drawings.length,
                      itemBuilder: (context, index) {
                        final item = _drawings[index];
                        final date = item['created_at']?.toString() ?? '';

                        return InkWell(
                          onTap: () => _openDrawing(item),
                          borderRadius: BorderRadius.circular(16),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.network(
                                    _imageUrl(item),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    date.length > 10
                                        ? date.substring(0, 10)
                                        : date,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class ChildDrawingViewScreen extends StatelessWidget {
  const ChildDrawingViewScreen({
    super.key,
    required this.item,
    required this.imageUrl,
  });

  final Map<String, dynamic> item;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final date = item['created_at']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('මගේ චිත්‍රය'),
        backgroundColor: const Color(0xFF4EAA57),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(imageUrl),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'දිනය: ${date.length > 10 ? date.substring(0, 10) : date}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'ඔයාගේ චිත්‍රය සුරක්ෂිතව ගබඩා කර ඇත. වාර්තාව දෙමාපියන්ට පමණක් පෙන්වනු ලැබේ.',
                style: TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}