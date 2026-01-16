import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/user_model.dart';
import 'profile_state.dart';

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController() : super(ProfileState.initial()) {
    // UI-only: use mock data, no backend calls.
    loadMockUserProfile();
  }

  void loadMockUserProfile() {
    state = state.copyWith(
      isLoading: false,
      error: null,
      user: UserModel(
        id: 'SE140123',
        email: 'anvv@fpt.edu.vn',
        name: 'Nguyen Van An',
        phone: '+84 912 345 678',
        avatar: '',
        role: 'student',
        createdAt: null,
        updatedAt: null,
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    // UI-only: just navigate back to login screen.
    if (context.mounted) {
      context.go(AppRoutes.login);
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
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController();
});
