import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class MiraWebSocketClient {
  final String uri;
  WebSocketChannel? _channel;

  MiraWebSocketClient({required this.uri});

  void connect({Function(dynamic)? onMessage}) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(uri));
      print("✅ Connected to $uri");

      _channel!.stream.listen(
            (message) {
          print("📩 Message from server: $message");
          onMessage?.call(message);
        },
        onDone: () {
          print("⚠️ WebSocket closed.");
        },
        onError: (error) {
          print("❌ WebSocket error: $error");
        },
      );
    } catch (e) {
      print("❌ Failed to connect: $e");
    }
  }

  void sendStartMessage(String text) {
    if (_channel != null) {
      final message = jsonEncode({
        "action": "start_chat",
        "payload": {"text": text}
      });
      print("➡️ Sending: $message");
      _channel!.sink.add(message);
    } else {
      print("⚠️ WebSocket not connected.");
    }
  }

  void disconnect() {
    _channel?.sink.close(status.goingAway);
  }
}
