import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../config/api_config.dart';
import '../models/validate_answer_response.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../widgets/listening_indicator.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/mood_badge.dart';
import 'mood_result_screen.dart';
import 'welcome_screen.dart';

class Question {
  final String text;
  String answer;
  String mood;
  bool loadingMood;
  bool skipped;

  Question(this.text)
      : answer = "",
        mood = "",
        loadingMood = false,
        skipped = false;
}

class MoodHome extends StatefulWidget {
  const MoodHome({super.key});

  @override
  State<MoodHome> createState() => _MoodHomeState();
}

class _MoodHomeState extends State<MoodHome> {
  final stt.SpeechToText speech = stt.SpeechToText();
  final TextEditingController _transcriptController = TextEditingController();
  final AuthService _authService = AuthService();

  bool listening = false;
  bool isSpeechAvailable = false;
  int currentQuestionIndex = 0;

  String liveTranscript = "";
  String mood = "";
  bool loadingMood = false;

  // Speech state
  String _accumulatedTranscript = "";
  String _finalTranscript = "";
  String _currentPartialTranscript = "";
  bool _manuallyStopped = false;
  bool _isRestartingSafely = false;
  Timer? _speechWatchdogTimer;
  DateTime? _lastSpeechResultAt;

  // Consent state (only for child users)
  bool _isChildUser = false;
  bool _alertsConsent = false;
  bool _loadingConsent = false;
  String _childName = "";

  late List<Question> questions;

  final String apiUrl = ApiConfig.PREDICT_ENDPOINT;
  final String overallUrl = ApiConfig.PREDICT_OVERALL_ENDPOINT;
  final String validateUrl = ApiConfig.VALIDATE_ANSWER_ENDPOINT;
  final String predictQuestionUrl = ApiConfig.PREDICT_QUESTION_ENDPOINT;

  @override
  void initState() {
    super.initState();
    questions = [
      Question(" අද ඉස්කෝලේ ගත කරපු කාලය ගැන ඔයාට මොකද හිතෙන්නේ? "),
      Question(" අද ඉස්කෝලේ ගුරුවරු එක්ක හරි යාළුවො එක්ක හරි ප්‍රශ්නයක් ඇතිවුණාද?"),
      Question(" අද පාඩම් වැඩ, homework හරි exam හරි නිසා ඔයා stress වෙලාද ඉන්නෙ?"),
      Question(" අද ඔයාට හුඟාක් මහන්සිද? අද විවේකයක් නැතිවම ද හිටියේ?"),
      Question(" අද ඔයාට සතුටු වෙන්න පුළුවන් මොකක් හරි හේතුවක් තියෙනවද?"),
    ];
    _initSpeech();
    _checkUserTypeAndLoadConsent();
    _checkAndAlertIfAlreadyCompleted();
  }

