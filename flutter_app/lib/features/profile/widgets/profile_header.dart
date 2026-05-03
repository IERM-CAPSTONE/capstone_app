import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../core/constants/app_colors.dart';

String _humanizeRole(String? role) {
  if (role == null || role.trim().isEmpty) return '';
  final parts = role.replaceAll('_', ' ').split(RegExp(r"\s+"));
  return parts.map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}').join(' ');
}

class ProfileHeader extends StatelessWidget {
  final UserModel user;

  const ProfileHeader({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF6B35),
                width: 3,
              ),
            ),
            child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      user.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            (user.fullName ?? 'No Name').toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          if (user.role?.toLowerCase() == 'student' && user.code != null && user.code!.isNotEmpty)
            Text(
              user.code!.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            )
          else if (user.role != null && user.role!.isNotEmpty)
            Text(
              _humanizeRole(user.role),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

          if (user.role?.toLowerCase() == 'student' && user.code != null && user.code!.isNotEmpty)
            const SizedBox(height: 8)
          else if (user.role != null && user.role!.isNotEmpty)
            const SizedBox(height: 8),

          const SizedBox(height: 12),

          // University Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF6B35),
                width: 1,
              ),
            ),
            child: const Text(
              'FPT University',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFF6B35),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.person,
      size: 50,
      color: Color(0xFFFF6B35),
    );
  }
}
