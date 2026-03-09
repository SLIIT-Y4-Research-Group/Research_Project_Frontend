class AppConstants {
  // API Constants
  static const String contentType = 'application/json';
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 60000; // 60 seconds
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String storiesKey = 'cached_stories';
  static const String settingsKey = 'app_settings';
  
  // Mood Constants
  static const List<String> moodEmojis = ['😢', '😰', '😐', '😌', '😊', '😠', '😕', '🤗'];
  static const List<String> moodSinhalaNames = [
    'දුක් සහගත',
    'කලඬල',
    'හිස්',
    'සන්සුන්',
    'සතුටු',
    'කෝපවත්',
    'ව්‍යාකූල',
    'බලාපොරොත්තු'
  ];
  
  // Sinhala translations for API values
  static final Map<String, String> moodTranslations = {
    'sad': 'දුක් සහගත',
    'anxious': 'කලබල',
    'empty': 'හිස්',
    'calm': 'සන්සුන්',
    'happy': 'සතුටු',
    'angry': 'කෝපවත්',
    'confused': 'ව්‍යාකූල',
    'hopeful': 'බලාපොරොත්තු',
  };
  
  static final Map<String, String> weatherTranslations = {
    'sunny': 'සූර්යාලෝක',
    'rainy': 'වර්ෂාව',
    'stormy': 'කුණාටුව',
    'foggy': 'මීදුම',
  };
  
  static final Map<String, String> characterTranslations = {
    'hare': 'කුරුල්ලා',
    'lion': 'සිංහයා',
    'elephant': 'අලියා',
  };
}