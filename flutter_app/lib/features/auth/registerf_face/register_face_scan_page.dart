import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'register_face_live_scan_page.dart';

class RegisterFaceScanIntroPage extends StatelessWidget {
  final String? targetStudentCode;
  final bool showCompletionInfo;

  const RegisterFaceScanIntroPage({
    super.key,
    this.targetStudentCode,
    this.showCompletionInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final isVietnamese = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('vi');

    return Scaffold(
      appBar: AppBar(
        title: Text(isVietnamese ? 'Quét khuôn mặt' : 'Scan face'),
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
              children: [
                const SizedBox(height: 8),
                Text(
                  isVietnamese
                      ? 'Sẵn sàng quét khuôn mặt?'
                      : 'Ready to scan the face?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 160,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 240,
                        decoration: const ShapeDecoration(
                          shape: OvalBorder(
                            side: BorderSide(
                              color: AppColors.appBarOrange,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                      ClipOval(
                        child: SizedBox(
                          width: 152,
                          height: 232,
                          child: Image.asset(
                            'assets/avatar_face.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Center(
                                child: Icon(Icons.person, size: 60),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    _Hint(
                      icon: Icons.crop_free,
                      text: isVietnamese
                          ? 'Giữ khuôn mặt trong khung'
                          : 'Keep the face inside the frame',
                    ),
                    _Hint(
                      icon: Icons.wb_sunny_outlined,
                      text: isVietnamese
                          ? 'Tránh ánh sáng quá gắt hoặc quá tối'
                          : 'Avoid harsh light or darkness',
                    ),
                    _Hint(
                      icon: Icons.no_accounts,
                      text: isVietnamese
                          ? 'Không đội mũ, đeo kính râm hoặc khẩu trang'
                          : 'No hat, sunglasses, or mask',
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RegisterFaceLiveScanPage(
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
                    child: Text(isVietnamese ? 'Bắt đầu quét' : 'Start scan'),
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

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Hint({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.appBarOrange),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
