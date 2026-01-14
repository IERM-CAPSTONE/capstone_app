import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      // For mobile app, we'll use a simplified OAuth flow
      // The backend needs to return tokens directly for mobile
      // For now, simulate successful login and store a mock token
      
      final prefs = await SharedPreferences.getInstance();
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Store mock auth token (in real app, this comes from backend)
      await prefs.setString('auth_token', 'mock_token_${DateTime.now().millisecondsSinceEpoch}');
      await prefs.setString('campus', state.selectedCampus ?? '');
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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

