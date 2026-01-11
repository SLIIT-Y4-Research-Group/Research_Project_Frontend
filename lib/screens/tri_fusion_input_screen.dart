import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';

import '../config/api_config.dart';

class TriFusionInputScreen extends StatefulWidget {
  const TriFusionInputScreen({super.key});

  @override
  State<TriFusionInputScreen> createState() => _TriFusionInputScreenState();
}

class _TriFusionInputScreenState extends State<TriFusionInputScreen> {
  final _textCtrl = TextEditingController();
  final _userIdCtrl = TextEditingController(text: "1");

  Uint8List? _imageBytes;
  String? _imageName;

  Uint8List? _audioBytes;
  String? _audioName;

  bool _loading = false;

  // ✅ Web mic record (4s)
  final AudioRecorder _record = AudioRecorder();
  bool _isRecording = false;
  int _secondsLeft = 4;
  Timer? _timer;

  @override
  void dispose() {
    _textCtrl.dispose();
    _userIdCtrl.dispose();
    _timer?.cancel();
    _record.dispose();
    super.dispose();
  }

  // ---------------- IMAGE PICK ----------------
  Future<void> _pickDrawing() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // IMPORTANT for web
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _imageBytes = file.bytes!;
      _imageName = file.name;
    });
  }

  // ---------------- AUDIO UPLOAD (OPTIONAL) ----------------
  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true, // IMPORTANT for web
      allowedExtensions: const ['wav', 'mp4', 'm4a', 'mp3', 'webm', 'ogg'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      // If user uploads audio, clear any recorded audio state
      _audioBytes = file.bytes!;
      _audioName = file.name;
      _isRecording = false;
      _timer?.cancel();
      _secondsLeft = 4;
    });
  }

  void _clearAudio() {
    setState(() {
      _audioBytes = null;
      _audioName = null;
      _isRecording = false;
      _timer?.cancel();
      _secondsLeft = 4;
    });
  }

  // ---------------- RECORD 4s ----------------
  Future<void> _startRecording4s() async {
    final ok = await _record.hasPermission();
    if (!ok) {
      _showMsg("Microphone permission denied.");
      return;
    }

    // If user records, clear uploaded audio first
    setState(() {
      _audioBytes = null;
      _audioName = null;
      _isRecording = true;
      _secondsLeft = 4;
    });

    // On web, the browser decides container/codec sometimes.
    // WAV may not always be truly WAV depending on browser support.
    // We'll still name it .wav, but backend should accept generic audio.
    await _record.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 16000,
      ),
      path: "voice_4s.wav", // required
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;

      setState(() => _secondsLeft--);

      if (_secondsLeft <= 0) {
        t.cancel();
        await _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _timer?.cancel();

    final pathOrUrl = await _record.stop();
    if (!mounted) return;

    setState(() => _isRecording = false);

    if (pathOrUrl == null) {
      _showMsg("Audio recording failed.");
      return;
    }

    // On Flutter Web, record returns a blob URL -> fetch it to get bytes
    try {
      final resp = await http.get(Uri.parse(pathOrUrl));
      if (resp.statusCode != 200) {
        _showMsg("Failed to read recorded audio bytes.");
        return;
      }

      setState(() {
        _audioBytes = resp.bodyBytes;
        _audioName = "voice_4s.wav";
      });
    } catch (e) {
      _showMsg("Error reading audio: $e");
    }
  }

  // ---------------- SUBMIT ----------------
  Future<void> _submit() async {
    if (_imageBytes == null) {
      _showMsg("Please upload the drawing image.");
      return;
    }
    if (_audioBytes == null) {
      _showMsg("Please record OR upload a voice file.");
      return;
    }
    if (_textCtrl.text.trim().isEmpty) {
      _showMsg("Please enter some text.");
      return;
    }

    setState(() => _loading = true);

    try {
      final req = http.MultipartRequest(
        "POST",
        Uri.parse(ApiConfig.triFusion),
      );

      req.fields["userId"] = _userIdCtrl.text.trim();
      req.fields["text"] = _textCtrl.text.trim();

      req.files.add(
        http.MultipartFile.fromBytes(
          "image",
          _imageBytes!,
          filename: _imageName ?? "drawing.jpg",
        ),
      );

      // send audio with whatever filename user recorded/uploaded
      req.files.add(
        http.MultipartFile.fromBytes(
          "audio",
          _audioBytes!,
          filename: _audioName ?? "voice.wav",
        ),
      );

      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        _showMsg("Backend error ${streamed.statusCode}:\n$body");
        return;
      }

      final jsonData = jsonDecode(body);
      final data = jsonData["data"] ?? {};
      await _showResultPopup(Map<String, dynamic>.from(data));
    } catch (e) {
      _showMsg("Request failed: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showResultPopup(Map<String, dynamic> data) async {
    final prediction = (data["prediction"] ?? "").toString().toLowerCase();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tri Fusion Result"),
        content: SingleChildScrollView(
          child: Text(const JsonEncoder.withIndent("  ").convert(data)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (prediction == "happy" || prediction == "happiness") {
                Navigator.pushReplacementNamed(context, "/tri_result_happy");
              } else {
                Navigator.pushReplacementNamed(context, "/tri_result_sad");
              }
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tri Fusion - Drawing + Voice + Text"),
        backgroundColor: const Color(0xFF4EAA57),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text(
                "Upload drawing + type text + (record 4s OR upload voice file).",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _userIdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "User ID",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _textCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Text (how you feel)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Drawing
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickDrawing,
                icon: const Icon(Icons.image),
                label: Text(
                  _imageBytes == null
                      ? "Upload Drawing Image"
                      : "Drawing Selected: ${_imageName ?? ''}",
                ),
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 180, // smaller -> faster UI
                  child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                ),
              ],

              const SizedBox(height: 16),

              // Voice controls (Record OR Upload)
              const Text(
                "Voice (choose one):",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_loading || _isRecording) ? null : _startRecording4s,
                      icon: const Icon(Icons.mic),
                      label: Text(_isRecording ? "Recording..." : "Record 4s"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4EAA57),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_isRecording)
                    Text(
                      "$_secondsLeft s",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: _loading ? null : _pickAudioFile,
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload Voice File (wav/mp4/etc)"),
              ),

              if (_audioBytes != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Text("✅ Audio ready: ${_audioName ?? 'voice'}")),
                    TextButton(
                      onPressed: _loading ? null : _clearAudio,
                      child: const Text("Clear"),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Submit to Tri Fusion"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
