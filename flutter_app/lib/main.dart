import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'config/env.dart';
import 'config/dependency_injection.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:dio/dio.dart';
import 'core/routes/app_routes.dart';
import 'data/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Initialize environment
  await Env.init();

  // Initialize dependency injection
  await DependencyInjection.init();

  // Setup global 401 handler
  final dio = DependencyInjection.get<Dio>();
  final authService = DependencyInjection.get<AuthService>();
  
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          print('⚠️ Received 401 Unauthorized. Logging out and redirecting to login...');
          await authService.signOut();
          AppRoutes.router.go(AppRoutes.login);
        }
        return handler.next(error);
      },
    ),
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
