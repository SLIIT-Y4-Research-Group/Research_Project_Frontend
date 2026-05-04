import 'package:flutter/material.dart';

class MoodProfile {
  final String mood;
  final String weather;
  final String character;
  final String? starterSentence;
  final String storyLength; // 'short', 'medium', 'long'
  final bool useGemini; // Option to use Gemini or local model
  final DateTime timestamp;

  MoodProfile({
    required this.mood,
    required this.weather,
    required this.character,
    this.starterSentence,
    this.storyLength = 'medium', // Default to medium
    this.useGemini = true, // Default to using Gemini if available
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'mood': mood,
      'weather': weather,
      'character': character,
      'starter_sentence': starterSentence,
      'story_length': storyLength,
      'use_gemini': useGemini,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Convert from JSON for API response
  factory MoodProfile.fromJson(Map<String, dynamic> json) {
    return MoodProfile(
      mood: json['mood'],
      weather: json['weather'],
      character: json['character'],
      starterSentence: json['starter_sentence'],
      storyLength: json['story_length'] ?? 'medium',
      useGemini: json['use_gemini'] ?? true,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // Get Sinhala display names
  String get moodSinhala => _getSinhalaMood(mood);
  String get weatherSinhala => _getSinhalaWeather(weather);
  String get characterSinhala => _getSinhalaCharacter(character);
  String get storyLengthSinhala => _getSinhalaStoryLength(storyLength);

  String _getSinhalaMood(String englishMood) {
    const translations = {
      'sad': 'දුක් සහගත',
      'anxious': 'කලබල',
      'empty': 'හිස්',
      'calm': 'සන්සුන්',
      'happy': 'සතුටු',
      'angry': 'කෝපවත්',
      'confused': 'ව්‍යාකූල',
      'hopeful': 'බලාපොරොත්තු',
    };
    return translations[englishMood] ?? englishMood;
  }

  String _getSinhalaWeather(String englishWeather) {
    const translations = {
      'sunny': 'සූර්යාලෝක',
      'rainy': 'වර්ෂාව',
      'stormy': 'කුණාටුව',
      'foggy': 'මීදුම',
    };
    return translations[englishWeather] ?? englishWeather;
  }

  String _getSinhalaCharacter(String englishCharacter) {
    const translations = {
      'hare': 'කුරුල්ලා',
      'lion': 'සිංහයා',
      'elephant': 'අලියා',
    };
    return translations[englishCharacter] ?? englishCharacter;
  }

  String _getSinhalaStoryLength(String length) {
    const translations = {
      'short': 'කෙටි',
      'medium': 'මධ්‍යම',
      'long': 'දිගු',
    };
    return translations[length] ?? length;
  }

  Color get moodColor {
    final colors = {
      'sad': Colors.blue,
      'anxious': Colors.orange,
      'empty': Colors.grey,
      'calm': Colors.green,
      'happy': Colors.yellow,
      'angry': Colors.red,
      'confused': Colors.purple,
      'hopeful': Colors.lightBlue,
    };
    return colors[mood] ?? Colors.deepPurple;
  }
}