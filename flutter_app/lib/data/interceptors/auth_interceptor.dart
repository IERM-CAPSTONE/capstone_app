import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Get the auth token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    // Add the token to the Authorization header if it exists
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if the error is due to unauthorized (401)
    if (err.response?.statusCode == 401) {
      // Token is invalid or expired
      // In a real app, you would try to refresh the token here
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    }
    
    return handler.next(err);
  }
}
