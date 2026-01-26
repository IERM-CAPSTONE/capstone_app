import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';
import '../data/services/auth_service.dart';
import '../data/services/face_registration_service.dart';
import '../data/services/socket_service.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/exam_session_repository.dart';
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
          // Skip auth for login/register endpoints
          final requiresAuth = options.extra['requiresAuth'] != false;
          final isAuthEndpoint = options.path.contains('/auth/');

          if (requiresAuth && !isAuthEndpoint) {
            final token = prefs.getString('auth_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Unwrap backend response wrapper
          if (response.data is Map) {
            final data = response.data as Map<String, dynamic>;
            // Check if response is wrapped with {success, statusCode, data}
            if (data.containsKey('data') && data.containsKey('success')) {
              final innerData = data['data'];
              
              // Check type of innerData
              if (innerData is Map) {
                // innerData is Map - check if it's paginated
                final innerMap = innerData as Map;
                final isPaginated = innerMap.containsKey('data') && innerMap.containsKey('total');
                
                if (isPaginated) {
                  print('📦 DEBUG: Paginated response (keep wrapper for retrofit)');
                  // Keep as-is: {success, data: {data: [...], total, ...}}
                } else {
                  print('📦 DEBUG: Single object (unwrap)');
                  // Unwrap: {success, data: {id, ...}} → {id, ...}
                  response.data = innerData;
                }
              } else if (innerData is List) {
                print('📦 DEBUG: Direct list response (keep wrapper for retrofit)');
                // innerData is List - this is also paginated, keep wrapper
                // {success, data: [...]}
              } else {
                print('📦 DEBUG: Unknown data type: ${innerData.runtimeType}');
              }
            }
          }
          
          // Debug log for exam-sessions endpoint
          if (response.requestOptions.path.contains('exam-sessions/')) {
            print('📡 DEBUG HTTP Response (after processing):');
            print('   URL: ${response.requestOptions.path}');
            print('   Status: ${response.statusCode}');
            print('   Data type: ${response.data.runtimeType}');
            if (response.data is Map) {
              final keys = (response.data as Map).keys.toList();
              print('   Keys: $keys');
              if (keys.contains('id')) {
                print('   id field: ${(response.data as Map)['id']}');
              }
            }
          }
          return handler.next(response);
        },
      ),
    );

    _dependencies[Dio] = dio;

    // Initialize ApiService
    final apiService = ApiService(dio);
    _dependencies[ApiService] = apiService;

    // Initialize FaceRegistrationService
    final faceService = FaceRegistrationService(dio);
    _dependencies[FaceRegistrationService] = faceService;

    // Initialize SocketService
    final socketService = SocketService();
    _dependencies[SocketService] = socketService;

    // Initialize AuthService
    final authService = AuthService(dio);
    await authService.init();
    _dependencies[AuthService] = authService;

    // Initialize Repositories
    _dependencies[UserRepository] = UserRepository(apiService);
    _dependencies[ExamSessionRepository] = ExamSessionRepository(apiService);
    

    _initialized = true;
  }

  static T get<T>() {
    final dependency = _dependencies[T];
    if (dependency == null) {
      throw Exception(
          'Dependency $T not found. Make sure to call init() first.');
    }
    return dependency as T;
  }
}
