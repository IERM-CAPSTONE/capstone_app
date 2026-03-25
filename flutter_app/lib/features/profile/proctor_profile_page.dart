import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'proctor_profile_controller.dart';
import 'widgets/proctor_profile_header.dart';
import 'widgets/proctor_personal_info_section.dart';
import 'widgets/proctor_device_verification_section.dart';
import 'widgets/proctor_security_section.dart';
import 'widgets/proctor_help_support_section.dart';
import 'widgets/bottom_nav_bar.dart';

class ProctorProfilePage extends ConsumerWidget {
  const ProctorProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(proctorProfileControllerProvider);
    final profileController =
        ref.read(proctorProfileControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarOrange,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.proctorProfile,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: profileState.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.appBarOrange),
                ),
              )
            : profileState.user == null
                ? const Center(child: Text('No user data'))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header Section
                        ProctorProfileHeader(user: profileState.user!),

                        const SizedBox(height: 24),

                        // Personal Information Section
                        const ProctorPersonalInfoSection(),

                        const SizedBox(height: 24),

                        // Device Verification Section
                        const ProctorDeviceVerificationSection(),

                        const SizedBox(height: 24),

                        // Security Section
                        const ProctorSecuritySection(),

                        const SizedBox(height: 24),

                        // Help & Support Section
                        ProctorHelpSupportSection(
                          onLogout: () => profileController.logout(context),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}
