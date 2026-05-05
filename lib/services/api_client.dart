import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiClient {
  static final AuthService _authService = AuthService();

  static Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ================= AUTH =================

  static Future<http.Response> registerParent(String email, String password) async {
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/parent/register'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
  }

  static Future<http.Response> loginParent(String email, String password) async {
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/parent/login'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
  }

  static Future<http.Response> loginChild(String username, String password) async {
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/child/login'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
  }

  // ================= CHILD MANAGEMENT =================

  static Future<http.Response> getChildren() async {
    return await http.get(
      Uri.parse('${ApiConfig.baseUrl}/parent/children'),
      headers: await _getHeaders(includeAuth: true),
    );
  }

  static Future<http.Response> addChild({
    required String username,
    required String password,
    required String name,
    required int age,
  }) async {
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}/parent/children'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({
        'username': username,
        'password': password,
        'name': name,
        'age': age,
      }),
    );
  }

  // ================= TRUSTED CONTACTS =================

  static Future<http.Response> inviteTrustedContact(
    String childId,
    String email, {
    String? relationship,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      'relationship': (relationship != null && relationship.isNotEmpty)
          ? relationship
          : 'Other',
    };

    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}/parent/children/$childId/trusted'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode(payload),
    );
  }

  static Future<http.Response> removeTrustedContact(
    String childId,
    String trustedId,
    String reason,
  ) async {
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}/parent/children/$childId/trusted/$trustedId/remove'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({
        'reason': reason,
      }),
    );
  }

  static Future<http.Response> getTrustedContacts(String childId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return await http.get(
      Uri.parse('${ApiConfig.baseUrl}/parent/children/$childId/trusted?_t=$timestamp'),
      headers: await _getHeaders(includeAuth: true),
    );
  }

  // ================= MOOD =================

  static Future<http.Response> storeMood({
    required String mood,
    required String datetime,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.STORE_MOOD_ENDPOINT),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({
        "mood": mood,
        "datetime": datetime,
      }),
    );

    print('[API] storeMood - Status: ${response.statusCode}, Body: ${response.body}');
    return response;
  }

  static Future<http.Response> getTodayMoodStatus() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/child/me/today-mood-status'),
      headers: await _getHeaders(includeAuth: true),
    );

    print('[API] getTodayMoodStatus - Status: ${response.statusCode}, Body: ${response.body}');
    return response;
  }

  static Future<http.Response> getWeeklyMoods() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/child/me/weekly-moods'),
      headers: await _getHeaders(includeAuth: true),
    );

    print('[API] getWeeklyMoods - Status: ${response.statusCode}, Body: ${response.body}');
    return response;
  }

  // ================= CHILD SETTINGS =================

  static Future<http.Response> updateChildConsent(bool alertsConsent) async {
    return await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/child/me/consent'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({
        'alerts_consent': alertsConsent,
      }),
    );
  }

  static Future<http.Response> respondAlertPermission({
    required bool approve,
  }) async {
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}/mood/respond_alert_permission'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({
        "approve": approve,
      }),
    );
  }

  static Future<http.Response> getChildInfo() async {
    return await http.get(
      Uri.parse('${ApiConfig.baseUrl}/child/me'),
      headers: await _getHeaders(includeAuth: true),
    );
  }

  static Future<http.Response> markFirstLoginPromptSeen() async {
    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}/child/me/first-login-seen'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({}),
    );
  }

  static Future<http.Response> resetChildPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/child/me/reset-password'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
  }

  // ================= DRAWINGS =================

  static Future<http.Response> getParentDrawings() async {
    return await http.get(
      Uri.parse('${ApiConfig.baseUrl}/parent/drawings'),
      headers: await _getHeaders(includeAuth: true),
    );
  }

  static Future<http.Response> getParentDrawingReports() async {
    return await http.get(
      Uri.parse('${ApiConfig.baseUrl}/drawing/parent/me'),
      headers: await _getHeaders(includeAuth: true),
    );
  }

  static Future<http.Response> getChildDrawingsGallery() async {
    return await http.get(
      Uri.parse('${ApiConfig.baseUrl}/drawing/child/me/gallery'),
      headers: await _getHeaders(includeAuth: true),
    );
  }

  static String getDrawingImageUrl(String analysisId) {
    return '${ApiConfig.baseUrl}/drawing/image/$analysisId';
  }

  // ================= THERAPY =================

  static Future<http.Response> logTherapySession({
    required String activityType,
    required int durationSeconds,
    int? score,
    int? roundsCompleted,
    String? triggeredByEmotion,
  }) async {
    final body = <String, dynamic>{
      'activity_type': activityType,
      'duration_seconds': durationSeconds,
    };

    if (score != null) body['score'] = score;
    if (roundsCompleted != null) body['rounds_completed'] = roundsCompleted;
    if (triggeredByEmotion != null) {
      body['triggered_by_emotion'] = triggeredByEmotion;
    }

    return await http.post(
      Uri.parse('${ApiConfig.baseUrl}/therapy/session'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> getChildReport({
    required String childId,
    int days = 30,
  }) async {
    return await http.get(
      Uri.parse('${ApiConfig.baseUrl}/therapy/report/$childId?days=$days'),
      headers: await _getHeaders(includeAuth: true),
    );
  }
}