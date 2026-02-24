import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'login_state.dart';
import '../../../config/dependency_injection.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/routes/app_routes.dart';

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

  Future<void> loginWithGoogle(BuildContext context) async {
    if (!state.canLogin) return;

    state = state.copyWith(isLoading: true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Get auth service from dependency injection
      final authService = DependencyInjection.get<AuthService>();

      // 1. Sign in with Firebase
      final firebaseUser = await authService.signInWithGoogle();

      if (firebaseUser == null) {
        // User cancelled sign-in
        state = state.copyWith(isLoading: false);
        return;
      }

      // 2. Get Firebase ID token
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // 3. Send Firebase token to backend for verification
      final backendResponse =
          await authService.verifyFirebaseTokenWithBackend(idToken);

      // 4. Extract tokens from backend response
      final accessToken = backendResponse['accessToken'] as String?;
      final refreshToken = backendResponse['refreshToken'] as String?;
      final userData = backendResponse['user'] as Map<String, dynamic>?;

      if (accessToken == null || userData == null) {
        throw Exception(
            'Invalid backend response: missing tokens or user data');
      }

      // 5. Save tokens locally
      await authService.saveTokens(accessToken, refreshToken);

      // 6. Create and save user model
      final userModel = UserModel(
        id: userData['id'] as String? ?? firebaseUser.uid,
        email: userData['email'] as String? ?? firebaseUser.email ?? '',
        fullName: userData['fullName'] as String? ??
            userData['name'] as String? ??
            firebaseUser.displayName ??
            'User',
        role: userData['role'] as String? ?? 'student',
        avatarUrl: userData['avatarUrl'] as String? ??
            userData['avatar'] as String? ??
            firebaseUser.photoURL,
        code: userData['code'] as String?,
      );

      await authService.saveUserData(userModel);

      // 7. Navigate to home
      if (context.mounted) {
        if (userModel.role == 'PROCTOR' || userModel.role == 'proctor') {
          context.go(AppRoutes.proctorDashboard);
        } else {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      print('❌ Google sign-in error: $e');
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thất bại. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
