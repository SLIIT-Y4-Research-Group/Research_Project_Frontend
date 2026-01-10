import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../config/api_config.dart';
import '../widgets/listening_indicator.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/mood_badge.dart';
import 'mood_result_screen.dart';




class Question {
  final String text;
  String answer;
  String mood;
  bool loadingMood;

  Question(this.text)
      : answer = "",
        mood = "",
        loadingMood = false;
}

class MoodHome extends StatefulWidget {
  const MoodHome({super.key});
  @override
  State<MoodHome> createState() => _MoodHomeState();
}

class _MoodHomeState extends State<MoodHome> {
  final stt.SpeechToText speech = stt.SpeechToText();
  final TextEditingController _transcriptController = TextEditingController();

  bool listening = false;
  bool isSpeechAvailable = false;
  int currentQuestionIndex = 0;

  String liveTranscript = "";
  String mood = "";
  bool loadingMood = false;
  String _lastRecognizedWords = "";
  bool _isUserEditing = false;

  //  Five questions
  late List<Question> questions;

  // final String apiUrl = "http://127.0.0.1:8000/mood/predict";
  // final String overallUrl = "http://127.0.0.1:8000/mood/predict_overall";

  // Using centralized API configuration
  final String apiUrl = ApiConfig.PREDICT_ENDPOINT;
  final String overallUrl = ApiConfig.PREDICT_OVERALL_ENDPOINT;



  @override
  void initState() {
    super.initState();
    questions = [
      Question(" අද ඉස්කෝලේ ගත කරපු කාලය ගැන ඔයාට මොකද හිතෙන්නේ? "),
      Question(" අද ඉස්කෝලේ ගුරුවරු එක්ක හරි යාළුවො එක්ක හරි ගැටලුවක් ඇතිවුණාද?"),
      Question(" අද පාඩම් වැඩ, homework හරි exam හරි නිසා ආතතියක් තිබුණාද?"),
      Question(" අද ඔයාට හුඟාක් මහන්සිද? අද විවේකයක් නැතිවම ද හිටියේ?"),
      Question(" අද ඔයාට සතුටු වෙන්න පුළුවන් මොකක් හරි හේතුවක් තියෙනවද?"),    
    ];
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    
    if (!status.isGranted) {
      setState(() {
        mood = "Microphone permission denied. Please enable it in settings.";
        isSpeechAvailable = false;
      });
      return;
    }

    isSpeechAvailable = await speech.initialize(
      onStatus: (status) {
        // statuses: listening, notListening, done
        if (status == "notListening" || status == "done") {
          setState(() => listening = false);
        }
      },
      onError: (error) {
        setState(() {
          listening = false;
          mood = "Speech error: ${error.errorMsg}";
        });
      },
    );
    setState(() {});
  }

  Future<void> startListening() async {
    if (!isSpeechAvailable) {
      setState(() => mood = "Speech recognition not available");
      return;
    }

    setState(() {
      listening = true;
      mood = "";
      _lastRecognizedWords = "";
      _isUserEditing = false;
    });

    await speech.listen(
      localeId: "si_LK",
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      pauseFor: const Duration(hours: 1), // Effectively no timeout - wait 1 hour of silence
      listenFor: const Duration(hours: 24), // Allow 24 hours of continuous listening
      cancelOnError: true,
      onResult: (result) {
        // Don't override if user is manually editing
        if (_isUserEditing) {
          _isUserEditing = false;
          return;
        }
        
        setState(() {
          String newWords = result.recognizedWords;
          
          if (newWords.isNotEmpty && newWords != _lastRecognizedWords) {
            // Get current cursor position and text
            final cursorPosition = _transcriptController.selection.baseOffset;
            final currentText = _transcriptController.text;
            
            // Determine where to insert new speech
            int insertPosition = cursorPosition >= 0 ? cursorPosition : currentText.length;
            
            // Get text before and after cursor
            String beforeCursor = currentText.substring(0, insertPosition);
            String afterCursor = currentText.substring(insertPosition);
            
            // Remove old recognized words if they exist at cursor position
            if (_lastRecognizedWords.isNotEmpty && beforeCursor.endsWith(_lastRecognizedWords)) {
              beforeCursor = beforeCursor.substring(0, (beforeCursor.length - _lastRecognizedWords.length).toInt());
            }
            
            // Add space if needed
            if (beforeCursor.isNotEmpty && !beforeCursor.endsWith(' ') && !newWords.startsWith(' ')) {
              beforeCursor += ' ';
            }
            
            // Construct new text
            _transcriptController.text = beforeCursor + newWords + afterCursor;
            liveTranscript = _transcriptController.text;
            _lastRecognizedWords = newWords;
            
            // Set cursor after the new words
            int newCursorPosition = beforeCursor.length + newWords.length;
            _transcriptController.selection = TextSelection.fromPosition(
              TextPosition(offset: newCursorPosition),
            );
            
            if (result.finalResult) {
              questions[currentQuestionIndex].answer = _transcriptController.text;
              _lastRecognizedWords = "";
            }
          }
        });
      },
    );
  }

