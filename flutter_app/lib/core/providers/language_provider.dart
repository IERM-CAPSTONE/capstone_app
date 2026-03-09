import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/dependency_injection.dart';

class LanguageState extends StateNotifier<Locale> {
  LanguageState() : super(const Locale('vi')) {
    _loadLanguage();
  }

  void _loadLanguage() {
    final prefs = DependencyInjection.get<SharedPreferences>();
    final languageCode = prefs.getString('language_code') ?? 'vi';
    state = Locale(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = DependencyInjection.get<SharedPreferences>();
    await prefs.setString('language_code', languageCode);
    state = Locale(languageCode);
  }
}

final languageProvider = StateNotifierProvider<LanguageState, Locale>((ref) {
  return LanguageState();
});
