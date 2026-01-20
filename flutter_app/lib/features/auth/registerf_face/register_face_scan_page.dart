import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'register_second_page.dart';

/// Static UI - Face scan intro screen (Step before ID capture).
/// Pressing "Start scan" navigates to the ID capture page.
class RegisterFaceScanIntroPage extends StatelessWidget {
  const RegisterFaceScanIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan your face'),
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
                const Text(
                  'Ready to scan your face?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                // Avatar in oval frame with outline
                SizedBox(
                  width: 160,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 🔵 Viền oval chuẩn
                      Container(
                        width: 160,
                        height: 240,
                        decoration: ShapeDecoration(
                          shape: OvalBorder(
                            side: BorderSide(
                              color: AppColors.appBarOrange,
                              width: 4,
                            ),
                          ),
                        ),
                      ),

                      // 🖼 Avatar oval chuẩn
                      ClipOval(
                        child: SizedBox(
                          width: 152,
                          height: 232,
                          child: Image.asset(
                            'assets/avatar_face.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
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
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _Hint(
                      icon: Icons.crop_free,
                      text: 'Keep your face\ninside the frame',
                    ),
                    _Hint(
                      icon: Icons.wb_sunny_outlined,
                      text: 'Avoid harsh light\nor darkness',
                    ),
                    _Hint(
                      icon: Icons.no_accounts,
                      text: 'No hat, sunglasses,\nor mask',
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
                          builder: (_) => const RegisterFaceIdCapturePage(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.appBarOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Start scan'),
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
      width: 98,
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
