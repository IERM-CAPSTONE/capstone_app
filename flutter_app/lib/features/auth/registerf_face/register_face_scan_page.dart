import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'register_face_live_scan_page.dart';

class RegisterFaceScanIntroPage extends StatelessWidget {
  const RegisterFaceScanIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isVietnamese =
        Localizations.localeOf(context).languageCode.toLowerCase().startsWith('vi');

    return Scaffold(
      appBar: AppBar(
        title: Text(isVietnamese ? 'Qu\u00e9t khu\u00f4n m\u1eb7t' : 'Scan your face'),
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
                      ? 'S\u1eb5n s\u00e0ng qu\u00e9t khu\u00f4n m\u1eb7t?'
                      : 'Ready to scan your face?',
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
                          ? 'Gi\u1eef khu\u00f4n m\u1eb7t trong khung'
                          : 'Keep your face inside the frame',
                    ),
                    _Hint(
                      icon: Icons.wb_sunny_outlined,
                      text: isVietnamese
                          ? 'Tr\u00e1nh \u00e1nh s\u00e1ng qu\u00e1 g\u1eaft ho\u1eb7c qu\u00e1 t\u1ed1i'
                          : 'Avoid harsh light or darkness',
                    ),
                    _Hint(
                      icon: Icons.no_accounts,
                      text: isVietnamese
                          ? 'Kh\u00f4ng \u0111\u1ed9i m\u0169, \u0111eo k\u00ednh r\u00e2m ho\u1eb7c kh\u1ea9u trang'
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
                          builder: (_) => const RegisterFaceLiveScanPage(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.appBarOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isVietnamese ? 'B\u1eaft \u0111\u1ea7u qu\u00e9t' : 'Start scan',
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
