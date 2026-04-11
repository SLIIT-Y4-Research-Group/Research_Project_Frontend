class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.180.12:8000',
  );

  // API Endpoints
  static const String apiBase = '$baseUrl';
  static const String storiesEndpoint = '$apiBase/stories';
  static const String aiGenerateEndpoint = '$apiBase/ai/generate-story';
  static const String healthEndpoint = '$apiBase/health';
  static const String aiTestEndpoint = '$apiBase/ai/test-generate';
  
  // App settings
  static const String appName = 'StoryGen AI';
  static const int storyGenerationTimeout = 60; // seconds
  static const int maxStoryLength = 2000;
  
  // Feature flags
  static const bool enableAiGeneration = true;
  static const bool enableLocalStorage = true;
  
  // Mood mappings (must match backend)
  static final Map<String, String> moodMappings = {
    'sad': 'sad',
    'anxious': 'anxious',
    'empty': 'empty',
    'calm': 'calm',
    'happy': 'happy',
    'angry': 'angry',
    'confused': 'confused',
    'hopeful': 'hopeful',
  };
  
  static final Map<String, String> weatherMappings = {
    'sunny': 'sunny',
    'rainy': 'rainy',
    'stormy': 'stormy',
    'foggy': 'foggy',
  };
  
  static final Map<String, String> characterMappings = {
    'hare': 'hare',
    'lion': 'lion',
    'elephant': 'elephant',
  };
}