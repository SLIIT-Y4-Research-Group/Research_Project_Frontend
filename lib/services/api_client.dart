import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiClient {
  static final AuthService _authService = AuthService();

  static Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = {"Content-Type": "application/json"};
    
    if (includeAuth) {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }
    
    return headers;
  }

  // Parent Registration
  static Future<http.Response> registerParent(String email, String password) async {
    return await http.post(
      Uri.parse('${ApiConfig.BASE_URL}/auth/parent/register'),
      headers: await _getHeaders(),
      body: jsonEncode({"email": email, "password": password}),
    );
  }

  // Parent Login
  static Future<http.Response> loginParent(String email, String password) async {
    return await http.post(
      Uri.parse('${ApiConfig.BASE_URL}/auth/parent/login'),
      headers: await _getHeaders(),
      body: jsonEncode({"email": email, "password": password}),
    );
  }

  // Child Login
  static Future<http.Response> loginChild(String username, String password) async {
    return await http.post(
      Uri.parse('${ApiConfig.BASE_URL}/auth/child/login'),
      headers: await _getHeaders(),
      body: jsonEncode({"username": username, "password": password}),
    );
  }

  // Get Children (Parent)
  static Future<http.Response> getChildren() async {
    return await http.get(
      Uri.parse('${ApiConfig.BASE_URL}/parent/children'),
      headers: await _getHeaders(includeAuth: true),
    );
  }

  // Add Child (Parent)
  static Future<http.Response> addChild({
    required String username,
    required String password,
    required String name,
    required int age,
  }) async {
    return await http.post(
      Uri.parse('${ApiConfig.BASE_URL}/parent/children'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({
        "username": username,
        "password": password,
        "name": name,
        "age": age,
      }),
    );
  }

  // Invite Trusted Contact (Parent)
  static Future<http.Response> inviteTrustedContact(
    String childId,
    String email,
    {String? relationship}
  ) async {
    final payload = {"email": email};
    if (relationship != null && relationship.isNotEmpty) {
      payload["relationship"] = relationship;
    }
    return await http.post(
      Uri.parse('${ApiConfig.BASE_URL}/parent/children/$childId/trusted'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode(payload),
    );
  }

  // Remove Trusted Contact (Parent)
  static Future<http.Response> removeTrustedContact(
    String childId,
    String trustedId,
    String reason,
  ) async {
    return await http.post(
      Uri.parse('${ApiConfig.BASE_URL}/parent/children/$childId/trusted/$trustedId/remove'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({"reason": reason}),
    );
  }

  // List Trusted Contacts (Parent)
  static Future<http.Response> getTrustedContacts(String childId) async {
    return await http.get(
      Uri.parse('${ApiConfig.BASE_URL}/parent/children/$childId/trusted'),
      headers: await _getHeaders(includeAuth: true),
    );
  }

  // Update Child Consent
  static Future<http.Response> updateChildConsent(bool alertsConsent) async {
    return await http.patch(
      Uri.parse('${ApiConfig.BASE_URL}/child/me/consent'),
      headers: await _getHeaders(includeAuth: true),
      body: jsonEncode({"alerts_consent": alertsConsent}),
    );
  }

  // Get Child Info
  static Future<http.Response> getChildInfo() async {
    return await http.get(
      Uri.parse('${ApiConfig.BASE_URL}/child/me'),
      headers: await _getHeaders(includeAuth: true),
    );
  }
}
