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
          // Nền Gradient tinh tế hơn
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8C5A), Color(0xFFFF6B35)],
              ),
            ),
          ),
          
          // Hình tròn trang trí cho nền
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.topRight,
                    child: _buildLanguageDropdown(context, ref, currentLocale.languageCode),
                  ),
                  const Spacer(flex: 2),
                  _buildLogo(),
                  const SizedBox(height: 24),
                  Text(
                    l10n.fptExamManagement,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.secureExamSystem,
                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w400),
                  ),
                  const Spacer(flex: 2),
                  _buildLoginCard(context, loginState, loginController, l10n),
                  const Spacer(flex: 3),
                  Text(
                    l10n.copyright,
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          if (loginState.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Image.asset(AppAssets.fptLogo, width: 70, height: 70),
    );
  }

  Widget _buildLoginCard(BuildContext context, LoginState state, LoginController controller, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        children: [
          const Text(
            'Chào mừng trở lại',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            'Đăng nhập để bắt đầu phiên làm việc',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => controller.loginWithGoogle(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Image.asset(AppAssets.googleLogo, width: 18),
                  ),
                  const SizedBox(width: 14),
                  const Text('Tiếp tục với Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown(BuildContext context, WidgetRef ref, String currentLanguageCode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(currentLanguageCode.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}