import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class Env {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'apiBaseUrl',
    defaultValue: 'https://4891-171-231-192-153.ngrok-free.app/api',
  );

  // Redis Configuration (if needed for direct access)
  static const String redisHost = String.fromEnvironment(
    'REDIS_HOST',
    defaultValue: 'localhost',
  );

  static const String redisPort = String.fromEnvironment(
    'REDIS_PORT',
    defaultValue: '6379',
  );

  static const String redisPassword = String.fromEnvironment(
    'REDIS_PASSWORD',
    defaultValue: '',
  );

  // Background Worker Configuration
  static const String backgroundPort = String.fromEnvironment(
    'BACKGROUND_PORT',
    defaultValue: '3002',
  );

  static Future<void> init() async {
    // Initialize environment variables
    // Can load from .env file or other sources
  }

  static int get redisPortInt {
    return int.tryParse(redisPort) ?? 6379;
  }

  static int get backgroundPortInt {
    return int.tryParse(backgroundPort) ?? 3001;
  }

  static int get apiTimeoutMs {
    return 30000; // Default timeout: 30 seconds
  }
}
