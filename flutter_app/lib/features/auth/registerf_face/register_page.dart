import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/dialogs/data_consent_dialog.dart';
import 'register_face_scan_page.dart';

class RegisterFaceStartPage extends StatelessWidget {
  const RegisterFaceStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isVietnamese =
        Localizations.localeOf(context).languageCode.toLowerCase().startsWith('vi');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isVietnamese
              ? '\u0110\u0103ng k\u00fd nh\u1eadn di\u1ec7n khu\u00f4n m\u1eb7t'
              : 'Register face identity',
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
                  isVietnamese
                      ? 'S\u1eb5n s\u00e0ng \u0111\u0103ng k\u00fd khu\u00f4n m\u1eb7t?'
                      : 'Ready to register your face?',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _StepCard(
                  stepNumber: 1,
                  title: isVietnamese ? 'Qu\u00e9t khu\u00f4n m\u1eb7t' : 'Scan your face',
                  description: isVietnamese
                      ? '\u0110\u1ea3m b\u1ea3o khu\u00f4n m\u1eb7t c\u1ee7a b\u1ea1n hi\u1ec3n th\u1ecb r\u00f5 r\u00e0ng. Kh\u00f4ng \u0111eo k\u00ednh, m\u0169 ho\u1eb7c kh\u1ea9u trang.'
                      : 'Make sure your face is clearly visible. Do not wear glasses, a hat, or a mask.',
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
                          builder: (_) => const RegisterFaceScanIntroPage(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.appBarOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isVietnamese ? 'Ti\u1ebfp t\u1ee5c' : 'Continue',
                    ),
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
