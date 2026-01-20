import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../proctor_profile_controller.dart';

class ProctorPersonalInfoSection extends ConsumerWidget {
  const ProctorPersonalInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(proctorProfileControllerProvider);
    final user = profileState.user;

    if (user == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          _buildInfoRow(
            icon: Icons.email,
            iconColor: Colors.blue,
            label: 'Email',
            value: user.email,
          ),

          const SizedBox(height: 12),

          _buildInfoRow(
            icon: Icons.phone,
            iconColor: Colors.green,
            label: 'Phone Number',
            value: user.phone ?? 'Not provided',
          ),

          const SizedBox(height: 12),

          _buildInfoRow(
            icon: Icons.badge,
            iconColor: Colors.purple,
            label: 'Employee ID',
            value: user.id,
          ),

          const SizedBox(height: 12),

          _buildInfoRow(
            icon: Icons.work,
            iconColor: const Color(0xFFFF6B35),
            label: 'Department',
            value: 'Examination Department',
          ),

          const SizedBox(height: 12),

          _buildInfoRow(
            icon: Icons.location_on,
            iconColor: Colors.red,
            label: 'Campus',
            value: 'FPT University - Ho Chi Minh Campus',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
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
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}