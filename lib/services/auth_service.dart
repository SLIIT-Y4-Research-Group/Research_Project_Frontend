import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userTypeKey = 'user_type';
  static const String _parentIdKey = 'parent_id';

  Future<void> saveToken(String token, String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userTypeKey, userType);
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

  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> isParent() async {
    final userType = await getUserType();
    return userType == 'parent';
  }

  Future<bool> isChild() async {
    final userType = await getUserType();
    return userType == 'child';
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_parentIdKey);
  }
}