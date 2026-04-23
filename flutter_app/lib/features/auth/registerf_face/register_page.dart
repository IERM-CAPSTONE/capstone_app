import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/dialogs/data_consent_dialog.dart';
import 'register_face_scan_page.dart';

class RegisterFaceStartPage extends StatelessWidget {
  final String? targetStudentCode;
  final bool showCompletionInfo;

  const RegisterFaceStartPage({
    super.key,
    this.targetStudentCode,
    this.showCompletionInfo = false,
  });

  bool get _isProctorMode =>
      targetStudentCode != null && targetStudentCode!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isVietnamese = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('vi');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isProctorMode
              ? (isVietnamese
                  ? 'Đăng ký khuôn mặt sinh viên'
                  : 'Register student face')
              : (isVietnamese
                  ? 'Đăng ký nhận diện khuôn mặt'
                  : 'Register face identity'),
        ),
        backgroundColor: AppColors.appBarOrange,
        foregroundColor: Colors.white,
        elevation: 0,
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
                Text(
                  _isProctorMode
                      ? (isVietnamese
                          ? 'Sẵn sàng đăng ký khuôn mặt cho sinh viên?'
                          : 'Ready to register this student face?')
                      : (isVietnamese
                          ? 'Sẵn sàng đăng ký khuôn mặt?'
                          : 'Ready to register your face?'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_isProctorMode) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.badge_outlined,
                            color: AppColors.appBarOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isVietnamese
                                ? 'Mã sinh viên: ${targetStudentCode!}'
                                : 'Student code: ${targetStudentCode!}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _StepCard(
                  stepNumber: 1,
                  title: isVietnamese ? 'Quét khuôn mặt' : 'Scan face',
                  description: isVietnamese
                      ? 'Đảm bảo khuôn mặt hiển thị rõ ràng. Không đeo kính, mũ hoặc khẩu trang.'
                      : 'Make sure the face is clearly visible. Do not wear glasses, a hat, or a mask.',
                  icon: Icons.face_retouching_natural,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () async {
                      final agreed = await DataConsentDialog.show(context);
                      if (!agreed || !context.mounted) return;

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RegisterFaceScanIntroPage(
                            targetStudentCode: targetStudentCode,
                            showCompletionInfo: showCompletionInfo,
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.appBarOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isVietnamese ? 'Tiếp tục' : 'Continue'),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.appBarOrange,
            ),
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: AppColors.appBarOrange),
        ],
      ),
    );
  }
}