  Future<void> _checkAndAlertIfAlreadyCompleted() async {
    try {
      final response = await ApiClient.getTodayMoodStatus();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['completed'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ඔයා අද mood check එක කරලා ඉවරයි!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('[MOOD] Error checking completion status: $e');
    }
  }

  Future<void> _checkUserTypeAndLoadConsent() async {
    final isChild = await _authService.isChild();
    setState(() => _isChildUser = isChild);

    if (isChild) {
      _loadChildConsent();
    }
  }

  Future<void> _loadChildConsent() async {
    try {
      final response = await ApiClient.getChildInfo();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _alertsConsent = data['alerts_consent'] ?? false;
          _childName = data['name'] ?? "";
        });
      }
    } catch (e) {
      debugPrint('Error loading consent: $e');
    }
  }

  Future<void> _updateConsent(bool value) async {
    setState(() => _loadingConsent = true);

    try {
      final response = await ApiClient.updateChildConsent(value);
      if (response.statusCode == 200) {
        setState(() => _alertsConsent = value);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(value ? 'Alert emails enabled' : 'Alert emails disabled'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update consent')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _loadingConsent = false);
    }
  }

  void _showConsentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Allow guardian to receive alert emails about your mood',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Alert Emails'),
              value: _alertsConsent,
              onChanged: _loadingConsent
                  ? null
                  : (value) {
                      Navigator.pop(context);
                      _updateConsent(value);
                    },
              activeColor: const Color(0xFF22C55E),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAlertPermissionDialog({required int badMoodCount}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/Hand with love.json',
                height: 110,
                repeat: true,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                _childName.isNotEmpty
                    ? '$_childName, අපිට පේනවා පහුගිය දවස් ටිකේ ඔයා ටිකක් දුකෙන් හිටියා වගේ.'
                    : 'අපිට පේනවා පහුගිය දවස් ටිකේ ඔයා ටිකක් දුකෙන් හිටියා වගේ.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ඔයා කැමතිනම්, මේ ගැන ඔයාගේ දෙමව්පියන්ට හරි විශ්වාසවන්ත පුද්ගලයකුට හරි දැනුම් දෙන්න පුළුවන්.\nඑතකොට එයාලට ඔයාට උදව් කරන්න පුළුවන්.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ඔයා ඒකට අවසර දෙනවද?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'නැහැ, දැන් එපා',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                try {
                  await ApiClient.respondAlertPermission(approve: false);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('හරි, අපි දැනුම්දීමක් එවන්නේ නැහැ'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.grey,
                      ),
                    );
                  }
                } catch (e) {
                  print("[MOOD] Error sending decline response: $e");
                }
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'ඔව්, දන්වන්න',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                try {
                  final response = await ApiClient.respondAlertPermission(approve: true);

                  if (response.statusCode == 200 || response.statusCode == 201) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ඔබේ භාරකරුට දැනුම්දීම යවන ලදී '),
                          duration: Duration(seconds: 3),
                          backgroundColor: Color(0xFF22C55E),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('දැනුම්දීම යැවීමේ දෝෂයක්: ${response.statusCode}'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('දැනුම්දීම යැවීමේ දෝෂයක්'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  String _buildCombinedTranscript() {
    final finalText = _accumulatedTranscript.trim();
    final partialText = _currentPartialTranscript.trim();

    if (finalText.isEmpty && partialText.isEmpty) return "";
    if (finalText.isEmpty) return partialText;
    if (partialText.isEmpty) return finalText;

    if (partialText.startsWith(finalText)) {
      return partialText;
    }

    return "$finalText $partialText".trim();
  }

  void _syncTranscriptToUi(String text) {
    liveTranscript = text;
    _transcriptController.text = text;
    _transcriptController.selection = TextSelection.fromPosition(
      TextPosition(offset: _transcriptController.text.length),
    );
    questions[currentQuestionIndex].answer = text;
    questions[currentQuestionIndex].skipped = false;
  }

  void _startSpeechWatchdog() {
    _speechWatchdogTimer?.cancel();
    _lastSpeechResultAt = DateTime.now();

    _speechWatchdogTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (!mounted || !listening || _manuallyStopped || _isRestartingSafely) {
        return;
      }

      final lastAt = _lastSpeechResultAt;
      if (lastAt == null) return;

      final diff = DateTime.now().difference(lastAt);

      if (diff.inMilliseconds > 7000) {
        debugPrint("Speech watchdog: no results for ${diff.inMilliseconds}ms");
        await _safeRestartListening();
      }
    });
  }

  void _stopSpeechWatchdog() {
    _speechWatchdogTimer?.cancel();
    _speechWatchdogTimer = null;
  }

  Future<String?> _resolveSpeechLocaleId() async {
    try {
      final locales = await speech.locales();
      if (locales.isEmpty) return null;

      final exact = locales.where((l) => l.localeId == "si_LK").toList();
      if (exact.isNotEmpty) {
        return exact.first.localeId;
      }

      final exactDash = locales.where((l) => l.localeId == "si-LK").toList();
      if (exactDash.isNotEmpty) {
        return exactDash.first.localeId;
      }

      final fallback = locales.where((l) {
        final id = l.localeId.toLowerCase();
        return id.contains("si");
      }).toList();

      if (fallback.isNotEmpty) {
        return fallback.first.localeId;
      }
    } catch (e) {
      debugPrint("Speech locale lookup error: $e");
    }

    return null;
  }

  Future<bool> _tryStartListening(
    String? localeId, {
    required Duration pauseFor,
    required Duration listenFor,
  }) async {
    try {
      await speech.listen(
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
        pauseFor: pauseFor,
        listenFor: listenFor,
        onResult: (result) {
          _lastSpeechResultAt = DateTime.now();

          final recognized = result.recognizedWords.trim();
          if (recognized.isEmpty) return;

          if (result.finalResult) {
            final currentDisplay = _buildCombinedTranscript();

            if (_accumulatedTranscript.isEmpty) {
              _accumulatedTranscript = recognized;
            } else if (recognized.startsWith(_accumulatedTranscript)) {
              _accumulatedTranscript = recognized;
            } else if (currentDisplay.startsWith(_accumulatedTranscript) &&
                recognized.startsWith(_currentPartialTranscript)) {
              _accumulatedTranscript = currentDisplay;
            } else if (!_accumulatedTranscript.endsWith(recognized)) {
              _accumulatedTranscript = "$_accumulatedTranscript $recognized".trim();
            }

            _finalTranscript = _accumulatedTranscript;
            _currentPartialTranscript = "";
          } else {
            _currentPartialTranscript = recognized;
          }

          final displayText = _buildCombinedTranscript();

          if (mounted) {
            setState(() {
              _syncTranscriptToUi(displayText);
            });
          }
        },
      );
      return true;
    } catch (e) {
      debugPrint("Speech listen error (localeId: $localeId): $e");
      return false;
    }
  }

  Future<void> _safeRestartListening() async {
    if (_isRestartingSafely || _manuallyStopped || !mounted) return;

    _isRestartingSafely = true;

    try {
      debugPrint("SAFE RESTART...");

      final currentText = _buildCombinedTranscript();
      if (currentText.isNotEmpty) {
        _accumulatedTranscript = currentText;
        _finalTranscript = currentText;
        _currentPartialTranscript = "";
        if (mounted) {
          setState(() {
            _syncTranscriptToUi(currentText);
          });
        }
      }

      await speech.cancel();
      await Future.delayed(const Duration(milliseconds: 500));

      if (!_manuallyStopped && mounted) {
        await startListening(restart: true);
      }
    } catch (e) {
      debugPrint("Safe restart error: $e");
    } finally {
      _isRestartingSafely = false;
    }
  }

  Future<void> _initSpeech() async {
    var status = await Permission.microphone.request();

    if (!status.isGranted) {
      setState(() {
        mood = "Microphone permission denied. Please enable it in settings.";
        isSpeechAvailable = false;
      });
      return;
    }

    isSpeechAvailable = await speech.initialize(
      onStatus: (status) async {
        debugPrint("Speech status: $status");

        if (status == "listening") {
          _lastSpeechResultAt = DateTime.now();
          if (mounted) {
            setState(() => listening = true);
          }
          return;
        }

        if (status == "notListening" || status == "done") {
          if (_manuallyStopped) {
            _stopSpeechWatchdog();
            if (mounted) {
              setState(() => listening = false);
            }
            return;
          }

          if (!listening || !mounted) {
            debugPrint("Speech auto-stop ignored (listening=$listening)");
            return;
          }

          if (!_isRestartingSafely) {
            debugPrint("Speech auto-stop detected, restarting...");
          }

          await Future.delayed(const Duration(milliseconds: 400));
          await _safeRestartListening();
        }
      },
      onError: (error) async {
        debugPrint("Speech error: ${error.errorMsg}");

        if (_manuallyStopped) return;

        await _safeRestartListening();
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> startListening({bool restart = false}) async {
    if (!isSpeechAvailable) {
      setState(() => mood = "Speech recognition not available");
      return;
    }

    if (!restart && _isRestartingSafely) return;

    if (!restart) {
      _accumulatedTranscript = questions[currentQuestionIndex].answer.trim();
      _finalTranscript = _accumulatedTranscript;
      _currentPartialTranscript = "";
    }

    _manuallyStopped = false;
    _lastSpeechResultAt = DateTime.now();

    if (mounted) {
      setState(() {
        listening = true;
        mood = "";
        _syncTranscriptToUi(_accumulatedTranscript);
      });
    }

    _startSpeechWatchdog();

    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final pauseDuration = isMobile
        ? const Duration(seconds: 10)
        : const Duration(seconds: 5);
    final listenDuration = isMobile
        ? const Duration(minutes: 2)
        : const Duration(minutes: 1);

    final localeId = await _resolveSpeechLocaleId();
    final preferredLocale = localeId ?? "si_LK";
    final startedPreferred = await _tryStartListening(
      preferredLocale,
      pauseFor: pauseDuration,
      listenFor: listenDuration,
    );
    if (startedPreferred) return;

    if (preferredLocale != "si_LK") {
      final startedSi = await _tryStartListening(
        "si_LK",
        pauseFor: pauseDuration,
        listenFor: listenDuration,
      );
      if (startedSi) return;
    }

    await _tryStartListening(
      null,
      pauseFor: pauseDuration,
      listenFor: listenDuration,
    );
  }

  Future<void> stopListening() async {
    _manuallyStopped = true;
    _stopSpeechWatchdog();

    await speech.stop();

    final finalText = _buildCombinedTranscript().trim();

    if (mounted) {
      setState(() {
        listening = false;
        _currentPartialTranscript = "";
        _accumulatedTranscript = finalText;
        _finalTranscript = finalText;
        _syncTranscriptToUi(finalText);
      });
    }
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        final saved = questions[currentQuestionIndex].answer;
        liveTranscript = saved;
        _transcriptController.text = saved;
        _accumulatedTranscript = saved;
        _finalTranscript = saved;
        _currentPartialTranscript = "";
      });
    }
  }

  void handleSkipQuestion() {
    if (currentQuestionIndex == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("පළමු ප්‍රශ්නය මග හැරිය නොහැක. කරුණාකර පිළිතුරු දෙන්න."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool isLastQuestion = currentQuestionIndex == questions.length - 1;

    if (isLastQuestion) {
      int answeredCount = 0;
      for (int i = 0; i < questions.length - 1; i++) {
        if (!questions[i].skipped && questions[i].answer.trim().isNotEmpty) {
          answeredCount++;
        }
      }

      if (answeredCount < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("අද දවසේ ඔයාගේ mood එක බලන්න අඩුම ප්‍රශ්න 3කට උත්තර දෙන්න."),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        questions[currentQuestionIndex].skipped = true;
        questions[currentQuestionIndex].answer = "";
        questions[currentQuestionIndex].mood = "";
        liveTranscript = "";
        _accumulatedTranscript = "";
        _finalTranscript = "";
        _currentPartialTranscript = "";
        _transcriptController.clear();
      });
      submitAllAnswers();
      return;
    }

    setState(() {
      questions[currentQuestionIndex].skipped = true;
      questions[currentQuestionIndex].answer = "";
      questions[currentQuestionIndex].mood = "";
      liveTranscript = "";
      _accumulatedTranscript = "";
      _finalTranscript = "";
      _currentPartialTranscript = "";
      _transcriptController.clear();
    });
    nextQuestion();
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        final saved = questions[currentQuestionIndex].answer;
        liveTranscript = saved;
        _transcriptController.text = saved;
        _accumulatedTranscript = saved;
        _finalTranscript = saved;
        _currentPartialTranscript = "";
      });
    }
  }

  void retakeAnswer() {
    setState(() {
      questions[currentQuestionIndex].answer = "";
      questions[currentQuestionIndex].mood = "";
      questions[currentQuestionIndex].skipped = false;
      liveTranscript = "";
      _accumulatedTranscript = "";
      _finalTranscript = "";
      _currentPartialTranscript = "";
      _transcriptController.clear();
    });
  }

  Future<void> checkQuestionMood(int questionIndex) async {
    debugPrint("checkQuestionMood called for question $questionIndex");

    final question = questions[questionIndex];
    final questionId = questionIndex + 1;

    if (question.answer.trim().isEmpty) {
      debugPrint(" Answer is empty");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("කරුණාකර මුලින්ම ප්‍රශ්නයට පිළිතුරු දෙන්න"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      questions[questionIndex].loadingMood = true;
      questions[questionIndex].mood = "";
    });

    final validation = await validateAnswer(questionId, question.answer.trim());
    debugPrint(" Validation status: ${validation?.status ?? 'null'} (normalized: ${validation?.statusNormalized ?? 'null'})");

    if (validation == null) {
      setState(() {
        questions[questionIndex].loadingMood = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Validation failed. Please try again."),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (validation.isEmpty) {
      setState(() {
        questions[questionIndex].loadingMood = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("කරුණාකර උත්තරයක් ලබා දෙන්න."),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (validation.needsMoreInfo) {
      setState(() {
        questions[questionIndex].loadingMood = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ටිකක් විස්තර කරලා කියන්න පුළුවන්ද?"),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (validation.isIrrelevant) {
      setState(() {
        questions[questionIndex].loadingMood = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ඔයාගේ උත්තරේ ප්‍රශ්නයට සම්බන්ධ නැහැ වගේ. ටිකක් විස්තර කරලා කියන්න."),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (validation.isYesNoAnswer) {
      final answerText = validation.normalized.isNotEmpty
          ? validation.normalized.toLowerCase()
          : question.answer.trim().toLowerCase();

      final isYes = answerText.contains('ඔව්') ||
          answerText.contains('yes') ||
          answerText == 'ඔව්' ||
          answerText == 'yes';

      String mood;
      if (questionId == 5) {
        mood = isYes ? "සතුටුයි" : "සාමාන්‍ය";
      } else {
        mood = isYes ? "දුකයි / හොඳ නෑ" : "සතුටුයි";
      }

      setState(() {
        questions[questionIndex].mood = mood;
        questions[questionIndex].loadingMood = false;
      });
      return;
    }

    if (validation.isQ1DirectMood) {
      String moodLabel;
      final directMood = validation.directMood?.toLowerCase() ?? '';

      if (directMood.contains('happy')) {
        moodLabel = "සතුටුයි";
      } else if (directMood.contains('normal')) {
        moodLabel = "සාමාන්‍ය";
      } else if (directMood.contains('bad')) {
        moodLabel = "දුකයි / හොඳ නෑ";
      } else {
        moodLabel = validation.directMood ?? "සාමාන්‍ය";
      }

      setState(() {
        if (validation.normalized.isNotEmpty) {
          questions[questionIndex].answer = validation.normalized;
        }
        questions[questionIndex].mood = moodLabel;
        questions[questionIndex].loadingMood = false;
      });
      return;
    }

    if (validation.isNeutralPhrase) {
      setState(() {
        if (validation.normalized.isNotEmpty) {
          questions[questionIndex].answer = validation.normalized;
        }
        questions[questionIndex].mood = "Normal / සාමාන්‍ය";
        questions[questionIndex].loadingMood = false;
      });
      return;
    }

    if (validation.isValidText) {
      try {
        final res = await http.post(
          Uri.parse(predictQuestionUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"question_id": questionId, "text": question.answer}),
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            questions[questionIndex].mood = data["mood"]?.toString() ?? "No mood";
          });
        } else {
          setState(() {
            questions[questionIndex].mood = "Error: ${res.statusCode}";
          });
        }
      } catch (e) {
        setState(() {
          questions[questionIndex].mood =
              "Connection Error: $e\n\nCheck:\n- Backend running?\n- Same WiFi?\n- IP: ${ApiConfig.baseUrl}";
        });
      } finally {
        setState(() {
          questions[questionIndex].loadingMood = false;
        });
      }
      return;
    }

    setState(() {
      questions[questionIndex].loadingMood = false;
    });
  }

  Future<ValidateAnswerResponse?> validateAnswer(int questionId, String text) async {
    try {
      final res = await http.post(
        Uri.parse(validateUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question_id": questionId, "text": text}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ValidateAnswerResponse.fromJson(data);
      } else {
        setState(() {
          mood = "Validation error: ${res.statusCode}";
        });
        return null;
      }
    } catch (e) {
      setState(() {
        mood = "Validation connection error: $e";
      });
      return null;
    }
  }

  Future<void> handleNextQuestion() async {
    final currentAnswer = questions[currentQuestionIndex].answer.trim();

    final validation = await validateAnswer(currentQuestionIndex + 1, currentAnswer);

    if (validation == null) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("වලංගු කිරීමේ දෝෂයක්"),
          content: const Text("ඔබේ පිළිතුර වලංගු කිරීමට නොහැකි විය. කෙසේ වුවද ඉදිරියට යන්නද?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("නැත"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("ඔව්"),
            ),
          ],
        ),
      );

      if (shouldContinue == true) {
        nextQuestion();
      }
      return;
    }

    if (validation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("කරුණාකර උත්තරයක් ලබා දෙන්න."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (validation.needsMoreInfo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ටිකක් විස්තර කරලා කියන්න පුළුවන්ද?"),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (validation.isIrrelevant) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ඔයාගේ උත්තරේ ප්‍රශ්නයට සම්බන්ධ නැහැ වගේ. ටිකක් විස්තර කරලා කියන්න."),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (validation.isYesNoAnswer) {
      final answerText = validation.normalized.isNotEmpty
          ? validation.normalized.toLowerCase()
          : questions[currentQuestionIndex].answer.trim().toLowerCase();

      final isYes = answerText.contains('ඔව්') ||
          answerText.contains('yes') ||
          answerText == 'ඔව්' ||
          answerText == 'yes';

      final questionId = currentQuestionIndex + 1;
      String mood;
      if (questionId == 5) {
        mood = isYes ? "සතුටුයි" : "සාමාන්‍ය";
      } else {
        mood = isYes ? "දුකයි / හොඳ නෑ" : "සතුටුයි";
      }

      setState(() {
        if (validation.normalized.isNotEmpty) {
          questions[currentQuestionIndex].answer = validation.normalized;
          questions[currentQuestionIndex].skipped = false;
        }
        questions[currentQuestionIndex].mood = mood;
      });
      nextQuestion();
      return;
    }

    if (validation.isQ1DirectMood) {
      String moodLabel;
      final directMood = validation.directMood?.toLowerCase() ?? '';

      if (directMood.contains('happy')) {
        moodLabel = "සතුටුයි";
      } else if (directMood.contains('normal')) {
        moodLabel = "සාමාන්‍ය";
      } else if (directMood.contains('bad')) {
        moodLabel = "දුකයි / හොඳ නෑ";
      } else {
        moodLabel = validation.directMood ?? "සාමාන්‍ය";
      }

      setState(() {
        if (validation.normalized.isNotEmpty) {
          questions[currentQuestionIndex].answer = validation.normalized;
          questions[currentQuestionIndex].skipped = false;
        }
        questions[currentQuestionIndex].mood = moodLabel;
      });
      nextQuestion();
      return;
    }

    if (validation.isNeutralPhrase) {
      setState(() {
        if (validation.normalized.isNotEmpty) {
          questions[currentQuestionIndex].answer = validation.normalized;
          questions[currentQuestionIndex].skipped = false;
        }
        questions[currentQuestionIndex].mood = "Normal / සාමාන්‍ය";
      });
      nextQuestion();
      return;
    }

    if (validation.isValidText) {
      nextQuestion();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Unknown validation status: ${validation.status}"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isYesNoAnswer(String answer) {
    final lower = answer.toLowerCase().trim();
    return lower == 'ඔව්' ||
        lower == 'නෑ' ||
        lower == 'නැහැ' ||
        lower == 'yes' ||
        lower == 'no' ||
        lower == 'ok' ||
        lower == 'ow' ||
        lower == 'naa' ||
        lower == 'නෑ';
  }

  bool _isYesAnswer(String answer) {
    final lower = answer.toLowerCase().trim();
    return lower == 'ඔව්' || lower == 'yes' || lower == 'ok' || lower == 'ow';
  }

  String _convertYesNoToSentence(int questionId, String answer) {
    final isYes = _isYesAnswer(answer);

    switch (questionId) {
      case 2:
        return isYes
            ? "අද මට ගුරුවරු හෝ යාළුවන් සමඟ ප්‍රශ්නයක් තිබුණා"
            : "අද මට ගුරුවරු හෝ යාළුවන් සමඟ ප්‍රශ්නයක් නැහැ";
      case 3:
        return isYes
            ? "අද පාඩම්, homework හෝ exam නිසා මට ආතතිය තිබුණා"
            : "අද පාඩම්, homework හෝ exam නිසා මට ආතතියක් නැහැ";
      case 4:
        return isYes
            ? "අද මට හුඟක් මහන්සි වුණා සහ විවේකයක් අඩු වුණා"
            : "අද මට මහන්සි අඩුයි සහ විවේකයක් තිබුණා";
      case 5:
        return isYes
            ? "අද මට සතුටු වෙන්න හේතුවක් තිබුණා"
            : "අද මට සතුටු වෙන්න විශේෂ හේතුවක් නැහැ";
      default:
        return answer;
    }
  }

  Future<void> submitAllAnswers() async {
    if (questions[0].answer.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("කරුණාකර පළමු ප්‍රශ්නයට පිළිතුරු දෙන්න."),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int answeredCount = 0;
    for (int i = 0; i < questions.length; i++) {
      if (!questions[i].skipped && questions[i].answer.trim().isNotEmpty) {
        answeredCount++;
      }
    }

    if (answeredCount < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("අවසාන ප්‍රතිඵලය ලබාගන්න, පළමු ප්‍රශ්නයට සහ තවත් ප්‍රශ්න 2කටවත් පිළිතුරු දෙන්න."),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final answers = <String>[];

    for (int i = 0; i < questions.length; i++) {
      final questionId = i + 1;

      if (questions[i].skipped) {
        answers.add("");
        continue;
      }

      final answer = questions[i].answer.trim();

      if (answer.isEmpty) {
        answers.add("");
        continue;
      }

      if (questionId == 1) {
        answers.add(answer);
      } else {
        answers.add(answer);
      }
    }

    setState(() => loadingMood = true);

    try {
      final res = await http.post(
        Uri.parse(overallUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"answers": answers}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final finalMood = data["final_mood"]?.toString() ?? "";
        final dynamic totalScoreValue = data["total_score"];
        final int? totalScore = totalScoreValue is num
            ? totalScoreValue.toInt()
            : int.tryParse(totalScoreValue?.toString() ?? "");
        final List<int> perQuestionScores = <int>[];
        final dynamic perQuestionValue = data["per_question"];
        if (perQuestionValue is List) {
          for (final item in perQuestionValue) {
            if (item is Map && item.containsKey("score")) {
              final scoreValue = item["score"];
              if (scoreValue is num) {
                perQuestionScores.add(scoreValue.toInt());
              } else {
                final parsed = int.tryParse(scoreValue?.toString() ?? "");
                if (parsed != null) {
                  perQuestionScores.add(parsed);
                }
              }
            } else if (item is num) {
              perQuestionScores.add(item.toInt());
            } else {
              final parsed = int.tryParse(item?.toString() ?? "");
              if (parsed != null) {
                perQuestionScores.add(parsed);
              }
            }
          }
        }

        await Future.delayed(const Duration(seconds: 3));

        try {
          final storageRes = await ApiClient.storeMood(
            mood: finalMood,
            datetime: DateTime.now().toIso8601String(),
          );

          if (storageRes.statusCode == 200 || storageRes.statusCode == 201) {
            final storageData = jsonDecode(storageRes.body);

            if (storageData["status"] == "already_exists") {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("ඔයා අද mood check එක කරලා ඉවරයි!."),
                    duration: Duration(seconds: 3),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              setState(() => loadingMood = false);
              if (mounted) {
                Navigator.pop(context);
              }
              return;
            }

            try {
              if (storageData["alert_permission_needed"] == true) {
                final badMoodCount = storageData["bad_mood_count"] ?? 5;
                await _showAlertPermissionDialog(badMoodCount: badMoodCount);
              }
            } catch (_) {}
          } else if (storageRes.statusCode == 409) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("අද දවසේ මනෝභාවය දැනටමත් සටහන් කර ඇත."),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("මනෝභාවය අනාවරණය විය, නමුත් සුරැකීම අසාර්ථක විය"),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("මනෝභාවය අනාවරණය විය, නමුත් සුරැකීම අසාර්ථක විය"),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        setState(() => loadingMood = false);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MoodResultScreen(
                mood: finalMood,
                totalScore: totalScore,
                perQuestionScores: perQuestionScores,
              ),
            ),
          );
        }
        return;
      } else {
        setState(() {
          mood = "API error: ${res.statusCode}\n${res.body}";
        });
      }
    } catch (e) {
      setState(() {
        mood = "Connection Error\n$e\n\nTroubleshooting:\n✓ Backend running on ${ApiConfig.baseUrl}?\n✓ Phone & PC on same WiFi?\n✓ Try ${ApiConfig.baseUrl}/docs in browser";
      });
    } finally {
      setState(() => loadingMood = false);
    }
  }

  Future<void> handleSubmitAll() async {
    final currentAnswer = questions[currentQuestionIndex].answer.trim();
    final bool isLastQuestion = currentQuestionIndex == questions.length - 1;

    if (isLastQuestion && currentAnswer.isEmpty) {
      int answeredCount = 0;
      for (int i = 0; i < questions.length; i++) {
        if (!questions[i].skipped && questions[i].answer.trim().isNotEmpty) {
          answeredCount++;
        }
      }

      if (answeredCount >= 3) {
        setState(() {
          questions[currentQuestionIndex].skipped = true;
          questions[currentQuestionIndex].answer = "";
          questions[currentQuestionIndex].mood = "";
          liveTranscript = "";
          _accumulatedTranscript = "";
          _finalTranscript = "";
          _currentPartialTranscript = "";
          _transcriptController.clear();
        });
        await submitAllAnswers();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "අවසාන ප්‍රතිඵලය ලබාගන්න, පළමු ප්‍රශ්නයට සහ තවත් ප්‍රශ්න 2කටවත් පිළිතුරු දෙන්න.",
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final validation = await validateAnswer(currentQuestionIndex + 1, currentAnswer);

    if (validation == null) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("වලංගු කිරීමේ දෝෂයක්"),
          content: const Text("ඔබේ අවසාන පිළිතුර වලංගු කිරීමට නොහැකි විය. කෙසේ වුවද ඉදිරියට යන්නද?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("නැත"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("ඔව්"),
            ),
          ],
        ),
      );

      if (shouldContinue == true) {
        await submitAllAnswers();
      }
      return;
    }

    if (validation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("කරුණාකර උත්තරයක් ලබා දෙන්න."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (validation.needsMoreInfo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ටිකක් විස්තර කරලා කියන්න පුළුවන්ද?"),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (validation.isIrrelevant) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ඔයාගේ උත්තරේ ප්‍රශ්නයට සම්බන්ධ නැහැ වගේ. ටිකක් විස්තර කරලා කියන්න."),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (validation.isYesNoAnswer) {
      final answerText = validation.normalized.isNotEmpty
          ? validation.normalized.toLowerCase()
          : questions[currentQuestionIndex].answer.trim().toLowerCase();

      final isYes = answerText.contains('ඔව්') ||
          answerText.contains('yes') ||
          answerText == 'ඔව්' ||
          answerText == 'yes';

      final questionId = currentQuestionIndex + 1;
      String mood;
      if (questionId == 5) {
        mood = isYes ? "සතුටුයි" : "සාමාන්‍ය";
      } else {
        mood = isYes ? "දුකයි / හොඳ නෑ" : "සතුටුයි";
      }

      setState(() {
        if (validation.normalized.isNotEmpty) {
          questions[currentQuestionIndex].answer = validation.normalized;
          questions[currentQuestionIndex].skipped = false;
        }
        questions[currentQuestionIndex].mood = mood;
      });
      await submitAllAnswers();
      return;
    }

    if (validation.isQ1DirectMood) {
      String moodLabel;
      final directMood = validation.directMood?.toLowerCase() ?? '';

      if (directMood.contains('happy')) {
        moodLabel = "සතුටුයි";
      } else if (directMood.contains('normal')) {
        moodLabel = "සාමාන්‍ය";
      } else if (directMood.contains('bad')) {
        moodLabel = "දුකයි / හොඳ නෑ";
      } else {
        moodLabel = validation.directMood ?? "සාමාන්‍ය";
      }

      setState(() {
        if (validation.normalized.isNotEmpty) {
          questions[currentQuestionIndex].answer = validation.normalized;
          questions[currentQuestionIndex].skipped = false;
        }
        questions[currentQuestionIndex].mood = moodLabel;
      });
      await submitAllAnswers();
      return;
    }

    if (validation.isNeutralPhrase) {
      setState(() {
        if (validation.normalized.isNotEmpty) {
          questions[currentQuestionIndex].answer = validation.normalized;
          questions[currentQuestionIndex].skipped = false;
        }
        questions[currentQuestionIndex].mood = "Normal / සාමාන්‍ය";
      });
      await submitAllAnswers();
      return;
    }

    if (validation.isValidText) {
      await submitAllAnswers();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Unknown validation status: ${validation.status}"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _manuallyStopped = true;
    _stopSpeechWatchdog();
    speech.stop();
    _transcriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF4CAF50);
    const secondaryGreen = Color(0xFF2E7D32);
    const lightGrey = Color(0xFFF5F5F5);
    const softBlue = Color(0xFF64B5F6);
    const textDark = Color(0xFF333333);
    final currentQuestion = questions[currentQuestionIndex];
    final showText = listening ? liveTranscript : currentQuestion.answer;
    final isLastQuestion = currentQuestionIndex == questions.length - 1;
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ClipOval(
                                  child: Image.asset(
                                    'assets/images/sidephoto.jpg',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "සුව මනස",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "ප්‍රශ්නය ${currentQuestionIndex + 1}/${questions.length}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    "${(progress * 100).toInt()}%",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF22C55E),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 2,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width - 80,
                                ),
                                child: Text(
                                  currentQuestion.text,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                ),
                              ),
                              if (currentQuestion.answer.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: currentQuestion.loadingMood
                                      ? null
                                      : () => checkQuestionMood(currentQuestionIndex),
                                  icon: currentQuestion.loadingMood
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.visibility),
                                  label: Text(
                                    currentQuestion.loadingMood
                                        ? "පරීක්ෂා කරනවා..."
                                        : "result",
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF22C55E),
                                  ),
                                ),
                              ],
                              if (currentQuestion.mood.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 300),
                                  child: MoodBadge(moodText: currentQuestion.mood),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        listening ? "🎤 සවන් දෙනවා... කථා කරන්න" : "ඔබේ පිළිතුර",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        constraints: const BoxConstraints(
                          minHeight: 250,
                          maxHeight: 350,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: listening
                            ? Column(
                                children: [
                                  if (_transcriptController.text.isEmpty) ...[
                                    const SizedBox(height: 10),
                                    ListeningIndicator(useLottie: true),
                                    const SizedBox(height: 10),
                                  ],
                                  Expanded(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(8),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          liveTranscript.isEmpty ? "කථා කරන්න..." : liveTranscript,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: liveTranscript.isEmpty
                                                ? Colors.grey[400]
                                                : Colors.black87,
                                            fontWeight: FontWeight.w700,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  showText.isEmpty
                                      ? "මෙතන ඔබේ පිළිතුර පෙනෙනවා..."
                                      : showText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: showText.isEmpty
                                        ? Colors.grey[500]
                                        : Colors.black87,
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: listening ? stopListening : startListening,
                      icon: Icon(listening ? Icons.stop : Icons.mic),
                      label: Text(
                        listening ? "නවත්වන්න" : "කථා කරන්න පටන් ගන්න",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: softBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),

                    if (currentQuestion.answer.isNotEmpty && !listening) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: retakeAnswer,
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          "නැවත පටන් ගන්න",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(14),
                          foregroundColor: secondaryGreen,
                          side: const BorderSide(color: secondaryGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        if (currentQuestionIndex > 0)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: listening ? null : previousQuestion,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text("පෙර"),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(14),
                                foregroundColor: secondaryGreen,
                                side: const BorderSide(color: secondaryGreen),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        if (currentQuestionIndex > 0) const SizedBox(width: 12),
                        if (currentQuestionIndex > 0)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: listening ? null : handleSkipQuestion,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(14),
                                backgroundColor: lightGrey,
                                foregroundColor: textDark,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                "මග හරින්න",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        if (currentQuestionIndex > 0) const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: listening
                                ? null
                                : (isLastQuestion ? handleSubmitAll : handleNextQuestion),
                            icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
                            label: Text(
                              isLastQuestion ? "ඉවරයි" : "ඊළඟ",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(14),
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (loadingMood)
            LoadingOverlay(
              title: "කල්පනා කරනවා… 🤔",
              subtitle: "ඔබගේ මූඩ් එක බලනවා",
              useLottie: true,
            ),
        ],
      ),
    );
  }
}