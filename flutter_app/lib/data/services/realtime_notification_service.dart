import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../config/dependency_injection.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'socket_service.dart';

class AppNotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? ticketId;
  final bool isRead;

  const AppNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.ticketId,
    this.isRead = false,
  });

  AppNotificationItem copyWith({bool? isRead}) {
    return AppNotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      ticketId: ticketId,
      isRead: isRead ?? this.isRead,
    );
  }

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>?;
    return AppNotificationItem(
      id: json['id'].toString(),
      type: json['channel'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      ticketId: meta?['ticketId']?.toString(),
      isRead: json['isRead'] == true,
    );
  }
}

class RealtimeNotificationService {
  final SocketService _socketService;
  final AuthService _authService;

  StreamSubscription<TicketRealtimeEvent>? _ticketSub;
  bool _started = false;

  final ValueNotifier<List<AppNotificationItem>> notifications =
      ValueNotifier<List<AppNotificationItem>>([]);

  RealtimeNotificationService(this._socketService, this._authService);

  ApiService get _apiService => DependencyInjection.get<ApiService>();

  Future<void> start() async {
    if (_started) return;

    final token = _authService.getToken();
    final user = await _authService.getSavedUserData();

    if (token == null || user?.id == null) {
      debugPrint('🔔 NotificationService: no token or user, skipping start');
      return;
    }

    _socketService.initAndJoin(
      token: token,
      userId: user!.id!,
      campus: user.code,
    );

    // Tải thông báo cũ từ Database
    try {
      debugPrint('🔔 Fetching notifications from API...');
      final response = await _apiService.getNotifications();
      debugPrint('🔔 API response: success=${response.success}, data=${response.data?.runtimeType}');
      if (response.data is List) {
        final List<dynamic> data = response.data;
        debugPrint('🔔 Loaded ${data.length} notifications');
        notifications.value = data
            .map((json) => AppNotificationItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e, stack) {
      debugPrint('🔔 Error fetching old notifications: $e');
      debugPrint(stack.toString());
    }

    _ticketSub?.cancel();
    _ticketSub = _socketService.ticketEvents.listen(_handleTicketEvent);

    _started = true;
  }

  Future<void> restartWithLatestAuth() async {
    _started = false;
    await _ticketSub?.cancel();
    _ticketSub = null;
    await start();
  }

  Future<void> refreshNotifications() async {
    try {
      final response = await _apiService.getNotifications();
      if (response.data is List) {
        final List<dynamic> data = response.data;
        notifications.value = data
            .map((json) => AppNotificationItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('🔔 Error refreshing notifications: $e');
    }
  }

  void _handleTicketEvent(TicketRealtimeEvent event) {
    final payload = event.payload;
    
    // Check if this is a user-facing notification
    final isUserNotification = payload['isUserNotification'] == true;
    
    // Silent events: only refresh lists, no UI alerts
    if (!isUserNotification) {
      // For ticket:created and ticket:updated with isUserNotification: false
      // Just refresh notifications/tickets list silently
      if (event.type == 'ticket:created' || event.type == 'ticket:updated') {
        // Optional: trigger ticket list refresh via a separate stream
        debugPrint('[RealtimeNotification] Silent event: ${event.type}');
      }
      return;
    }

    // Real notifications: show in-app alert
    final issueName = (payload['issueName'] ?? 'ticket').toString();

    String title;
    String message;
    Color color;

    switch (event.type) {
      case 'ticket:assigned':
        title = 'Ticket được giao';
        message = 'Bạn vừa được giao ticket: $issueName';
        color = Colors.blue;
        break;
      case 'ticket:resolved':
        title = 'Ticket đã xử lý';
        message = 'Ticket đã được xử lý: $issueName';
        color = Colors.green;
        break;
      case 'ticket:updated':
        final status = (payload['status'] ?? 'UPDATED').toString();
        title = 'Ticket cập nhật';
        message = 'Ticket cập nhật trạng thái: $status';
        color = Colors.orange;
        break;
      default:
        title = 'Thông báo';
        message = 'Bạn có thông báo mới';
        color = Colors.black87;
    }

    refreshNotifications();

    appScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> markRead(String notificationId) async {
    try {
      if (notificationId == '0' || notificationId.isEmpty) return;
      await _apiService.markNotificationRead(notificationId);
      final updated = notifications.value.map((n) {
        return n.id == notificationId ? n.copyWith(isRead: true) : n;
      }).toList();
      notifications.value = updated;
    } catch (e) {
      debugPrint('🔔 Error marking notification as read: $e');
    }
  }

  Future<void> markTicketNotificationsAsRead(String ticketId) async {
    final unreadMatches = notifications.value.where(
        (n) => n.ticketId == ticketId && !n.isRead
    ).toList();
    
    for (var n in unreadMatches) {
      await markRead(n.id);
    }
  }

  Future<void> stop() async {
    _started = false;
    await _ticketSub?.cancel();
    _ticketSub = null;
    _socketService.dispose();
  }
}
