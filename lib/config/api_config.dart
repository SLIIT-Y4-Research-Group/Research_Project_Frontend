class ApiConfig {
  // ================= COMPANY EMOTION API =================
  // Backend API Base URL
  // Local dev: http://localhost:8000
  // Mobile device: http://YOUR_PC_IP:8000
  static const String baseUrl = 'http://localhost:8000';

  static const String emotionPredictImage = '$baseUrl/emotion/predict-image';
  static const String emotionUpload = '$baseUrl/emotion/upload';
  static const String emotionPredictWithHappyFace =
      '$baseUrl/emotion/predict-with-happy-face';

  // ================= LEADERBOARD API =================
  static const String leaderboardBase = '$baseUrl/leaderboard';

  // ================= YOUR SINHALA MOOD API =================
  // Sinhala Mood Classification API
  static const String BASE_URL = 'http://127.0.0.1:8000';

  static const String PREDICT_ENDPOINT = '$BASE_URL/mood/predict';
  static const String PREDICT_OVERALL_ENDPOINT =
      '$BASE_URL/mood/predict_overall';
  static const String VALIDATE_ANSWER_ENDPOINT =
      '$BASE_URL/mood/validate_answer';
  static const String PREDICT_QUESTION_ENDPOINT =
      '$BASE_URL/mood/predict_question';
}
