import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../profile_controller.dart';

String _humanizeRole(String? role) {
  if (role == null || role.trim().isEmpty) return 'N/A';
  final parts = role.replaceAll('_', ' ').split(RegExp(r"\s+"));
  return parts.map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}').join(' ');
}

class PersonalInfoSection extends ConsumerWidget {
  const PersonalInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final user = profileState.user;

    if (user == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              AppLocalizations.of(context)!.personalInformation,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          _buildInfoRow(
            icon: Icons.email,
            iconColor: Colors.blue,
            label: AppLocalizations.of(context)!.email,
            value: user.email ?? '',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            iconColor: Colors.indigo,
            label: 'Mã cán bộ',
            value: user.code ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.location_on,
            iconColor: Colors.teal,
            label: AppLocalizations.of(context)!.campus,
            value: user.campus ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.work_outline,
            iconColor: Colors.orange,
            label: 'Vai trò',
            value: _humanizeRole(user.role),
          ),

          /*
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.phone,
            iconColor: Colors.green,
            label: 'Phone Number',
            value: user.phone ?? 'Not provided',
          ),
          */

          /* 
          // Class and Major fields are not yet available in the database
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.group,
            iconColor: Colors.purple,
            label: 'Class',
            value: 'SE1401', // TODO: Get from user model
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoRow(
            icon: Icons.school,
            iconColor: const Color(0xFFFF6B35),
            label: 'Major',
            value: 'Software Engineering', // TODO: Get from user model
          ),
          */
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
                    fontSize: 12,
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
