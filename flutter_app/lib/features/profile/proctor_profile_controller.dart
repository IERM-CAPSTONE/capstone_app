import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/user_model.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import 'proctor_profile_state.dart';

class ProctorProfileController extends StateNotifier<ProctorProfileState> {
  ProctorProfileController() : super(ProctorProfileState.initial()) {
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final authService = DependencyInjection.get<AuthService>();
      final user = await authService.getSavedUserData();
      
      if (user != null) {
        state = state.copyWith(
          isLoading: false,
          user: user,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'User data not found',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      final authService = DependencyInjection.get<AuthService>();
      await authService.signOut();
      
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  Future<void> changePassword() async {
    // TODO: Implement password change
  }

  Future<void> verifyNewDevice() async {
    // TODO: Implement device verification
  }

  Future<void> requestSupport() async {
    // TODO: Implement support request
  }
}

final proctorProfileControllerProvider =
    StateNotifierProvider.autoDispose<ProctorProfileController, ProctorProfileState>((ref) {
  return ProctorProfileController();
});