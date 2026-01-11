class ApiConfig {
  // Backend API Base URL
  // Change this based on your environment:
  // - Local development: 'http://localhost:8000'
  // - Mobile device on same network: 'http://YOUR_COMPUTER_IP:8000'
  // - Deployed backend: 'https://your-backend-url.com'
  static const String baseUrl = 'http://127.0.0.1:8000';

  // Emotion API endpoints
  static const String emotionPredictImage = '$baseUrl/emotion/predict-image';
  static const String emotionUpload = '$baseUrl/emotion/upload';
  static const String emotionPredictWithHappyFace = '$baseUrl/emotion/predict-with-happy-face';
  static const String triFusion = '$baseUrl/predict/tri_fusion';
}

