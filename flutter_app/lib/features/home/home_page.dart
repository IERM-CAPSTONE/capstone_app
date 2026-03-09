import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/registerf_face/register_page.dart';
import '../../config/dependency_injection.dart';
import '../../data/services/auth_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../profile/widgets/bottom_nav_bar.dart';

import '../../l10n/generated/app_localizations.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/language_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarOrange,
        elevation: 0,
        title: Text(
          l10n.studentHomepage,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => _showLanguageBottomSheet(context, ref),
          ),
        ],
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
        child: const Center(
          child: SizedBox(),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
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
