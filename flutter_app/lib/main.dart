import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'config/dependency_injection.dart';
import 'config/env.dart';
import 'data/services/auth_service.dart';
import 'data/services/push_notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi', null);
  await initializeDateFormatting('en', null);

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (e is FirebaseException && e.code == 'duplicate-app') {
      debugPrint('Firebase already initialized: $e');
    } else {
      rethrow;
    }
  }

  await Env.init();
  await DependencyInjection.init();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final pushNotificationService =
      DependencyInjection.get<PushNotificationService>();
  final authService = DependencyInjection.get<AuthService>();
  if (authService.isLoggedIn()) {
    await pushNotificationService.init();
    await pushNotificationService.syncTokenWithBackend(force: true);
  }

  runApp(const ProviderScope(child: MyApp()));
}
