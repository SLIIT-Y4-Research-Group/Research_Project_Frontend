import 'dart:convert';
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
  String _lastRecognizedWords = "";
  bool _isUserEditing = false;
  
  // Consent state (only for child users)
  bool _isChildUser = false;
  bool _alertsConsent = false;
  bool _loadingConsent = false;
  String _childName = "";

  //  Five questions
  late List<Question> questions;

  // final String apiUrl = "http://127.0.0.1:8000/mood/predict";
  // final String overallUrl = "http://127.0.0.1:8000/mood/predict_overall";

  // Using centralized API configuration
  final String apiUrl = ApiConfig.PREDICT_ENDPOINT;
  final String overallUrl = ApiConfig.PREDICT_OVERALL_ENDPOINT;
  final String validateUrl = ApiConfig.VALIDATE_ANSWER_ENDPOINT;
  final String predictQuestionUrl = ApiConfig.PREDICT_QUESTION_ENDPOINT;



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
    _checkUserTypeAndLoadConsent();
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
      // Silently fail - consent can be set later
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
              content: Text(value 
                ? 'Alert emails enabled' 
                : 'Alert emails disabled'),
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
              onChanged: _loadingConsent ? null : (value) {
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
      barrierDismissible: false, // Student must respond
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Supportive illustration - Hand with love animation
              Lottie.asset(
                'assets/lottie/Hand with love.json',
                height: 110,
                repeat: true,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              
              // Main message with child's name
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
              
              // Supporting text
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
              
              // Permission question
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
                  print("[MOOD] Student declined alert permission");
                  await ApiClient.respondAlertPermission(approve: false);
                  print("[MOOD] Decline response sent to backend");
                  
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
                  // Continue anyway - navigation should not break
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
                  print("[MOOD] Student approved alert permission");
                  await ApiClient.respondAlertPermission(approve: true);
                  print("[MOOD] Approval response sent to backend");
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ඔබේ භාරකරුට දැනුම්දීම යවන ලදී ✓'),
                        duration: Duration(seconds: 3),
                        backgroundColor: Color(0xFF22C55E),
                      ),
                    );
                  }
                } catch (e) {
                  print("[MOOD] Error sending approval response: $e");
                  // Continue anyway - navigation should not break
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
              questions[currentQuestionIndex].skipped = false;
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
        questions[currentQuestionIndex].skipped = false;
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

  void handleSkipQuestion() {
    // Only allow skipping Q2-Q5 (not Q1)
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

    // Special handling for Q5 (last question)
    bool isLastQuestion = currentQuestionIndex == questions.length - 1;
    
    if (isLastQuestion) {
      // Count how many questions are already answered (excluding current Q5)
      int answeredCount = 0;
      for (int i = 0; i < questions.length - 1; i++) { // Check Q1-Q4 only
        if (!questions[i].skipped && questions[i].answer.trim().isNotEmpty) {
          answeredCount++;
        }
      }
      
      // Need minimum 3 answers from Q1-Q4 to skip Q5
      if (answeredCount < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("අවසාන ප්‍රශ්නය මග හැරීමට, අවම වශයෙන් පළමු ප්‍රශ්න 3කට පිළිතුරු දෙන්න."),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // If 3+ answers exist, skip Q5 and submit directly
      setState(() {
        questions[currentQuestionIndex].skipped = true;
        questions[currentQuestionIndex].answer = "";
        questions[currentQuestionIndex].mood = "";
      });
      submitAllAnswers();
      return;
    }

    // For Q2-Q4: normal skip behavior (skip and go to next question)
    setState(() {
      questions[currentQuestionIndex].skipped = true;
      questions[currentQuestionIndex].answer = "";
      questions[currentQuestionIndex].mood = "";
    });
    nextQuestion();
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
      questions[currentQuestionIndex].skipped = false;
      liveTranscript = "";
      _transcriptController.clear();
    });
  }

  Future<void> checkQuestionMood(int questionIndex) async {
    debugPrint("🔍 checkQuestionMood called for question $questionIndex");
    
    final question = questions[questionIndex];
    final questionId = questionIndex + 1; // Convert 0-4 index to 1-5 question ID
    
    if (question.answer.trim().isEmpty) {
      debugPrint("❌ Answer is empty");
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

    // First, validate the answer
    final validation = await validateAnswer(questionId, question.answer.trim());
    debugPrint("📋 Validation status: ${validation?.status ?? 'null'} (normalized: ${validation?.statusNormalized ?? 'null'})");
    
    // Handle validation failure
    if (validation == null) {
      debugPrint("❌ Validation returned null - network or API error");
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

    // Handle validation statuses
    if (validation.isEmpty) {
      debugPrint("⚠️ Status: EMPTY - stopping here");
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
      debugPrint("⚠️ Status: NEED_MORE_INFO - stopping here");
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
      debugPrint("⚠️ Status: IRRELEVANT - stopping here, NOT calling predict_question");
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

    // Handle YES/NO answers for Q2-Q5
    if (validation.isYesNoAnswer) {
      debugPrint("✅ Status: YES_NO - processing as yes/no answer");
      final answerText = validation.normalized.isNotEmpty 
          ? validation.normalized.toLowerCase() 
          : question.answer.trim().toLowerCase();
      
      // Detect YES or NO
      final isYes = answerText.contains('ඔව්') || 
                    answerText.contains('yes') || 
                    answerText == 'ඔව්' ||
                    answerText == 'yes';
      
      String mood;
      if (questionId == 5) {
        // Q5: YES = Happy, NO = Normal
        mood = isYes ? "සතුටුයි" : "සාමාන්‍ය";
      } else {
        // Q2, Q3, Q4: YES = Bad, NO = Happy
        mood = isYes ? "දුකයි / හොඳ නෑ" : "සතුටුයි";
      }
      debugPrint("✅ YES_NO mood determined: $mood");
      
      setState(() {
        questions[questionIndex].mood = mood;
        questions[questionIndex].loadingMood = false;
      });
      return;
    }

    // Handle Q1_DIRECT_MOOD - direct mood from backend
    if (validation.isQ1DirectMood) {
      debugPrint("✅ Status: Q1_DIRECT_MOOD - using direct mood from validator");
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
      debugPrint("✅ Q1_DIRECT_MOOD determined: $moodLabel");
      
      setState(() {
        if (validation.normalized.isNotEmpty) {
          questions[questionIndex].answer = validation.normalized;
        }
        questions[questionIndex].mood = moodLabel;
        questions[questionIndex].loadingMood = false;
      });
      return;
    }

    // Handle VALID_TEXT - call mood prediction endpoint
    if (validation.isValidText) {
      debugPrint("✅ Status: VALID_TEXT - calling predict_question endpoint");
      debugPrint("🌐 Calling predict_question with question_id=$questionId");
      try {
        final res = await http.post(
          Uri.parse(predictQuestionUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"question_id": questionId, "text": question.answer}),
        );
        debugPrint("📡 predict_question response: ${res.statusCode}");

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
          questions[questionIndex].mood = "Connection Error: $e\n\nCheck:\n- Backend running?\n- Same WiFi?\n- IP: ${ApiConfig.baseUrl}";
        });
      } finally {
        setState(() {
          questions[questionIndex].loadingMood = false;
        });
      }
      return;
    }

    // Unknown validation status
    debugPrint("❌ Unknown validation status: ${validation.status} - this should not happen!");
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
        // If validation endpoint fails, return null and allow continuation
        setState(() {
          mood = "Validation error: ${res.statusCode}";
        });
        return null;
      }
    } catch (e) {
      // If validation endpoint fails, return null and allow continuation
      setState(() {
        mood = "Validation connection error: $e";
      });
      return null;
    }
  }

  Future<void> handleNextQuestion() async {
    final currentAnswer = questions[currentQuestionIndex].answer.trim();
    
    // Validate answer
    final validation = await validateAnswer(currentQuestionIndex + 1, currentAnswer);
    
    // If validation failed (network error), show warning but allow continuation
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
    
    // Handle validation status
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
      // Store yes/no answer without calling mood prediction
      // Use normalized answer if available
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
        // Q2, Q3, Q4: YES = Bad, NO = Happy
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
      // Q1 direct mood classification from backend
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
    
    if (validation.isValidText) {
      // Proceed with normal flow - no action needed here
      // The mood prediction will be called separately if user clicks "result" button
      nextQuestion();
      return;
    }
    
    // Unknown status - show warning and allow continuation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Unknown validation status: ${validation.status}"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isYesNoAnswer(String answer) {
    final lower = answer.toLowerCase().trim();
    return lower == 'ඔව්' || lower == 'නෑ' || lower == 'නැහැ' || 
           lower == 'yes' || lower == 'no' || lower == 'ok' ||
           lower == 'ow' || lower == 'naa' || lower == 'නෑ';
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
            ? "අද මට ගුරුවරු හෝ යාළුවන් සමඟ ගැටලුවක් තිබුණා"
            : "අද මට ගුරුවරු හෝ යාළුවන් සමඟ ගැටලුවක් නැහැ";
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
        return answer; // Fallback
    }
  }

  Future<void> submitAllAnswers() async {
  // Validate minimum requirements before submission
  // Q1 must be answered
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

  // Count answered questions (not skipped and not empty)
  int answeredCount = 0;
  for (int i = 0; i < questions.length; i++) {
    if (!questions[i].skipped && questions[i].answer.trim().isNotEmpty) {
      answeredCount++;
    }
  }
  
  print("[SUBMIT] Answered count: $answeredCount");
  for (int i = 0; i < questions.length; i++) {
    print("  Q${i+1}: skipped=${questions[i].skipped}, answer='${questions[i].answer.trim()}' (${questions[i].answer.trim().length} chars)");
  }

  // Minimum 3 questions must be answered (Q1 + 2 more)
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

  // Build answers list with YES/NO conversion
  // Send exactly 5 answers, empty string for skipped
  final answers = <String>[];
  
  for (int i = 0; i < questions.length; i++) {
    final questionId = i + 1;
    
    // If skipped, send empty string
    if (questions[i].skipped) {
      answers.add("");
      continue;
    }
    
    final answer = questions[i].answer.trim();
    
    // If somehow empty (shouldn't happen due to validation above), send empty
    if (answer.isEmpty) {
      answers.add("");
      continue;
    }
    
    // Q1: always use the real answer
    if (questionId == 1) {
      answers.add(answer);
    } else {
      // Q2-Q5: check if it's YES/NO and convert to sentence
      if (_isYesNoAnswer(answer)) {
        answers.add(_convertYesNoToSentence(questionId, answer));
      } else {
        // Keep the real descriptive answer
        answers.add(answer);
      }
    }
  }

  setState(() => loadingMood = true);

  try {
    print("[MOOD] Starting mood prediction...");
    
    final res = await http.post(
      Uri.parse(overallUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"answers": answers}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final finalMood = data["final_mood"]?.toString() ?? "";
      
      print("[MOOD] Prediction received: $finalMood");
      
      // Wait for minimum 3 seconds to show the loading animation
      await Future.delayed(const Duration(seconds: 3));
      
      // After successful prediction, store the mood to backend
      try {
        print("[MOOD] Attempting to store mood to backend...");
        
        final storageRes = await ApiClient.storeMood(
          mood: finalMood,
          datetime: DateTime.now().toIso8601String(),
        );
        
        if (storageRes.statusCode == 200 || storageRes.statusCode == 201) {
          print("[MOOD] Mood stored successfully to backend");
          
          // Check if alert permission is needed
          try {
            final storageData = jsonDecode(storageRes.body);
            if (storageData["alert_permission_needed"] == true) {
              final badMoodCount = storageData["bad_mood_count"] ?? 5;
              print("[MOOD] Alert permission needed - showing dialog (bad mood count: $badMoodCount)");
              
              // Show permission dialog before navigating to result screen
              await _showAlertPermissionDialog(badMoodCount: badMoodCount);
            } else {
              print("[MOOD] No alert permission needed");
            }
          } catch (parseError) {
            print("[MOOD] Could not parse storage response for alert check: $parseError");
            // Continue normal flow if parsing fails
          }
        } else if (storageRes.statusCode == 409) {
          // Handle already_exists (conflict)
          print("[MOOD] Mood already recorded today: ${storageRes.body}");
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
          print("[MOOD] Failed to store mood: ${storageRes.statusCode} - ${storageRes.body}");
          
          // Check if response indicates already_exists
          try {
            final errorData = jsonDecode(storageRes.body);
            if (errorData["detail"]?.toString().toLowerCase().contains("already") == true ||
                errorData["error"]?.toString().toLowerCase().contains("already") == true) {
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
              // Other error
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
          } catch (parseError) {
            // Show generic error
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
        }
      } catch (storageError) {
        print("[MOOD] Error storing mood: $storageError");
        // Show warning but continue to result screen
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
    print("[MOOD] Connection error: $e");
    setState(() {
      mood = "Connection Error\n$e\n\nTroubleshooting:\n✓ Backend running on ${ApiConfig.baseUrl}?\n✓ Phone & PC on same WiFi?\n✓ Try ${ApiConfig.baseUrl}/docs in browser";
    });
  } finally {
    setState(() => loadingMood = false);
  }
}

  Future<void> handleSubmitAll() async {
    final currentAnswer = questions[currentQuestionIndex].answer.trim();
    
    // Validate the last answer before submitting all
    final validation = await validateAnswer(currentQuestionIndex + 1, currentAnswer);
    
    // If validation failed (network error), show warning but allow continuation
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
    
    // Handle validation status
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
      // Store yes/no answer
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
        // Q2, Q3, Q4: YES = Bad, NO = Happy
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
      // Q1 direct mood classification from backend
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
    
    if (validation.isValidText) {
      // Proceed with normal submission
      await submitAllAnswers();
      return;
    }
    
    // Unknown status - show warning
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Unknown validation status: ${validation.status}"),
        duration: const Duration(seconds: 2),
      ),
    );
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
                          // Settings and logout buttons (only for logged in child users)
                          if (_isChildUser)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.settings, color: Colors.white),
                                  onPressed: _showConsentDialog,
                                  tooltip: 'Alert Settings',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout, color: Colors.white),
                                  onPressed: _logout,
                                  tooltip: 'Logout',
                                ),
                              ],
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
                      // Skip button for Q2-Q5 only (not Q1)
                      if (currentQuestionIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: listening ? null : handleSkipQuestion,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(14),
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[400]!),
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