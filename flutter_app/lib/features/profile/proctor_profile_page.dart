import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'proctor_profile_controller.dart';
import 'widgets/proctor_profile_header.dart';
import 'widgets/proctor_personal_info_section.dart';
import 'widgets/proctor_device_verification_section.dart';
import 'widgets/bottom_nav_bar.dart';

class ProctorProfilePage extends ConsumerWidget {
  const ProctorProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(proctorProfileControllerProvider);
    final profileController = ref.read(proctorProfileControllerProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.backgroundGradientEnd,
      appBar: AppBar(
        backgroundColor: AppColors.appBarOrange,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Hồ sơ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.appBarOrange))
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (profileState.user != null) ProctorProfileHeader(user: profileState.user!),
                  const SizedBox(height: 24),
                  const ProctorPersonalInfoSection(),
                  const SizedBox(height: 24),
                  const ProctorDeviceVerificationSection(),
                  const SizedBox(height: 24),

                  // Action Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.orange),
                          ),
                          title: const Text('Giám sát đăng ký khuôn mặt', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Dành cho Giám thị hành lang'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push(AppRoutes.faceEnrollmentDashboard),
                        ),
                        const Divider(indent: 70),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.logout_rounded, color: Colors.red),
                          ),
                          title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          onTap: () => profileController.logout(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}