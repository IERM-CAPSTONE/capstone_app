import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Placeholder for future login functionality
  Future<void> loginWithGoogle() async {
    if (!state.canLogin) return;
    
    state = state.copyWith(isLoading: true);
    // TODO: Implement Google login
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(isLoading: false);
  }
}

