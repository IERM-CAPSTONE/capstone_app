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
    defaultValue: '3000',
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
    return 'http://$redisHost:$apiPort/api';
  }
  
  static int get apiPortInt {
    return int.tryParse(apiPort) ?? 3000;
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

