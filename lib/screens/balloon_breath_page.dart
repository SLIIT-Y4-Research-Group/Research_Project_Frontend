import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const MaterialApp(home: BalloonBreathPage()));

enum BreathPhase { inhale, hold, exhale }

class BalloonBreathPage extends StatefulWidget {
  const BalloonBreathPage({super.key});

  @override
  State<BalloonBreathPage> createState() => _BalloonBreathPageState();
}

class _BalloonBreathPageState extends State<BalloonBreathPage>
    with SingleTickerProviderStateMixin {
  static const int secondsPerPhase = 4;

  late final AnimationController _controller;
  late final Animation<double> _scale;

  BreathPhase _phase = BreathPhase.inhale;
  int _remaining = secondsPerPhase;

  Timer? _timer;

  // Balloon size tuning
  static const double minScale = 0.75;
  static const double maxScale = 1.25;

  bool _running = false;

  // Audio
  final AudioPlayer _player = AudioPlayer();
  BreathPhase? _lastPlayedPhase;
  bool _voiceEnabled = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: secondsPerPhase),
    );

    _scale = Tween<double>(begin: minScale, end: maxScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start in inhale position (small balloon)
    _controller.value = 0.0;

    // Optional: set player mode (keeps behavior consistent across platforms)
    _player.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  String _phaseLabel(BreathPhase p) {
    switch (p) {
      case BreathPhase.inhale:
        return "හුස්ම ආශ්වාස කරන්න";
      case BreathPhase.hold:
        return "හුස්ම රඳවන්න";
      case BreathPhase.exhale:
        return "හුස්ම ප්‍රශ්වාස කරන්න";
    }
  }

  /// Ensure you have these files:
  /// assets/audio/inhale.mp3
  /// assets/audio/hold.mp3
  /// assets/audio/exhale.mp3
  String _phaseAudioAsset(BreathPhase p) {
    switch (p) {
      case BreathPhase.inhale:
        return "audio/inhale.mp3";
      case BreathPhase.hold:
        return "audio/hold.mp3";
      case BreathPhase.exhale:
        return "audio/exhale.mp3";
    }
  }

  Future<void> _playPhaseVoice(BreathPhase phase) async {
    if (!_voiceEnabled) return;

    // only play when phase changes
    if (_lastPlayedPhase == phase) return;
    _lastPlayedPhase = phase;

    try {
      await _player.stop();
      await _player.play(AssetSource(_phaseAudioAsset(phase)));
    } catch (_) {
      // If audio fails (missing asset / pubspec not configured), fail silently
      // You can debug by checking console logs in debug mode.
    }
  }

  void _start() {
    if (_running) return;

    setState(() {
      _running = true;
      _phase = BreathPhase.inhale;
      _remaining = secondsPerPhase;
    });

    _lastPlayedPhase = null; // allow inhale voice to play again
    _playPhaseVoice(_phase);

    // Begin inhale (scale up)
    _controller
      ..duration = const Duration(seconds: secondsPerPhase)
      ..forward(from: 0.0);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _pause() {
    if (!_running) return;
    setState(() => _running = false);
    _timer?.cancel();
    _controller.stop();
    _player.stop();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _phase = BreathPhase.inhale;
      _remaining = secondsPerPhase;
      _lastPlayedPhase = null;
    });
    _controller.value = 0.0; // back to small
    _player.stop();
  }

  void _tick() {
    if (!_running) return;

    setState(() {
      _remaining -= 1;
    });

    if (_remaining > 0) return;

    // Move to next phase
    switch (_phase) {
      case BreathPhase.inhale:
        // HOLD: keep balloon big for 4s, stop animation at end (big)
        setState(() {
          _phase = BreathPhase.hold;
          _remaining = secondsPerPhase;
        });
        _controller
          ..stop()
          ..value = 1.0; // ensure max
        _playPhaseVoice(_phase);
        break;

      case BreathPhase.hold:
        // EXHALE: animate down for 4s
        setState(() {
          _phase = BreathPhase.exhale;
          _remaining = secondsPerPhase;
        });
        _controller
          ..duration = const Duration(seconds: secondsPerPhase)
          ..reverse(from: 1.0);
        _playPhaseVoice(_phase);
        break;

      case BreathPhase.exhale:
        // Loop back to INHALE
        setState(() {
          _phase = BreathPhase.inhale;
          _remaining = secondsPerPhase;
        });
        _controller
          ..duration = const Duration(seconds: secondsPerPhase)
          ..forward(from: 0.0);
        _playPhaseVoice(_phase);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _phaseLabel(_phase);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Balloon Breath"),
        actions: [
          IconButton(
            tooltip: _voiceEnabled ? "Voice: On" : "Voice: Off",
            icon: Icon(_voiceEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () async {
              setState(() => _voiceEnabled = !_voiceEnabled);
              if (!_voiceEnabled) {
                await _player.stop();
              } else {
                // speak immediately when turning on (optional)
                _lastPlayedPhase = null;
                await _playPhaseVoice(_phase);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "$_remaining s",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 32),

              // Balloon
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFB3E5FC), Color(0xFF0288D1)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            spreadRadius: 2,
                            color: Colors.black.withOpacity(0.15),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.air, size: 46, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _running ? null : _start,
                    child: const Text("ආරම්භ කරන්න"),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _running ? _pause : null,
                    child: const Text("විරාම කරන්න"),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _reset,
                    child: const Text("අවසන් කරන්න"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _voiceEnabled ? "හඬ සක්‍රියයි" : "හඬ අක්‍රියයි",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}