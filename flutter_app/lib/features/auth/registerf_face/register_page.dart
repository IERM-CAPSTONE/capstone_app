import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/dialogs/data_consent_dialog.dart';
import 'register_face_scan_page.dart';

/// Static UI - Step 1 for ID verification.
/// Pressing "Start" navigates to step 2.
class RegisterFaceStartPage extends StatelessWidget {
  const RegisterFaceStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.verifyIdentity),
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
                  l10n.readyToVerify,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _StepCard(
                  stepNumber: 1,
                  title: l10n.step1Title,
                  description: l10n.step1Desc,
                  icon: Icons.face_retouching_natural,
                ),
                const SizedBox(height: 12),
                _StepCard(
                  stepNumber: 2,
                  title: l10n.step2Title,
                  description: l10n.step2Desc,
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
                      backgroundColor: AppColors.appBarOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.continueText),
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
                    height: 1.2,
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
