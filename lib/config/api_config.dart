class ApiConfig {
  // ================= COMPANY EMOTION API =================
  // Backend API Base URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.180.12:8000',
  );

  static const String emotionPredictImage = '$baseUrl/emotion/predict-image';
  static const String emotionUpload = '$baseUrl/emotion/upload';
  static const String emotionPredictWithHappyFace =
      '$baseUrl/emotion/predict-with-happy-face';

  // ================= LEADERBOARD API =================
  static const String leaderboardBase = '$baseUrl/leaderboard';

  // ================= YOUR SINHALA MOOD API =================
  // Sinhala Mood Classification API

  static const String PREDICT_ENDPOINT = '$baseUrl/mood/predict';
  static const String PREDICT_OVERALL_ENDPOINT =
      '$baseUrl/mood/predict_overall';
  static const String VALIDATE_ANSWER_ENDPOINT =
      '$baseUrl/mood/validate_answer';
  static const String PREDICT_QUESTION_ENDPOINT =
      '$baseUrl/mood/predict_question';

  // ================= MUSIC SESSION API =================
  static const String musicTracks = '$baseUrl/music/tracks';
  static const String musicRecommendations = '$baseUrl/music/recommendations';
  static const String musicSessionStart = '$baseUrl/music/session/start';
  // Mood Storage Endpoint (already using baseUrl)
  static const String STORE_MOOD_ENDPOINT = '$baseUrl/mood/store';
}
