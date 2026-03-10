import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/story/story_model.dart';

class LocalStoryStorage {
  static const _keyStories = 'saved_stories';

  // Save a story
  static Future<void> saveStory(Story story) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing stories
    final storiesJson = prefs.getStringList(_keyStories) ?? [];

    // Add new story
    storiesJson.add(jsonEncode(story.toJson()));

    // Save back
    await prefs.setStringList(_keyStories, storiesJson);
  }

  // Get all saved stories
  static Future<List<Story>> getStories() async {
    final prefs = await SharedPreferences.getInstance();
    final storiesJson = prefs.getStringList(_keyStories) ?? [];

    return storiesJson
        .map((jsonStr) => Story.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  // Clear all saved stories (optional)
  static Future<void> clearStories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStories);
  }
}