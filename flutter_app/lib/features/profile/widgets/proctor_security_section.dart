import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../proctor_profile_controller.dart';

class ProctorSecuritySection extends ConsumerWidget {
  const ProctorSecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileController = ref.read(proctorProfileControllerProvider.notifier);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          _buildSecurityCard(
            icon: Icons.lock,
            iconColor: Colors.purple,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () => profileController.changePassword(),
          ),

          const SizedBox(height: 12),

          _buildSecurityCard(
            icon: Icons.security,
            iconColor: Colors.blue,
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            onTap: () {
              // TODO: Implement 2FA
            },
          ),

          const SizedBox(height: 12),

          _buildSecurityCard(
            icon: Icons.devices,
            iconColor: Colors.green,
            title: 'Device Management',
            subtitle: 'Manage trusted devices',
            onTap: () {
              // TODO: Implement device management
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}