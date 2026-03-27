import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/dependency_injection.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/realtime_notification_service.dart';
import '../../../l10n/generated/app_localizations.dart';
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

  Future<void> loginWithGoogle(BuildContext context) async {
    if (!state.canLogin) return;

    state = state.copyWith(isLoading: true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final authService = DependencyInjection.get<AuthService>();

      final firebaseUser = await authService.signInWithGoogle();
      if (firebaseUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      final backendResponse =
          await authService.verifyFirebaseTokenWithBackend(idToken);

      final accessToken = backendResponse['accessToken'] as String?;
      final refreshToken = backendResponse['refreshToken'] as String?;
      final userData = backendResponse['user'] as Map<String, dynamic>?;

      if (accessToken == null || userData == null) {
        throw Exception('Invalid backend response: missing tokens or user data');
      }

      await authService.saveTokens(accessToken, refreshToken);

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

      final realtimeNotificationService =
          DependencyInjection.get<RealtimeNotificationService>();
      await realtimeNotificationService.restartWithLatestAuth();

      if (context.mounted) {
        final upperRole = userModel.role?.toUpperCase() ?? 'STUDENT';
        final allowedRoles = [
          'STUDENT',
          'PROCTOR',
          'HALL_INVIGILATOR',
          'IT_SUPPORT'
        ];

        if (!allowedRoles.contains(upperRole)) {
          await authService.signOut();
          if (context.mounted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Bạn không có quyền truy cập ứng dụng này!'),
                backgroundColor: Colors.red,
              ),
            );
            state = state.copyWith(isLoading: false);
            return;
          }
        }

        context.go(AppRoutes.examSchedule);
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.authFailed),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
