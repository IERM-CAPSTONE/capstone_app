import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'login_state.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>(
  (ref) => LoginController(),
);

class LoginController extends StateNotifier<LoginState> {
  LoginController() : super(const LoginState());

  void selectCampus(String campus) {
    state = state.copyWith(selectedCampus: campus);
  }

  void clearCampus() {
    state = state.copyWith(selectedCampus: null);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  Future<bool> loginWithGoogle() async {
    if (!state.canLogin) return false;
    
    state = state.copyWith(isLoading: true);
    
    try {
      // Get a real JWT token from the backend test-token endpoint
      // This is a development endpoint that generates valid tokens
      final dio = Dio();
      final response = await dio.post(
        'http://10.0.2.2:3001/api/auth/test-token',
        data: {
          'userId': 'test-student-${DateTime.now().millisecondsSinceEpoch}',
          'role': 'STUDENT',
        },
      );
      
      if (response.statusCode == 200) {
        final token = response.data['accessToken'] as String?;
        if (token != null && token.isNotEmpty) {
          // Store the real JWT token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('campus', state.selectedCampus ?? '');
          
          state = state.copyWith(isLoading: false);
          return true;
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get auth token from server',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }
  
  // Check if user is already logged in
  Future<bool> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

