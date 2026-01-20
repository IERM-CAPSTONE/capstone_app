import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'config/env.dart';
import 'config/dependency_injection.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

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

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
