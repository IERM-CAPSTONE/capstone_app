import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/dialogs/data_consent_dialog.dart';
import 'register_face_scan_page.dart';

/// Static UI - Step 1 for ID verification.
/// Pressing "Start" navigates to step 2.
class RegisterFaceStartPage extends StatelessWidget {
  const RegisterFaceStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your identity (2 steps)'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Ready to verify your identity?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _StepCard(
                stepNumber: 1,
                title: 'Scan your face',
                description:
                    'Make sure your face is clearly visible.\n(No glasses, hat, or mask)',
                icon: Icons.face_retouching_natural,
              ),
              const SizedBox(height: 12),
              _StepCard(
                stepNumber: 2,
                title: 'Capture both sides of your ID',
                description: 'Take photos of the front and back of your ID card.',
                icon: Icons.credit_card,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    // Show data consent dialog
                    final result = await DataConsentDialog.show(context);
                    
                    // If user agreed and selected storage duration, proceed
                    if (result != null && context.mounted) {
                      // result will be '7_days' or 'permanent'
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterFaceScanIntroPage(),
                        ),
                      );
                    }
                    // If result is null, user disagreed - don't navigate
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
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
              color: AppColors.accentLight,
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
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: AppColors.accent),
        ],
      ),
    );
  }
}
