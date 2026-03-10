import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ParentDrawingsScreen extends StatefulWidget {
  const ParentDrawingsScreen({super.key});

  @override
  State<ParentDrawingsScreen> createState() => _ParentDrawingsScreenState();
}

class _ParentDrawingsScreenState extends State<ParentDrawingsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<dynamic> _drawings = [];
  String? _error;

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
      final token = await _authService.getToken();

      if (token == null) {
        setState(() {
          _error = 'No login token found';
          _isLoading = false;
        });
        return;
      }

      final response = await ApiClient.getParentDrawings();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _drawings = data;
          _isLoading = false;
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _error = data['detail'] ?? 'Failed to load drawings';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Color _emotionColor(String? emotion) {
    switch (emotion?.toLowerCase()) {
      case 'happy':
        return Colors.green;
      case 'sad':
        return Colors.blue;
      case 'angry':
        return Colors.red;
      case 'fear':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Child Drawings',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDrawings,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  )
                : _drawings.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              'No drawing entries found',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _drawings.length,
                        itemBuilder: (context, index) {
                          final item = _drawings[index];
                          final emotion = item['emotion'];
                          final emotionLabel = emotion?['label'] ?? 'Unknown';
                          final confidence = emotion?['confidence'];
                          final childName = item['child_name'] ?? 'Unknown';
                          final childUsername = item['child_username'] ?? '';
                          final note = item['note'];
                          final createdAt = item['created_at'] ?? '';
                          final sourceMode = item['source_mode'] ?? 'unknown';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFFE8F5E9),
                                        child: Text(
                                          childName.isNotEmpty
                                              ? childName[0].toUpperCase()
                                              : '?',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF2E7D32),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              childName,
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              '@$childUsername',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _emotionColor(emotionLabel)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          emotionLabel,
                                          style: GoogleFonts.inter(
                                            color: _emotionColor(emotionLabel),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Created At: $createdAt',
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Source Mode: $sourceMode',
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    confidence != null
                                        ? 'Confidence: ${(confidence * 100).toStringAsFixed(1)}%'
                                        : 'Confidence: N/A',
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                  if (note != null &&
                                      note.toString().trim().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Note:',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      note,
                                      style: GoogleFonts.inter(fontSize: 14),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}