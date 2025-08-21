import 'dart:convert';
import '../models/user.dart';
import 'SocketService.dart';
class UserService {
  final SocketService socketService;
  UserService(this.socketService);

  void updateUser(User user, String lastusername, Function(String) onSuccess, Function(String) onError) {
    final request = {
      'requestType': 'user',
      'action': 'update',
      'data': {
        'Nusername': user.username,
        'Nemail': user.email,
        'Npassword': user.password,
        'lastusername': lastusername,
      },
    };
    socketService.sendMessage(request);
    socketService.setOnMessage((message) {
      final response = jsonDecode(message);
      if (response['status'] == 'success') {
        onSuccess(response['msg'] ?? 'Profile updated');
      } else {
        onError(response['msg'] ?? 'Failed to update profile');
      }
    });
  }
}