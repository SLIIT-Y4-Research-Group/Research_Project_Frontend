import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userTypeKey = 'user_type';
  static const String _parentIdKey = 'parent_id';
  static const String _childIdKey = 'child_id';
  static const String _childNameKey = 'child_name';

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

  Future<void> saveChildId(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_childIdKey, childId);
  }

  Future<String?> getChildId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_childIdKey);
  }

  Future<void> saveChildName(String childName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_childNameKey, childName);
  }

  Future<String?> getChildName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_childNameKey);
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
    await prefs.remove(_childIdKey);
    await prefs.remove(_childNameKey);
  }
}