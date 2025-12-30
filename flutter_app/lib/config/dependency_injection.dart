import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';
import '../data/services/auth_service.dart';
import '../data/services/camera_service.dart';
import '../data/repositories/user_repository.dart';
import 'env.dart';

class DependencyInjection {
  static final Map<Type, dynamic> _dependencies = {};
  static bool _initialized = false;
  
  static Future<void> init() async {
    if (_initialized) return;
    
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _dependencies[SharedPreferences] = prefs;
    
    // Initialize Dio
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: Duration(milliseconds: Env.apiTimeoutMs),
        receiveTimeout: Duration(milliseconds: Env.apiTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
    
    // Add interceptors for auth token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
    
    _dependencies[Dio] = dio;
    
    // Initialize ApiService
    final apiService = ApiService(dio);
    _dependencies[ApiService] = apiService;
    
    // Initialize Services
    _dependencies[AuthService] = AuthService(apiService, prefs);
    
    // Initialize Repositories
    _dependencies[UserRepository] = UserRepository(apiService);
    
    _initialized = true;
  }
  
  static T get<T>() {
    final dependency = _dependencies[T];
    if (dependency == null) {
      throw Exception('Dependency $T not found. Make sure to call init() first.');
    }
    return dependency as T;
  }
}

