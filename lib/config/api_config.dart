class ApiConfig {
  // ================= COMPANY EMOTION API =================
  // Backend API Base URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String emotionPredictImage = '$baseUrl/emotion/predict-image';
  static const String emotionUpload = '$baseUrl/emotion/upload';
  static const String emotionPredictWithHappyFace =
      '$baseUrl/emotion/predict-with-happy-face';

  // ================= LEADERBOARD API =================
  static const String leaderboardBase = '$baseUrl/leaderboard';

  // ================= UNIFIED BACKEND API =================
  // All mood endpoints (prediction + storage) now use the same backend
  // The ML prediction code has been merged into the main backend
  
  // Mood Prediction Endpoints (now using unified baseUrl)
  static const String PREDICT_ENDPOINT = '$baseUrl/mood/predict';
  static const String PREDICT_OVERALL_ENDPOINT = '$baseUrl/mood/predict_overall';
  static const String VALIDATE_ANSWER_ENDPOINT = '$baseUrl/mood/validate_answer';
  static const String PREDICT_QUESTION_ENDPOINT = '$baseUrl/mood/predict_question';
  
  // Mood Storage Endpoint (already using baseUrl)
  static const String STORE_MOOD_ENDPOINT = '$baseUrl/mood/store';
}
