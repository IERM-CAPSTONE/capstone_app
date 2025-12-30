import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'config/env.dart';
import 'config/dependency_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

