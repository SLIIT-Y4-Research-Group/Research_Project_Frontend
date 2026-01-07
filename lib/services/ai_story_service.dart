import 'dart:convert';
import '../core/config.dart';
import '../models/api_response.dart';
import '../models/mood_model.dart';
import '../models/story_model.dart';
import 'api_service.dart';

// Update AIStoryService.dart:

class AIStoryService {
  final ApiService _apiService = ApiService();

  AIStoryService();

  /// Generate story using AI model (GRU backend)
  Future<ApiResponse<Map<String, dynamic>>> generateStory({
    required String mood,
    required String weather,
    required String character,
    String? starterSentence,
    int maxLength = 200,
  }) async {
    try {
      final requestData = {
        'mood': mood,
        'weather': weather,
        'character': character,
        'max_length': maxLength,
        'temperature': 0.7,
        if (starterSentence != null && starterSentence.isNotEmpty)
          'starter_sentence': starterSentence,
      };

      print('[AI Service] Sending request to: ${AppConfig.aiGenerateEndpoint}');
      print('[AI Service] Request data: ${jsonEncode(requestData)}');

      final response = await _apiService.postData(
        AppConfig.aiGenerateEndpoint,
        requestData,
      );

      print('[AI Service] Raw response: ${jsonEncode(response.data)}');
      print('[AI Service] Response success: ${response.success}');
      print('[AI Service] Response message: ${response.message}');

      if (response.success) {
        final data = response.data ?? {};
        
        // DEBUG: Print the actual response structure
        print('[AI Service] Response keys: ${data.keys.toList()}');
        
        // Your backend returns {success: bool, story: str, metadata: dict}
        if (data.containsKey('story')) {
          return ApiResponse.success({
            'success': true,
            'story': data['story'] ?? 'කථාව නිර්මාණය කරන ලදී',
            'metadata': data['metadata'] ?? {},
            'generated_at': DateTime.now().toIso8601String(),
          });
        } else {
          // Fallback if structure is different
          print('[AI Service] Warning: Response missing "story" key');
          return ApiResponse.success({
            'success': true,
            'story': jsonEncode(data), // Fallback to show the data
            'metadata': {},
            'generated_at': DateTime.now().toIso8601String(),
          });
        }
      } else {
        print('[AI Service] Error: ${response.message}');
        return ApiResponse.error(
          response.message ?? 'AI story generation failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('[AI Service] Exception: $e');
      return ApiResponse.error('කථාව නිර්මාණය කිරීමට නොහැකි විය: $e');
    }
  }


  /// Generate and save story in one call
  Future<ApiResponse<Map<String, dynamic>>> generateAndSaveStory({
    required String userId,
    required MoodProfile moodProfile,
    String? customTitle,
  }) async {
    try {
      // Step 1: Generate story using AI
      final aiResponse = await generateStory(
        mood: moodProfile.mood,
        weather: moodProfile.weather,
        character: moodProfile.character,
        starterSentence: moodProfile.starterSentence,
      );

      if (!aiResponse.success) {
        return aiResponse;
      }

      final aiData = aiResponse.data!;

      // Step 2: Create story object for saving
      final story = {
        'user_id': userId,
        'title': customTitle ?? 'AI නිර්මාණය කළ කථාව',
        'content': aiData['story'] ?? '',
        'mood_profile': moodProfile.toJson(),
        'tags': ['ai-generated', moodProfile.mood, moodProfile.character],
        'is_public': false,
      };

      // Step 3: Save to backend
      final saveResponse = await _apiService.postData(
        AppConfig.storiesEndpoint,
        story,
      );

      if (!saveResponse.success) {
        return ApiResponse.error(
          saveResponse.message ?? 'කථාව සුරැකීම අසාර්ථක විය',
          statusCode: saveResponse.statusCode,
        );
      }

      return ApiResponse.success({
        'story': saveResponse.data,
        'ai_generated': true,
        'generation_time': DateTime.now().toIso8601String(),
        'message': 'කථාව සාර්ථකව නිර්මාණය කර සුරැකිනි',
      });
    } catch (e) {
      return ApiResponse.error('කථාව නිර්මාණය කිරීම හා සුරැකීම අසාර්ථක විය: $e');
    }
  }

  /// Check if AI service is available
  Future<ApiResponse<Map<String, dynamic>>> checkAIService() async {
    try {
      final response = await _apiService.getData('${AppConfig.apiBase}/ai/health');

      if (response.success) {
        return ApiResponse.success({
          'status': 'healthy',
          'model': 'GRU',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        return ApiResponse.error(
          response.message ?? 'AI සේවාව නොමැත',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error('AI සේවාව පරීක්ෂා කිරීමට නොහැකි විය: $e');
    }
  }
  Future<ApiResponse<Map<String, dynamic>>> testAIConnection() async {
  try {
    final requestData = {
      'mood': 'happy',
      'weather': 'sunny',
      'character': 'hare',
      'starter_sentence': 'අද දවස මට ගොඩක් සතුටක්',
      'max_length': 100,
      'temperature': 0.7,
    };

    print('[Test] Testing AI endpoint: ${AppConfig.aiGenerateEndpoint}');
    
    // First try the test endpoint
    final testResponse = await _apiService.postData(
      '${AppConfig.apiBase}/ai/test-generate',
      requestData,
    );

    if (testResponse.success) {
      print('[Test] Test endpoint successful!');
      return ApiResponse.success({
        'success': true,
        'message': 'Test endpoint works',
        'data': testResponse.data,
      });
    }

    // If test endpoint fails, try the real one
    print('[Test] Trying real endpoint...');
    final realResponse = await _apiService.postData(
      AppConfig.aiGenerateEndpoint,
      requestData,
    );

    if (realResponse.success) {
      return ApiResponse.success({
        'success': true,
        'message': 'Real endpoint works',
        'data': realResponse.data,
      });
    }

    return ApiResponse.error('Both endpoints failed');
    
  } catch (e) {
    print('[Test] Connection test error: $e');
    return ApiResponse.error('Connection test failed: $e');
  }
}

}