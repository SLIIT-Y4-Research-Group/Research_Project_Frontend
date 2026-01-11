import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart';

import 'music_recommendation_screen.dart';
import 'emotion_puzzle_screen.dart';
import '../config/api_config.dart';

// IMPORTANT: only import this when running on web
// We'll import it conditionally by using a try-catch style import is not possible in Dart,
// so we import normally but only CALL it inside kIsWeb. This file must not import dart:html
// in scan_screen.dart itself.
import '../utils/web_camera_picker.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  Uint8List? _capturedImage;
  bool _isScanning = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    try {
      if (kIsWeb) {
        // ✅ Web camera capture
        final bytes = await pickImageFromWebCamera();
        if (bytes == null) return;

        setState(() {
          _capturedImage = bytes;
        });
        return;
      }

      // ✅ Mobile camera capture
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _capturedImage = bytes;
      });
    } catch (e) {
      _showErrorDialog("Camera open failed: $e");
    }
  }

  Future<void> _detectEmotion() async {
    if (_capturedImage == null) return;

    setState(() {
      _isScanning = true;
    });
    _animationController.repeat();

    try {
      final base64Image = base64Encode(_capturedImage!);

      final response = await http.post(
        Uri.parse(ApiConfig.emotionPredictWithHappyFace),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );

      _animationController.stop();
      setState(() => _isScanning = false);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final String detectedEmotion = responseData['emotion_label'];
        final double confidence = (responseData['confidence'] as num).toDouble();
        final bool isHappy = responseData['is_happy'] ?? false;
        final String? happyFaceImage = responseData['happy_face_image'];
        final String? message = responseData['message'];

        if (!isHappy && happyFaceImage != null) {
          await _showHappyFaceDialog(
            detectedEmotion,
            happyFaceImage,
            message ?? '',
          );
        }

        String mappedEmotion = detectedEmotion;
        if (detectedEmotion == 'fear' || detectedEmotion == 'disgust') {
          mappedEmotion = 'anxious';
        } else if (detectedEmotion == 'surprise') {
          mappedEmotion = 'neutral';
        }

        final negativeEmotions = ['sad', 'anxious', 'angry', 'fear', 'disgust'];
        final isNegativeEmotion = negativeEmotions.contains(mappedEmotion);

        if (isNegativeEmotion) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EmotionPuzzleScreen(detectedEmotion: mappedEmotion),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MusicRecommendationScreen(emotion: mappedEmotion),
            ),
          );
        }
      } else {
        _showErrorDialog(
          'Failed to detect emotion. Status: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      _animationController.stop();
      setState(() => _isScanning = false);
      _showErrorDialog('Error connecting to backend: $e');
    }
  }

  // --- keep your _showHappyFaceDialog and _showErrorDialog and build() SAME ---
  // (no changes needed below)
  Future<void> _showHappyFaceDialog(
      String emotion, String happyFaceBase64, String message) async {
    Uint8List happyImageBytes = base64Decode(happyFaceBase64);

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Colors.purple, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Here\'s a Happier You!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                message,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Original',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _capturedImage!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward,
                      color: Colors.purple, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Happy You!',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600])),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            happyImageBytes,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // keep your UI as-is
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 300,
                height: 350,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: _capturedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.memory(
                              _capturedImage!,
                              width: 300,
                              height: 350,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (_isScanning)
                            AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return Positioned(
                                  top: _animation.value * 330,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.purple.withOpacity(0.8),
                                          Colors.purple,
                                          Colors.purple.withOpacity(0.8),
                                          Colors.transparent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.purple.withOpacity(0.5),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      )
                    : InkWell(
                        onTap: _openCamera,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Tap to capture image',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[500])),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed:
                    _capturedImage != null && !_isScanning ? _detectEmotion : null,
                icon: _isScanning
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isScanning ? 'Scanning...' : 'Detect Emotion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.purple.withOpacity(0.5),
                  disabledForegroundColor: Colors.white.withOpacity(0.7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home, color: Colors.grey), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera, color: Colors.grey), label: 'Scan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite, color: Colors.grey), label: 'Favorites'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person, color: Colors.grey), label: 'Profile'),
        ],
      ),
    );
  }
}
