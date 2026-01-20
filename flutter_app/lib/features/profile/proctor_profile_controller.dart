import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../data/models/user_model.dart';
import 'proctor_profile_state.dart';

class ProctorProfileController extends StateNotifier<ProctorProfileState> {
  ProctorProfileController() : super(ProctorProfileState.initial()) {
    // UI-only: use mock data, no backend calls.
    loadMockProctorProfile();
  }

  void loadMockProctorProfile() {
    state = state.copyWith(
      isLoading: false,
      error: null,
      user: UserModel(
        id: 'PRO001',
        email: 'proctor@fpt.edu.vn',
        name: 'Nguyen Van Proctor',
        phone: '+84 912 345 679',
        avatar: '',
        role: 'proctor',
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
    StateNotifierProvider<ProctorProfileController, ProctorProfileState>((ref) {
  return ProctorProfileController();
});