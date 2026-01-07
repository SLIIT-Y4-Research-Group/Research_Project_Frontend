import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
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
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _capturedImage = bytes);
    }
  }

  Future<void> _detectEmotion() async {
    if (_capturedImage == null) return;

    setState(() => _isScanning = true);
    _animationController.repeat();

    try {
      // Convert image to base64
      String base64Image = base64Encode(_capturedImage!);

      // Call backend API
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

        // Show choice dialog with the results
        _showNavigationChoiceDialog(detectedEmotion, happyFaceImage, isHappy);
      } else {
        _showErrorDialog('Failed to analyze emotion: ${response.statusCode}');
      }
    } catch (e) {
      _animationController.stop();
      setState(() => _isScanning = false);
      _showErrorDialog('Error connecting to server: $e');
    }
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

  void _showNavigationChoiceDialog(
    String detectedEmotion,
    Uint8List? happyFaceImage,
    bool isHappy,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.face, size: 50, color: Colors.purple),
            const SizedBox(height: 10),
            const Text(
              'මනෝභාවය හඳුනාගන්නා ලදී!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                detectedEmotion.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ඔබට කුමක් කිරීමට අවශ්‍යද?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          Column(
            children: [
              // Music Recommendation Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MusicRecommendationScreen(emotion: detectedEmotion),
                      ),
                    );
                  },
                  icon: const Icon(Icons.music_note),
                  label: const Text('සංගීත නිර්දේශ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Emotion Puzzle Button (only show if we have a happy face image)
              if (happyFaceImage != null)
                SizedBox(
                  width: double.infinity,
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
                    icon: const Icon(Icons.extension),
                    label: const Text('මනෝභාව ප්‍රහේලිකාව'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              // Cancel Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('අවලංගු කරන්න'),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'මනෝභාවය පරීක්ෂා කිරීම',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      // මෙහිදී body එක පුරාම පැතිරෙන සේ Stack එක සකසා ඇත
      body: SizedBox.expand(
        child: Stack(
          children: [
            // --- පසුබිම් මෝස්තර: හිස් ඉඩ පිරවීමට උපරිම ලෙස විශාල කර ඇත ---

            // ඉහළ දකුණු පස සිට මැදට විහිදෙන විශාල Ellipse එකක්
            Positioned(
              top: -80,
              right: -120,
              child: Image.asset(
                'assets/images/Ellipse1.png',
                width: 450, // ඉතා විශාල කර ඇත
                height: 450,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.35),
              ),
            ),

            // පහළ වම් පස සිට මැදට විහිදෙන විශාල Ellipse එකක්
            Positioned(
              bottom: -100,
              left: -130,
              child: Image.asset(
                'assets/images/Ellipse2.png',
                width: 500, // ඉතා විශාල කර ඇත
                height: 500,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.45),
              ),
            ),

            // ප්‍රධාන අන්තර්ගතය
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          const Text(
                            'ඔබේ මුහුණ පරීක්ෂා කරමු',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'කැමරාව දෙස බලා ඔබේ සිනහව පෙන්වන්න',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Image Box
                          Container(
                            width: 320,
                            height: 400,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(35),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: _capturedImage != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(35),
                                        child: Image.memory(
                                          _capturedImage!,
                                          width: 320,
                                          height: 400,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      if (_isScanning)
                                        AnimatedBuilder(
                                          animation: _animation,
                                          builder: (context, child) =>
                                              Positioned(
                                                top: _animation.value * 370,
                                                left: 20,
                                                right: 20,
                                                child: Container(
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF4EAA57,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                          0xFF4EAA57,
                                                        ).withOpacity(0.8),
                                                        blurRadius: 15,
                                                        spreadRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                        ),
                                    ],
                                  )
                                : InkWell(
                                    onTap: _openCamera,
                                    borderRadius: BorderRadius.circular(35),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 80,
                                          color: const Color(
                                            0xFF4EAA57,
                                          ).withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'ඡායාරූපයක් ගැනීමට තට්ටු කරන්න',
                                          style: TextStyle(
                                            color: Colors.black45,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // පහළ බොත්තම - Footer එකට ඉහළින් ස්ථාවරව තබා ඇත
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 30),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _capturedImage != null && !_isScanning
                            ? _detectEmotion
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4EAA57),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: _isScanning
                            ? const SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'මනෝභාවය හඳුනාගන්න',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
