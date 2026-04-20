import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../config/env.dart';

class TicketRealtimeEvent {
  final String type;
  final Map<String, dynamic> payload;

  const TicketRealtimeEvent({
    required this.type,
    required this.payload,
  });
}

class SocketService {
  io.Socket? _socket;
  bool _notificationHandlersBound = false;

  final StreamController<TicketRealtimeEvent> _ticketEventsController =
      StreamController<TicketRealtimeEvent>.broadcast();

  Stream<TicketRealtimeEvent> get ticketEvents => _ticketEventsController.stream;

  bool get isConnected => _socket?.connected == true;

  void initAndJoin({
    required String token,
    required String userId,
    String? campus,
  }) {
    final baseUrl = Env.apiBaseUrl.replaceAll('/api', '');
    final socketUrl = '$baseUrl/notifications';

    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
      _notificationHandlersBound = false;
    }

    debugPrint('Connecting to Socket.IO at $socketUrl');

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1500)
          .setTimeout(10000)
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('Socket connected to namespace: /notifications');
      _joinRoom(userId: userId, campus: campus);
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    _socket!.onConnectError((err) {
      debugPrint('Socket Connect Error: $err');
    });

    bindNotificationEventHandlers();
    _socket!.connect();
  }

  void _joinRoom({required String userId, String? campus}) {
    final payload = {
      'userId': userId,
      if (campus != null && campus.isNotEmpty) 'campus': campus,
    };

    _socket?.emit('join_room', payload);
    debugPrint('Joined notification room for userId=$userId');
  }

  void bindNotificationEventHandlers() {
    if (_socket == null || _notificationHandlersBound) return;

    void bind(String eventName) {
      _socket!.off(eventName);
      _socket!.on(eventName, (data) {
        final payload = data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data as Map);
        _ticketEventsController.add(
          TicketRealtimeEvent(type: eventName, payload: payload),
        );
      });
    }

    bind('ticket:assigned');
    bind('ticket:resolved');
    bind('ticket:updated');
    bind('ticket:created');
    bind('broadcast_announcement');
    bind('face_authenticated');

    _notificationHandlersBound = true;
  }

  void subscribe(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void unsubscribe(String event) {
    _socket?.off(event);
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _notificationHandlersBound = false;
  }
}
