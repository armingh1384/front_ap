import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class SocketService {
  Socket? _socket;
  final String host;
  final int port;
  bool isConnected = false;

  final List<int> _buffer = [];
  Function(String message)? _onMessageCallback;

  SocketService({required this.host, required this.port});
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.destroy();
      _socket = null;
    }
  }

  Future<void> connect() async {
    try {
      _socket = await Socket.connect(host, port);
      isConnected = true;
      print('Connected to: ${_socket!.remoteAddress.address}:${_socket!.remotePort}');

      _socket!.listen(
            (data) {
          _buffer.addAll(data);
          _processBuffer();
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

  void _processBuffer() {
    while (_buffer.length >= 4) {
      final byteData = ByteData.sublistView(Uint8List.fromList(_buffer));
      final length = byteData.getInt32(0, Endian.big);

      if (_buffer.length >= 4 + length) {
        final messageBytes = _buffer.sublist(4, 4 + length);
        final message = utf8.decode(messageBytes);
        print('Received: $message');
        _onMessageCallback?.call(message);
        _buffer.removeRange(0, 4 + length);
      } else {
        break; // منتظر بقیه پیام می‌مونیم
      }
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!isConnected || _socket == null) {
      print('Not connected to server');
      return;
    }
    final jsonString = jsonEncode(message);
    final bytes = utf8.encode(jsonString);
    final lengthBytes = ByteData(4)..setInt32(0, bytes.length, Endian.big);
    _socket!.add(lengthBytes.buffer.asUint8List());
    _socket!.add(bytes);
    print('Sent: $jsonString');
  }



  void setOnMessage(Function(String message) callback) {
    _onMessageCallback = callback;
  }
}
