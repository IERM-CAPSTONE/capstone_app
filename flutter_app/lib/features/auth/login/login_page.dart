import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import 'login_controller.dart';
import 'login_state.dart';
import '../../../core/providers/language_provider.dart';

import '../../../l10n/generated/app_localizations.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginControllerProvider);
    final loginController = ref.read(loginControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Main content
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
                      // Logo
                      _buildLogo(),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        l10n.fptExamManagement,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        l10n.secureExamSystem,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(flex: 1),
                      // Login Card
                      _buildLoginCard(
                          context, loginState, loginController, l10n),
                      const Spacer(flex: 2),
                      // Copyright
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
                  // Language Switcher Positioned
                  Positioned(
                    top: 10,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.language, color: Colors.white),
                      onPressed: () => _showLanguageBottomSheet(context, ref),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay
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
          // Welcome Back heading
          Text(
            l10n.welcomeBack,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Instruction text
          Text(
            l10n.signInGoogle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          // Login Button
          _buildLoginButton(context, state, controller, isEnabled, l10n),
        ],
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
                  // Google Logo
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

  void _showLanguageBottomSheet(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(languageProvider);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.language,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
                title: Text(l10n.vietnamese),
                trailing: currentLocale.languageCode == 'vi'
                    ? const Icon(Icons.check, color: AppColors.appBarOrange)
                    : null,
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('vi');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                title: Text(l10n.english),
                trailing: currentLocale.languageCode == 'en'
                    ? const Icon(Icons.check, color: AppColors.appBarOrange)
                    : null,
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('en');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
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
