import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/dependency_injection.dart';
import '../../core/routes/app_routes.dart';
import '../../firebase_options.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'realtime_notification_service.dart';
import 'socket_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint('FCM background message received: ${message.messageId}');
}

class PushNotificationService {
  static const String _storedTokenKey = 'fcm_token';
  static const String _storedUserIdKey = 'fcm_user_id';
  static const String _storedDeviceIdKey = 'fcm_device_id';

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin;
  final AuthService _authService;
  final Dio _dio;
  final SharedPreferences _prefs;

  bool _initialized = false;
  bool _localNotificationReady = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  StreamSubscription<RemoteMessage>? _openMessageSub;

  PushNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
    required AuthService authService,
    required Dio dio,
    required SharedPreferences prefs,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotificationsPlugin =
            localNotificationsPlugin ?? FlutterLocalNotificationsPlugin(),
        _authService = authService,
        _dio = dio,
        _prefs = prefs;

  Future<void> init() async {
    if (_initialized) return;

    await _setupLocalNotifications();
    await _requestPermission();

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      _registerToken(token, force: true);
    });

    _foregroundMessageSub?.cancel();
    _foregroundMessageSub = FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    _openMessageSub?.cancel();
    _openMessageSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    _initialized = true;
  }

  Future<void> syncTokenWithBackend({bool force = false}) async {
    if (kIsWeb) {
      debugPrint('FCM token registration is skipped on web until VAPID is configured.');
      return;
    }

    final user = await _authService.getSavedUserData();
    if (user?.id == null) {
      return;
    }

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('FCM token not available yet');
      return;
    }

    final savedToken = _prefs.getString(_storedTokenKey);
    final savedUserId = _prefs.getString(_storedUserIdKey);
    if (!force && savedToken == token && savedUserId == user!.id) {
      return;
    }

    await _registerToken(token, force: force);
    await _prefs.setString(_storedTokenKey, token);
    await _prefs.setString(_storedUserIdKey, user!.id!);
  }

  Future<void> clearLocalTokenState() async {
    await _prefs.remove(_storedTokenKey);
    await _prefs.remove(_storedUserIdKey);
  }

  Future<void> unregisterTokenFromBackend() async {
    final token = _prefs.getString(_storedTokenKey);
    final deviceId = _prefs.getString(_storedDeviceIdKey);

    if ((token == null || token.isEmpty) &&
        (deviceId == null || deviceId.isEmpty)) {
      return;
    }

    try {
      await _dio.delete(
        '/auth/me/push-tokens',
        data: {
          if (token != null && token.isNotEmpty) 'token': token,
          if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        },
      );
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
    }
  }

  Future<void> stop() async {
    _initialized = false;
    await _tokenRefreshSub?.cancel();
    await _foregroundMessageSub?.cancel();
    await _openMessageSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundMessageSub = null;
    _openMessageSub = null;
  }

  Future<void> _requestPermission() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (!kIsWeb) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('FCM permission request failed: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    if (_localNotificationReady || kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        _handleNotificationPayload(payload);
      },
    );

    const channel = AndroidNotificationChannel(
      'ticket_alerts',
      'Ticket Alerts',
      description: 'Ticket assignment and resolution alerts',
      importance: Importance.high,
    );

    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    _localNotificationReady = true;
  }

  Future<void> _registerToken(String token, {bool force = false}) async {
    final user = _authService.getSavedUserDataSync();
    final userId = user?.id;
    if (userId == null) return;
    final deviceId = await _getOrCreateDeviceId();

    try {
      await _dio.post(
        '/auth/me/push-tokens',
        data: {
        'token': token,
        'deviceId': deviceId,
        'platform': _platformName(),
      },
      );
      await _prefs.setString(_storedTokenKey, token);
      await _prefs.setString(_storedDeviceIdKey, deviceId);
      await _prefs.setString(_storedUserIdKey, userId);
      debugPrint('FCM token registered for user=$userId');
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = _prefs.getString(_storedDeviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final random = Random.secure();
    final value =
        '${_platformName()}_${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1 << 32)}';
    await _prefs.setString(_storedDeviceIdKey, value);
    return value;
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString() ?? 'Notification';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';
    try {
      DependencyInjection.get<RealtimeNotificationService>().refreshNotifications();
    } catch (_) {}

    // Check if this notification is for a ticket event
    final notificationType = message.data['type']?.toString() ?? '';
    final isTicketNotification = notificationType.startsWith('ticket_');

    // If it's a ticket notification, check if WebSocket is connected
    // to avoid duplicate notifications (one from FCM, one from Socket)
    if (isTicketNotification) {
      try {
        final socketService = DependencyInjection.get<SocketService>();
        if (socketService.isConnected) {
          // WebSocket is connected, event will be handled by RealtimeNotificationService
          // Suppress local notification to avoid duplicate
          debugPrint('[PushNotification] Suppressing duplicate: $notificationType (handled by WebSocket)');
          return;
        }
      } catch (e) {
        // SocketService not available or not connected, proceed with notification
        debugPrint('[PushNotification] WebSocket not available, showing notification');
      }
    }

    if (!kIsWeb) {
      _showLocalNotification(
        title: title,
        body: body,
        payload: message.data,
      );
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    if (!_localNotificationReady) return;

    const androidDetails = AndroidNotificationDetails(
      'ticket_alerts',
      'Ticket Alerts',
      channelDescription: 'Ticket assignment and resolution alerts',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotificationsPlugin.show(
      payload.hashCode,
      title,
      body,
      details,
      payload: payload.isEmpty ? null : jsonEncode(payload),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _handleNotificationPayloadFromData(message.data);
  }

  void _handleNotificationPayload(String rawPayload) {
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map<String, dynamic>) {
        _handleNotificationPayloadFromData(decoded);
        return;
      }
    } catch (_) {
    }
    AppRoutes.router.go(AppRoutes.notifications);
  }

  void _handleNotificationPayloadFromData(Map<String, dynamic> data) {
    final ticketId = data['ticketId']?.toString();
    if (ticketId != null && ticketId.isNotEmpty) {
      AppRoutes.router.go('${AppRoutes.tickets}/$ticketId');
      return;
    }
    AppRoutes.router.go(AppRoutes.notifications);
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
