import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import 'profile_controller.dart';
import 'widgets/profile_header.dart';
import 'widgets/personal_info_section.dart';
import 'widgets/face_recognition_section.dart';
import 'widgets/security_section.dart';
import 'widgets/help_support_section.dart';
import 'widgets/bottom_nav_bar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final profileController = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35), // Orange color
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
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
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      
                      const SizedBox(height: 24),
                      
                      // Security Section
                      const SecuritySection(),
                      
                      const SizedBox(height: 24),
                      
                      // Help & Support Section
                      HelpSupportSection(
                        onLogout: () => profileController.logout(context),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }
}
