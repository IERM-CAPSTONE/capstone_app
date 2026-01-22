import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../config/env.dart';

class SocketService {
  late IO.Socket socket;

  void init(String token) {
    // Lấy domain từ apiBaseUrl (bỏ phần /api)
    var baseUrl = Env.apiBaseUrl.replaceAll('/api', '');
    final socketUrl = '$baseUrl/notifications';

    debugPrint('Connecting to Socket.IO at $socketUrl');

    socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .disableAutoConnect()
            .build());

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Socket connected to namespace: /notifications');
    });

    socket.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    socket.onConnectError((err) {
      debugPrint('Socket Connect Error: $err');
    });
  }

  void subscribe(String event, Function(dynamic) callback) {
    socket.on(event, callback);
  }

  void unsubscribe(String event) {
    socket.off(event);
  }

  void dispose() {
    socket.dispose();
  }
}
