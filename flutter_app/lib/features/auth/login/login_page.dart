import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'login_controller.dart';
import 'login_state.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginControllerProvider);
    final loginController = ref.read(loginControllerProvider.notifier);
    final currentLocale = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.loginGradientStart,
                  AppColors.loginGradientEnd,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      const Spacer(flex: 2),
                      _buildLogo(),
                      const SizedBox(height: 16),
                      Text(
                        l10n.fptExamManagement,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.secureExamSystem,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(flex: 1),
                      _buildLoginCard(
                        context,
                        loginState,
                        loginController,
                        l10n,
                      ),
                      const Spacer(flex: 2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          l10n.copyright,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 10,
                    right: 16,
                    child: _buildLanguageDropdown(
                      context,
                      ref,
                      currentLocale.languageCode,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (loginState.isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.appBarOrange),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.loggingIn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          AppAssets.fptLogo,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLoginCard(
    BuildContext context,
    LoginState state,
    LoginController controller,
    AppLocalizations l10n,
  ) {
    const isEnabled = true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.welcomeBack,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.signInGoogle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _buildLoginButton(context, state, controller, isEnabled, l10n),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown(
    BuildContext context,
    WidgetRef ref,
    String currentLanguageCode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white54),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLanguageCode,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          selectedItemBuilder: (context) => const [
            _LanguageDropdownValue(label: 'VI'),
            _LanguageDropdownValue(label: 'EN'),
          ],
          items: const [
            DropdownMenuItem<String>(
              value: 'vi',
              child: Text(
                'Tiếng Việt',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'en',
              child: Text(
                'English',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              ref.read(languageProvider.notifier).setLanguage(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoginButton(
    BuildContext context,
    LoginState state,
    LoginController controller,
    bool isEnabled,
    AppLocalizations l10n,
  ) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? [
                    AppColors.loginButtonEnabled,
                    AppColors.loginButtonEnabled.withOpacity(0.9),
                  ]
                : [
                    AppColors.loginButtonDisabled,
                    AppColors.loginButtonDisabled,
                  ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.loginButtonEnabled.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled && !state.isLoading
                ? () => controller.loginWithGoogle(context)
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGoogleLogo(),
                  const SizedBox(width: 12),
                  Text(
                    l10n.loginWithGoogle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

Widget _buildGoogleLogo() {
  return Image.asset(
    AppAssets.googleLogo,
    width: 20,
    height: 20,
    fit: BoxFit.contain,
  );
}

class _LanguageDropdownValue extends StatelessWidget {
  const _LanguageDropdownValue({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.language, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
