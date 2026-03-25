import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'profile_controller.dart';
import 'widgets/profile_header.dart';
import 'widgets/personal_info_section.dart';
import 'widgets/face_recognition_section.dart';
import 'widgets/help_support_section.dart';
import 'widgets/bottom_nav_bar.dart';

import '../../core/providers/language_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final profileController = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarOrange,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppLocalizations.of(context)!.profile,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () {
              _showLanguageBottomSheet(context, ref);
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
                        ProfileHeader(user: profileState.user!),

                        const SizedBox(height: 24),

                        // Personal Information Section
                        const PersonalInfoSection(),

                        const SizedBox(height: 24),

                        // Face Recognition Section
                        const FaceRecognitionSection(),

                        /*
                        const SizedBox(height: 24),

                        // Security Section
                        const SecuritySection(),
                        */

                        const SizedBox(height: 24),

                        // Help & Support Section
                        HelpSupportSection(
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

  void _showLanguageBottomSheet(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(languageProvider);
    final l10n = AppLocalizations.of(context);

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
                l10n!.language,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
                title: Text(l10n!.vietnamese),
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
                title: Text(l10n!.english),
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
