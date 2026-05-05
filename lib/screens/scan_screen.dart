import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

import '../config/api_config.dart';
import 'emotion_puzzle_screen.dart';
import 'music_recommendation_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  Uint8List? _capturedImage;
  bool _isScanning = false;
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    // Ping-pong animation for a continuous scanning effect
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get _isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<Uint8List> _loadAssetImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'ෆොටෝ එකක් දාන්න', // Add a Photo
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'අලුත් සෙල්ෆියක් ගන්න නැතිනම් සාම්පලයක් භාවිතා කර බලන්න.', // Snap a fresh selfie or try a sample to see the magic.
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openCamera();
                },
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text(
                  'කැමරාව විවෘත කරන්න',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ), // Open Camera
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F63FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _useSampleImage();
                },
                icon: const Icon(Icons.image_rounded),
                label: const Text(
                  'සාම්පලයක් බලන්න',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ), // Try Sample Image
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A085).withOpacity(0.1),
                  foregroundColor: const Color(0xFF16A085),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'අවලංගු කරන්න',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ), // Cancel
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _capturedImage = bytes);
    }
  }

  Future<void> _useSampleImage() async {
    try {
      final sampleImage = await _loadAssetImage('assets/images/sadperson.png');
      setState(() => _capturedImage = sampleImage);
    } catch (e) {
      _showErrorDialog(
        'සාම්පලය ලබා ගැනීම අසාර්ථක විය: $e',
      ); // Failed to load sample image
    }
  }

  Future<void> _detectEmotion() async {
    if (_capturedImage == null) return;

    setState(() => _isScanning = true);
    _animationController.repeat(reverse: true);

    try {
      if (_isMobile) {
        await Future.delayed(const Duration(seconds: 2));

        _animationController.stop();
        setState(() => _isScanning = false);

        final happyPersonImage = await _loadAssetImage(
          'assets/images/happyperson.png',
        );
        _showNavigationChoiceDialog('sad', happyPersonImage, false);
      } else {
        final String base64Image = base64Encode(_capturedImage!);

        final response = await http.post(
          Uri.parse(ApiConfig.emotionPredictWithHappyFace),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'image': base64Image}),
        );

        _animationController.stop();
        setState(() => _isScanning = false);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final String detectedEmotion = data['emotion_label'] ?? 'neutral';
          final String? happyFaceBase64 = data['happy_face_image'];
          final bool isHappy = data['is_happy'] ?? false;

          Uint8List? happyFaceImage;
          if (happyFaceBase64 != null) {
            happyFaceImage = base64Decode(happyFaceBase64);
          }

          _showNavigationChoiceDialog(detectedEmotion, happyFaceImage, isHappy);
        } else {
          _showErrorDialog(
            'හැඟීම් විශ්ලේෂණය කිරීම අසාර්ථක විය: ${response.statusCode}',
          ); // Failed to analyze emotion
        }
      }
    } catch (e) {
      _animationController.stop();
      setState(() => _isScanning = false);
      _showErrorDialog('දෝෂයක්: $e'); // Error
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('අයියෝ!'), // Oops!
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('හරි'), // Got it
          ),
        ],
      ),
    );
  }

  void _showNavigationChoiceDialog(
    String detectedEmotion,
    Uint8List? happyFaceImage,
    bool isHappy,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Text(
              'මූඩ් එක පරීක්ෂාව', // Vibe Check
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3F63FF), Color(0xFF6C3FFF)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                detectedEmotion
                    .toUpperCase(), // Keeping the backend emotion tag in English looks cool usually
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'ඔබේ මූඩ් එක අපි හඳුනාගත්තා. ඊළඟට මොකද කරන්නේ?', // We found your vibe. What do you want to do next?
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.black87),
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                            MusicRecommendationScreen(
                              emotion: detectedEmotion,
                              initialScanImageBase64: base64Encode(_capturedImage!),
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.music_note_rounded),
                  label: const Text(
                    'මගේ ප්ලේලිස්ට් එක ගන්න',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ), // Get My Playlist
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1C22),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (happyFaceImage != null)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmotionPuzzleScreen(
                            detectedEmotion: detectedEmotion,
                            happyFaceImage: happyFaceImage,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.extension_rounded),
                    label: const Text(
                      'පසල් එකක් ගහමු',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ), // Play Mood Puzzle
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A085),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'වහන්න',
                  style: TextStyle(color: Colors.grey),
                ), // Close
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'මූඩ් ස්කෑන්',
          style: TextStyle(fontWeight: FontWeight.w800),
        ), // Mood Scan
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A1C22),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background blobs - Made much smaller!
          Positioned(
            top: -40,
            right: -60,
            child: Image.asset(
              'assets/images/Ellipse1.png',
              width: 250, // Reduced from 450
              height: 250, // Reduced from 450
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -80,
            child: Image.asset(
              'assets/images/Ellipse2.png',
              width: 320, // Reduced from 500
              height: 320, // Reduced from 500
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.45),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'ඔබේ මූඩ් එක හොයාගමු', // Discover Your Vibe
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Color(0xFF1A1C22),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'සෙල්ෆියක් ගෙන ඔබේ මූඩ් එකට ගැළපෙන නියම ප්ලේලිස්ට් එක ලබාගන්න.', // Snap a selfie to uncover your mood and get the perfect playlist.
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Stack layout for overlapping the character on the right side
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // The Camera Card (Shifted slightly left to balance the screen)
                      Padding(
                        padding: const EdgeInsets.only(right: 50.0),
                        child: GestureDetector(
                          onTap: !_isScanning ? _showImageSourceDialog : null,
                          child: Container(
                            height: 280, // Taller card to match the proportions
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3F63FF,
                                  ).withOpacity(0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: _capturedImage != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.memory(
                                          _capturedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                        // Cool Neon Scanning Effect
                                        if (_isScanning)
                                          AnimatedBuilder(
                                            animation: _animation,
                                            builder: (context, child) =>
                                                Positioned(
                                                  top:
                                                      _animation.value *
                                                      (280 - 10),
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          const Color(
                                                            0xFF3F63FF,
                                                          ).withOpacity(0.0),
                                                          const Color(
                                                            0xFF3F63FF,
                                                          ).withOpacity(0.8),
                                                          const Color(
                                                            0xFF3F63FF,
                                                          ),
                                                        ],
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(
                                                            0xFF3F63FF,
                                                          ).withOpacity(0.6),
                                                          blurRadius: 18,
                                                          spreadRadius: 2,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                          ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF4F7FF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.camera_alt_rounded,
                                            size: 42,
                                            color: const Color(
                                              0xFF3F63FF,
                                            ).withOpacity(0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'ටැප් කර ෆොටෝවක් ගන්න', // Tap to snap
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF1A1C22),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // Lottie Animation placed further on the right side overlapping the card
                      Positioned(
                        right: -75, // Pushed further to the right edge
                        bottom: -10, // Adjust vertically so he looks grounded
                        child: IgnorePointer(
                          // Allows tapping the card underneath him
                          child: SizedBox(
                            height: 240,
                            child: Lottie.asset(
                              'assets/animations/Music (3).json',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _capturedImage != null && !_isScanning
                          ? _detectEmotion
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F63FF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD3D8E8),
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        elevation: _capturedImage != null ? 8 : 0,
                        shadowColor: const Color(0xFF3F63FF).withOpacity(0.5),
                      ),
                      child: _isScanning
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'ස්කෑන් වෙනවා...', // Scanning...
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _capturedImage == null
                                  ? 'මුලින්ම ෆොටෝ එකක් දාන්න'
                                  : 'මූඩ් එක බලන්න', // Add a photo first : Analyze Vibe
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
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
