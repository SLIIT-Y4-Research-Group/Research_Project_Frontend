import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'music_recommendation_screen.dart';
import 'emotion_puzzle_screen.dart';
import '../config/api_config.dart';

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
    if (kIsWeb) {
      // Web implementation using HTML file input with camera capture
      final html.FileUploadInputElement uploadInput =
          html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.setAttribute('capture', 'camera'); // Opens device camera
      uploadInput.click();

      uploadInput.onChange.listen((event) async {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(files[0]);
          reader.onLoadEnd.listen((event) {
            setState(() {
              _capturedImage = reader.result as Uint8List;
            });
          });
        }
      });
    }
  }

  Future<void> _detectEmotion() async {
    if (_capturedImage == null) return;

    setState(() {
      _isScanning = true;
    });
    _animationController.repeat();

    try {
      // Convert image to base64
      String base64Image = base64Encode(_capturedImage!);

      // Make API request to backend (new endpoint with happy face generation)
      final response = await http.post(
        Uri.parse(ApiConfig.emotionPredictWithHappyFace),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      );

      _animationController.stop();
      setState(() {
        _isScanning = false;
      });

      if (response.statusCode == 200) {
        // Parse response
        final responseData = jsonDecode(response.body);
        final String detectedEmotion = responseData['emotion_label'];
        final double confidence = responseData['confidence'];
        final bool isHappy = responseData['is_happy'] ?? false;
        final String? happyFaceImage = responseData['happy_face_image'];
        final String? message = responseData['message'];

        print('Detected emotion: $detectedEmotion (confidence: $confidence)');

        // If not happy and we have a happy face image, show it
        if (!isHappy && happyFaceImage != null) {
          await _showHappyFaceDialog(detectedEmotion, happyFaceImage, message ?? '');
        }

        // Map backend emotions to app emotions
        // Backend: ['angry', 'disgust', 'fear', 'happy', 'neutral', 'sad', 'surprise']
        // App: ['happy', 'sad', 'anxious', 'calm', 'angry', 'neutral']
        String mappedEmotion = detectedEmotion;
        if (detectedEmotion == 'fear' || detectedEmotion == 'disgust') {
          mappedEmotion = 'anxious';
        } else if (detectedEmotion == 'surprise') {
          mappedEmotion = 'neutral';
        }

        // Check if emotion is negative
        final negativeEmotions = ['sad', 'anxious', 'angry', 'fear', 'disgust'];
        final isNegativeEmotion = negativeEmotions.contains(mappedEmotion);

        if (isNegativeEmotion) {
          // Navigate to puzzle screen for negative emotions
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EmotionPuzzleScreen(detectedEmotion: mappedEmotion),
            ),
          );
        } else {
          // Navigate to music recommendation screen for positive emotions
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MusicRecommendationScreen(emotion: mappedEmotion),
            ),
          );
        }
      } else {
        // Handle error response
        _showErrorDialog('Failed to detect emotion. Status: ${response.statusCode}');
      }
    } catch (e) {
      _animationController.stop();
      setState(() {
        _isScanning = false;
      });
      _showErrorDialog('Error connecting to backend: $e');
    }
  }

  Future<void> _showHappyFaceDialog(String emotion, String happyFaceBase64, String message) async {
    // Decode base64 to display image
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
              // Title
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.purple, size: 28),
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
              
              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Comparison: Original vs Happy
              Row(
                children: [
                  // Original image
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Original',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
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
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            emotion.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Arrow
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.purple,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  // Happy version
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Happy You!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
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
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'HAPPY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image preview area
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
                          // Scanning animation overlay
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
                            Icon(
                              Icons.camera_alt,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to capture image',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 30),
              // Detect Emotion button
              ElevatedButton.icon(
                onPressed: _capturedImage != null && !_isScanning
                    ? _detectEmotion
                    : null,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.grey),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera, color: Colors.grey),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, color: Colors.grey),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.grey),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
