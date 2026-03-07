import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userTypeKey = 'user_type'; // 'parent' or 'child'

  // Save token
  Future<void> saveToken(String token, String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userTypeKey, userType);
  }

  // Get token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get user type
  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Check if parent
  Future<bool> isParent() async {
    final userType = await getUserType();
    return userType == 'parent';
  }

  // Check if child
  Future<bool> isChild() async {
    final userType = await getUserType();
    return userType == 'child';
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userTypeKey);
  }
}
