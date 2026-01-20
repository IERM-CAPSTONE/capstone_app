import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Static UI - Step 2 for ID verification.
/// This screen only shows instructions to capture both sides of an ID.
class RegisterFaceIdCapturePage extends StatelessWidget {
  const RegisterFaceIdCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture your ID'),
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
                const Text(
                  'Capture both sides of your ID',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Make sure the photo is sharp, well-lit, and the entire card is visible.',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _GuideCard(
                        title: 'Front side',
                        subtitle: 'Photo of the front of your ID card',
                        icon: Icons.badge,
                        color: AppColors.appBarOrange.withOpacity(0.8),
                        onColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GuideCard(
                        title: 'Back side',
                        subtitle: 'Photo of the back of your ID card',
                        icon: Icons.badge_outlined,
                        color: AppColors.appBarOrange,
                        onColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _TipRow(
                  icon: Icons.crop_free,
                  text: 'Keep the ID inside the frame.',
                ),
                const SizedBox(height: 10),
                _TipRow(
                  icon: Icons.wb_sunny_outlined,
                  text: 'Avoid glare and reflections.',
                ),
                const SizedBox(height: 10),
                _TipRow(
                  icon: Icons.visibility_outlined,
                  text: 'Make sure all text is readable.',
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      // UI only (no camera flow yet)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'UI only: capture flow not implemented yet.'),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.appBarOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Start capture'),
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

class _GuideCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color onColor;

  const _GuideCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: onColor),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: onColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: onColor.withOpacity(0.85),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.appBarOrange),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(height: 1.2),
          ),
        ),
      ],
    );
  }
}
