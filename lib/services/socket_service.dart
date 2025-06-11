import 'dart:convert';
import 'dart:io';

class SocketService {
  late Socket _socket;
  final String host;
  final int port;
  bool isConnected = false;

  Function(String message)? _onMessageCallback;

  SocketService({required this.host, required this.port});

  Future<void> connect() async {
    try {
      _socket = await Socket.connect(host, port);
      isConnected = true;
      print('Connected to: ${_socket.remoteAddress.address}:${_socket.remotePort}');

      _socket.listen(
            (data) {
          final message = utf8.decode(data);
          print('Received: $message');
          _onMessageCallback?.call(message);
        },
        onDone: () {
          print('Connection closed by server');
          isConnected = false;
        },
        onError: (error) {
          print('Socket error: $error');
          isConnected = false;
        },
      );
    } catch (e) {
      print('Unable to connect: $e');
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!isConnected) {
      print('Not connected to server');
      return;
    }
    final jsonString = jsonEncode(message);
    _socket.write(jsonString + '\n');
    print('Sent: $jsonString');
  }

  void disconnect() {
    _socket.close();
    isConnected = false;
  }

  void setOnMessage(Function(String message) callback) {
    _onMessageCallback = callback;
  }
}
