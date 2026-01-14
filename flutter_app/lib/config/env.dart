import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class Env {
  // Redis Configuration
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
  
  // API Configuration
  static const String apiPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '3002',
  );
  
  // Background Worker Configuration
  static const String backgroundPort = String.fromEnvironment(
    'BACKGROUND_PORT',
    defaultValue: '3001',
  );
  
  static Future<void> init() async {
    // Initialize environment variables
    // Can load from .env file or other sources
  }
  
  // Computed properties
  static String get apiBaseUrl {
    // On Android emulator, use 10.0.2.2 to access host machine's localhost
    // This is a fixed IP that works on ALL Android emulators, no need to change per machine
    // On web and other platforms, use the configured host
    String host = redisHost;
    if (!kIsWeb && Platform.isAndroid) {
      // 10.0.2.2 is the special IP that Android emulator uses to access host machine's localhost
      // This works on ALL machines without needing to know the actual IP address
      if (host == 'localhost' || host == '127.0.0.1') {
        host = '10.0.2.2';
      }
    }
    return 'http://$host:$apiPort/api';
  }
  
  static int get apiPortInt {
    return int.tryParse(apiPort) ?? 3002;
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

