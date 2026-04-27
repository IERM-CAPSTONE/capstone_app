import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../profile_controller.dart';

class FaceRecognitionSection extends ConsumerWidget {
  const FaceRecognitionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final role = profileState.user?.role?.toUpperCase();
    final isProctorOrInvigilator = role == 'PROCTOR' || role == 'HALL_INVIGILATOR';
    
    final canSuperviseFaceEnrollment = {
      'ADMIN',
      'EXAM_OFFICER',
      'HALL_INVIGILATOR',
    }.contains(role);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhận diện khuôn mặt',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          
          if (!isProctorOrInvigilator) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: profileState.isFaceRegistered ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    profileState.isFaceRegistered ? Icons.verified_user_rounded : Icons.face_rounded,
                    color: profileState.isFaceRegistered ? Colors.green : AppColors.appBarOrange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      profileState.isFaceRegistered ? 'Đã đăng ký nhận diện' : 'Chưa đăng ký khuôn mặt',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.faceEnrollmentOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appBarOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cập nhật khuôn mặt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          
          if (canSuperviseFaceEnrollment) ...[
            if (!isProctorOrInvigilator) const Divider(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.faceEnrollmentDashboard),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
                label: const Text('Giám sát đăng ký SV'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}