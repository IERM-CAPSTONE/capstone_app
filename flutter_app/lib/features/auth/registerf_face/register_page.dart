import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/dialogs/data_consent_dialog.dart';
import '../../face_enrollment/student/face_storage_consent_page.dart';
import '../../face_enrollment/student/otp_input_page.dart';

class RegisterFaceStartPage extends StatelessWidget {
  final String? targetStudentCode;
  final bool showCompletionInfo;

  const RegisterFaceStartPage({
    super.key,
    this.targetStudentCode,
    this.showCompletionInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isStaffTargeted =
        targetStudentCode != null && targetStudentCode!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký khuôn mặt'),
        backgroundColor: AppColors.appBarOrange,
        foregroundColor: Colors.white,
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Sẵn sàng đăng ký khuôn mặt?',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _StepCard(
                  stepNumber: 1,
                  title: isStaffTargeted ? 'Chuẩn bị quét' : 'Nhập mã OTP',
                  description: isStaffTargeted
                      ? 'Dữ liệu sẽ được đăng ký cho sinh viên $targetStudentCode. Vui lòng hướng camera về phía sinh viên.'
                      : 'Vui lòng nhập mã OTP từ giám thị hành lang để tiếp tục.',
                  icon: isStaffTargeted ? Icons.camera_alt : Icons.vpn_key,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      if (isStaffTargeted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FaceStorageConsentPage(
                              targetStudentCode: targetStudentCode,
                              showCompletionInfo: showCompletionInfo,
                            ),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OtpInputPage(),
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.appBarOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tiếp tục'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.appBarOrange,
            child: Text('$stepNumber', style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Icon(icon, color: AppColors.appBarOrange),
        ],
      ),
    );
  }
}
