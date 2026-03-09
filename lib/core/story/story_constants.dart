// lib/constants/story_constants.dart

class StoryConstants {
  // Common story starters that match Python backend
  static const List<String> commonStarters = [
    'අතීතයේ දී එක් සමයක',
    'පුරාණ කාලයේ දී',
    'එක් වරක් ඉතා පැරණි යුගයක',
    'බොහෝ අවුරුදු ගණනකට පෙර',
    'එක්තරා පැරණි ගමක',
    'සිසිල් හෙමන්ත ඍතුවේ දිනක',
    'හරිත වසන්තයේ දිනක',
    'දුර්ගම වනාන්තරයක',
  ];

  // Weather to Sinhala mapping
  static const Map<String, String> weatherSinhala = {
    'sunny': 'සූර්යාලෝක',
    'rainy': 'වර්ෂාව',
    'stormy': 'කුණාටුව',
    'foggy': 'මීදුම',
  };

  // Character to Sinhala mapping
  static const Map<String, String> characterSinhala = {
    'hare': 'කුරුල්ලා',
    'lion': 'සිංහයා',
    'elephant': 'අලියා',
  };

  // Mood to Sinhala mapping
  static const Map<String, String> moodSinhala = {
    'sad': 'දුක් සහගත',
    'anxious': 'කලබල',
    'empty': 'හිස්',
    'calm': 'සන්සුන්',
    'happy': 'සතුටු',
    'angry': 'කෝපවත්',
    'confused': 'ව්‍යාකූල',
    'hopeful': 'බලාපොරොත්තු',
  };
  static const Map<String, String> storyLengthSinhala = {
    'short': 'කෙටි',
    'medium': 'මධ්‍යම',
    'long': 'දිගු',
  };
  
  static const Map<String, String> storyLengthDescription = {
    'short': 'වාක්‍ය 3-4',
    'medium': 'වාක්‍ය 5-6',
    'long': 'වාක්‍ය 7-9',
  };
}