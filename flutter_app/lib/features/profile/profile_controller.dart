import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/user_model.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import 'profile_state.dart';

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController() : super(ProfileState.initial()) {
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
        // Fallback or handle null user (maybe redirect to login?)
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

  Future<void> updateFaceData() async {
    // TODO: Implement face data update
  }

  Future<void> changePassword() async {
    // TODO: Implement password change
  }

  Future<void> requestSupport() async {
    // TODO: Implement support request
  }
}

final profileControllerProvider =
    StateNotifierProvider.autoDispose<ProfileController, ProfileState>((ref) {
  return ProfileController();
});
