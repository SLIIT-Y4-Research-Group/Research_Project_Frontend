import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../widgets/child_bottom_nav_bar.dart';

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

  static const double minScale = 0.75;
  static const double maxScale = 1.25;

  bool _running = false;

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

    _controller.value = 0.0;
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

    if (_lastPlayedPhase == phase) return;
    _lastPlayedPhase = phase;

    try {
      await _player.stop();
      await _player.play(AssetSource(_phaseAudioAsset(phase)));
    } catch (_) {}
  }

  void _start() {
    if (_running) return;

    setState(() {
      _running = true;
      _phase = BreathPhase.inhale;
      _remaining = secondsPerPhase;
    });

    _lastPlayedPhase = null;
    _playPhaseVoice(_phase);

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

    _controller.value = 0.0;
    _player.stop();
  }

  void _tick() {
    if (!_running) return;

    setState(() {
      _remaining -= 1;
    });

    if (_remaining > 0) return;

    switch (_phase) {
      case BreathPhase.inhale:
        setState(() {
          _phase = BreathPhase.hold;
          _remaining = secondsPerPhase;
        });

        _controller
          ..stop()
          ..value = 1.0;

        _playPhaseVoice(_phase);
        break;

      case BreathPhase.hold:
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
        backgroundColor: const Color(0xFF4EAA57),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _voiceEnabled ? "Voice: On" : "Voice: Off",
            icon: Icon(_voiceEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () async {
              setState(() => _voiceEnabled = !_voiceEnabled);

              if (!_voiceEnabled) {
                await _player.stop();
              } else {
                _lastPlayedPhase = null;
                await _playPhaseVoice(_phase);
              }
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$_remaining s",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 32),
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
                              colors: [
                                Color(0xFFB3E5FC),
                                Color(0xFF0288D1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 18,
                                spreadRadius: 2,
                                color: Colors.black.withValues(alpha: 0.15),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.air,
                              size: 46,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton(
                        onPressed: _running ? null : _start,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4EAA57),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text("ආරම්භ කරන්න"),
                      ),
                      OutlinedButton(
                        onPressed: _running ? _pause : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4EAA57),
                          side: const BorderSide(
                            color: Color(0xFF4EAA57),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text("විරාම කරන්න"),
                      ),
                      TextButton(
                        onPressed: _reset,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                        child: const Text("අවසන් කරන්න"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _voiceEnabled ? "හඬ සක්‍රියයි" : "හඬ අක්‍රියයි",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}