  Future<void> stopListening() async {
    await speech.stop();
    setState(() {
      listening = false;
      String finalText = _transcriptController.text.trim();
      if (finalText.isNotEmpty) {
        questions[currentQuestionIndex].answer = finalText;
        liveTranscript = finalText;
      }
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        liveTranscript = questions[currentQuestionIndex].answer;
        _transcriptController.text = questions[currentQuestionIndex].answer;
      });
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        liveTranscript = questions[currentQuestionIndex].answer;
        _transcriptController.text = questions[currentQuestionIndex].answer;
      });
    }
  }

  void retakeAnswer() {
    setState(() {
      questions[currentQuestionIndex].answer = "";
      questions[currentQuestionIndex].mood = "";
      liveTranscript = "";
      _transcriptController.clear();
    });
  }

  Future<void> checkQuestionMood(int questionIndex) async {
    final question = questions[questionIndex];
    
    if (question.answer.trim().isEmpty) {
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

    try {
      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": question.answer}),
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
        questions[questionIndex].mood = "Connection Error: $e\n\nCheck:\n- Backend running?\n- Same WiFi?\n- IP: ${ApiConfig.BASE_URL}";
      });
    } finally {
      setState(() {
        questions[questionIndex].loadingMood = false;
      });
    }
  }

  Future<void> submitAllAnswers() async {
  final answers = questions.map((q) => q.answer.trim()).where((a) => a.isNotEmpty).toList();

  if (answers.isEmpty) {
    setState(() => mood = "කරුණාකර අවම වශයෙන් එක් ප්‍රශ්නයකට පිළිතුරු දෙන්න");
    return;
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
      
      // Wait for minimum 3 seconds to show the loading animation
      await Future.delayed(const Duration(seconds: 3));
      
      setState(() => loadingMood = false);
      
      // Navigate to result screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MoodResultScreen(mood: finalMood),
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
      mood = "Connection Error\n$e\n\nTroubleshooting:\n✓ Backend running on ${ApiConfig.BASE_URL}?\n✓ Phone & PC on same WiFi?\n✓ Try ${ApiConfig.BASE_URL}/docs in browser";
    });
  } finally {
    setState(() => loadingMood = false);
  }
}


  @override
  void dispose() {
    speech.stop();
    _transcriptController.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  final currentQuestion = questions[currentQuestionIndex];
  final showText = listening ? liveTranscript : currentQuestion.answer;
  final isLastQuestion = currentQuestionIndex == questions.length - 1;
  final progress = (currentQuestionIndex + 1) / questions.length;

  return Scaffold(
    backgroundColor: Colors.white,
    body: Stack(
      children: [
        // Main UI
        Column(
          children: [
            // Green curved header section
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
                      // Logo at top left
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
                      const SizedBox(height: 20),
                      // Progress indicator
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

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question card
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

                            // Per-question mood badge
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

                    // Status text
                    Text(
                      listening ? "🎤 සවන් දෙනවා... කථා කරන්න" : "✅ ඔබේ පිළිතුර",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Answer box - Flexible height
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
                                  child: TextField(
                                    controller: _transcriptController,
                                    maxLines: null,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w700,
                                      height: 1.5,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "කථා කරන්න...",
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(8),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        liveTranscript = value;
                                        _isUserEditing = true;
                                      });
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    "💡 වැරදි වචනයක් මකන්න පුළුවන්",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
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
                    
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),

            // Bottom buttons section - Pinned at bottom
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
                  // Microphone button
                  ElevatedButton.icon(
                    onPressed: listening ? stopListening : startListening,
                    icon: Icon(listening ? Icons.stop : Icons.mic),
                    label: Text(
                      listening ? "නවත්වන්න" : "කථා කරන්න පටන් ගන්න",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: listening ? Colors.red : const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),

                  // Retake button
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
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Navigation buttons
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
                              foregroundColor: const Color(0xFF22C55E),
                              side: const BorderSide(color: Color(0xFF22C55E)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      if (currentQuestionIndex > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: listening
                              ? null
                              : (isLastQuestion ? submitAllAnswers : nextQuestion),
                          icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
                          label: Text(
                            isLastQuestion ? "ඉවරයි" : "ඊළඟ",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(14),
                            backgroundColor: const Color(0xFF22C55E),
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

          // Loading overlay (global)
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