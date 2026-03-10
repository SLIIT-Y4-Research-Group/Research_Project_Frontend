import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';
  static const String _parentIdKey = 'parent_id';

  Future<void> saveToken(String token, String role) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);

    final decoded = JwtDecoder.decode(token);
    final userId = decoded['id']?.toString();

    if (role == 'parent' && userId != null) {
      await prefs.setString(_parentIdKey, userId);
    }
  }

  Future<void> saveParentId(String parentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_parentIdKey, parentId);
  }

  Future<String?> getParentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_parentIdKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_parentIdKey);
  }
}