import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';
import '../models/api_response.dart';
import '../models/story_model.dart';
import '../models/mood_model.dart';


class ApiService {
  late Dio _dio;
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() => _instance;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBase,
      connectTimeout: const Duration(seconds: 120),  // increase if needed
  receiveTimeout: const Duration(seconds: 120),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }
  
  // Health check
  Future<ApiResponse<Map<String, dynamic>>> checkHealth() async {
    try {
      final response = await _dio.get(AppConfig.healthEndpoint);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data?['detail'] ?? 'Server connection failed',
        statusCode: e.response?.statusCode,
        error: e,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }
  
  // Create a story
  Future<ApiResponse<Story>> createStory(Story story) async {
    try {
      final response = await _dio.post(
        AppConfig.storiesEndpoint,
        data: story.toJson(),
      );
      
      final createdStory = Story.fromJson(response.data);
      return ApiResponse.success(createdStory, message: 'Story created successfully');
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data?['detail'] ?? 'Failed to create story',
        statusCode: e.response?.statusCode,
        error: e,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }
  
  // Get user stories
  Future<ApiResponse<List<Story>>> getUserStories(String userId, {int limit = 20}) async {
    try {
      final response = await _dio.get(
        '${AppConfig.storiesEndpoint}/user/$userId',
        queryParameters: {'limit': limit},
      );
      
      final stories = (response.data as List)
          .map((json) => Story.fromJson(json))
          .toList();
      
      return ApiResponse.success(stories);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data?['detail'] ?? 'Failed to fetch stories',
        statusCode: e.response?.statusCode,
        error: e,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }
  
  // Get public stories
  Future<ApiResponse<List<Story>>> getPublicStories({int limit = 20}) async {
    try {
      final response = await _dio.get(
        '${AppConfig.storiesEndpoint}/public/',
        queryParameters: {'limit': limit},
      );
      
      final stories = (response.data as List)
          .map((json) => Story.fromJson(json))
          .toList();
      
      return ApiResponse.success(stories);
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data?['detail'] ?? 'Failed to fetch public stories',
        statusCode: e.response?.statusCode,
        error: e,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }
  
  // Update story
  Future<ApiResponse<Story>> updateStory(Story story) async {
    try {
      final response = await _dio.put(
        '${AppConfig.storiesEndpoint}/${story.id}',
        data: story.toJson(),
      );
      
      final updatedStory = Story.fromJson(response.data);
      return ApiResponse.success(updatedStory, message: 'Story updated successfully');
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data?['detail'] ?? 'Failed to update story',
        statusCode: e.response?.statusCode,
        error: e,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }
  
  // Delete story
  Future<ApiResponse<void>> deleteStory(String storyId) async {
    try {
      await _dio.delete('${AppConfig.storiesEndpoint}/$storyId');
      return ApiResponse.success(null, message: 'Story deleted successfully');
    } on DioException catch (e) {
      return ApiResponse.error(
        e.response?.data?['detail'] ?? 'Failed to delete story',
        statusCode: e.response?.statusCode,
        error: e,
      );
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }
  // POST helper
Future<ApiResponse<Map<String, dynamic>>> postData(
    String endpoint, Map<String, dynamic> data) async {
  try {
    final response = await _dio.post(endpoint, data: data);
    return ApiResponse.success(response.data);
  } on DioException catch (e) {
    return ApiResponse.error(
      e.response?.data?['detail'] ?? 'Request failed',
      statusCode: e.response?.statusCode,
      error: e,
    );
  }
}

// GET helper
Future<ApiResponse<Map<String, dynamic>>> getData(String endpoint) async {
  try {
    final response = await _dio.get(endpoint);
    return ApiResponse.success(response.data);
  } on DioException catch (e) {
    return ApiResponse.error(
      e.response?.data?['detail'] ?? 'Request failed',
      statusCode: e.response?.statusCode,
      error: e,
    );
  }
}

}

