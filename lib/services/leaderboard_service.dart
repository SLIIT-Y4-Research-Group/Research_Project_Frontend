import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<LeaderboardEntry> createEntry({
    required String playerName,
    required int score,
    required int level,
    required double time,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/leaderboard'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'player_name': playerName,
        'score': score,
        'level': level,
        'time': time,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create entry (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return LeaderboardEntry.fromJson(data);
  }

  static Future<List<LeaderboardEntry>> getTop({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/leaderboard/top?limit=$limit'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch top scores (${response.statusCode}).');
    }

    return _parseListResponse(response.body);
  }

  static Future<List<LeaderboardEntry>> getLeaderboard({
    int skip = 0,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/leaderboard?skip=$skip&limit=$limit'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch leaderboard (${response.statusCode}).');
    }

    return _parseListResponse(response.body);
  }

  static Future<List<LeaderboardEntry>> getPlayerEntries(
    String playerName, {
    int skip = 0,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/leaderboard/player/${Uri.encodeComponent(playerName)}?skip=$skip&limit=$limit',
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch player scores (${response.statusCode}).');
    }

    return _parseListResponse(response.body);
  }

  static Future<LeaderboardEntry> getEntry(String entryId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/leaderboard/$entryId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch entry (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return LeaderboardEntry.fromJson(data);
  }

  static Future<void> deleteEntry(String entryId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/leaderboard/$entryId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete entry (${response.statusCode}).');
    }
  }

  static List<LeaderboardEntry> _parseListResponse(String body) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LeaderboardEntry.fromJson)
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final dynamic listValue =
          decoded['items'] ?? decoded['results'] ?? decoded['data'];
      if (listValue is List) {
        return listValue
            .whereType<Map<String, dynamic>>()
            .map(LeaderboardEntry.fromJson)
            .toList();
      }
    }

    return [];
  }
}
