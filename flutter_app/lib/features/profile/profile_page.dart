import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/language_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'profile_controller.dart';
import 'widgets/profile_header.dart';
import 'widgets/personal_info_section.dart';
import 'widgets/face_recognition_section.dart';
import 'widgets/personal_info_section.dart';
import 'widgets/profile_header.dart';
import 'widgets/proctor_device_verification_section.dart';
import 'widgets/bottom_nav_bar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final profileController = ref.read(profileControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundGradientEnd,
      appBar: AppBar(
        backgroundColor: AppColors.appBarOrange,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.profile,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => _showLanguageBottomSheet(context, ref),
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
                  color: AppColors.appBarOrange,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    if (profileState.user != null)
                      ProfileHeader(user: profileState.user!),
                    const SizedBox(height: 24),
                    const PersonalInfoSection(),
                    const SizedBox(height: 24),
                    const FaceRecognitionSection(),
                    const SizedBox(height: 24),
                    const ProctorDeviceVerificationSection(),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => profileController.logout(context),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Đăng xuất',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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

  void _showLanguageBottomSheet(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.language,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
                title: Text(l10n.vietnamese),
                trailing: currentLocale.languageCode == 'vi'
                    ? const Icon(Icons.check, color: AppColors.appBarOrange)
                    : null,
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('vi');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: Text(l10n.english),
                trailing: currentLocale.languageCode == 'en'
                    ? const Icon(Icons.check, color: AppColors.appBarOrange)
                    : null,
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('en');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
