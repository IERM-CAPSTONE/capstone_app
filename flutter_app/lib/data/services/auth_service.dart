import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiService _apiService;
  final SharedPreferences _prefs;
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  AuthService(this._apiService, this._prefs);
  
  // Login
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiService.login({
        'email': email,
        'password': password,
      });
      
      final token = response['token'] as String;
      final userData = response['user'] as Map<String, dynamic>;
      
      // Save token
      await _prefs.setString(_tokenKey, token);
      
      // Save user data
      final user = UserModel.fromJson(userData);
      await _prefs.setString(_userKey, user.toJson().toString());
      
      return user;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: ${e.toString()}');
    }
  }
  
  // Register
  Future<UserModel> register(String email, String password, String name) async {
    try {
      final response = await _apiService.register({
        'email': email,
        'password': password,
        'name': name,
      });
      
      final token = response['token'] as String;
      final userData = response['user'] as Map<String, dynamic>;
      
      // Save token
      await _prefs.setString(_tokenKey, token);
      
      // Save user data
      final user = UserModel.fromJson(userData);
      await _prefs.setString(_userKey, user.toJson().toString());
      
      return user;
    } catch (e) {
      throw Exception('Register failed: ${e.toString()}');
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_userKey);
    }
  }
  
  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      return await _apiService.getCurrentUser();
    } catch (e) {
      return null;
    }
  }
  
  // Check if user is logged in
  bool isLoggedIn() {
    return _prefs.containsKey(_tokenKey);
  }
  
  // Get token
  String? getToken() {
    return _prefs.getString(_tokenKey);
  }
}

