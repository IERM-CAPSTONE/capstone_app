import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'profile_controller.dart';
import 'widgets/profile_header.dart';
import 'widgets/personal_info_section.dart';
import 'widgets/device_verification_section.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/face_enrollment_section.dart';
import 'widgets/face_registration_section.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final profileController = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundGradientEnd,
      appBar: AppBar(
        backgroundColor: AppColors.appBarOrange,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Hồ sơ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.language, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundGradientStart, AppColors.backgroundGradientEnd],
          ),
        ),
        child: profileState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.appBarOrange))
            : SingleChildScrollView(
                child: Column(
                  children: [
                    if (profileState.user != null) ProfileHeader(user: profileState.user!),
                    const SizedBox(height: 24),
                    const PersonalInfoSection(),
                    const SizedBox(height: 24),
                    if (profileState.user?.role?.toUpperCase() == 'STUDENT')
                      const FaceRegistrationSection(),
                    if (profileState.user?.role?.toUpperCase() == 'STUDENT')
                      const SizedBox(height: 24),
                    if (profileState.user?.role?.toUpperCase() == 'HALL_INVIGILATOR' ||
                        profileState.user?.role?.toUpperCase() == 'PROCTOR')
                      const DeviceVerificationSection(),
                    if (profileState.user?.role?.toUpperCase() == 'HALL_INVIGILATOR' ||
                        profileState.user?.role?.toUpperCase() == 'PROCTOR')
                      const SizedBox(height: 24),
                    if (profileState.user?.role?.toUpperCase() == 'HALL_INVIGILATOR' ||
                        profileState.user?.role?.toUpperCase() == 'PROCTOR' ||
                        profileState.user?.role?.toUpperCase() == 'EXAM_OFFICER')
                      const FaceEnrollmentSection(),
                    if (profileState.user?.role?.toUpperCase() == 'HALL_INVIGILATOR' ||
                        profileState.user?.role?.toUpperCase() == 'PROCTOR' ||
                        profileState.user?.role?.toUpperCase() == 'EXAM_OFFICER')
                      const SizedBox(height: 24),
                    
                    // Nút Đăng xuất thiết kế lại
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => profileController.logout(context),
                          icon: const Icon(Icons.logout_rounded, color: Colors.red),
                          label: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}