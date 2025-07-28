import 'dart:convert';
import '../models/user.dart';
import 'socket_service.dart';

class UserService {
  final SocketService socketService;

  UserService(this.socketService);

  void updateUser(User user, Function(String) onSuccess, Function(String) onError) {
    final request = {
      'requestType': 'User',
      'action': 'update',
      'data': user.toJson(),
    };

    socketService.sendMessage(request);

    socketService.setOnMessage((message) {
      final response = jsonDecode(message);
      if (response['status'] == 'success') {
        onSuccess('تغییرات با موفقیت ذخیره شد ✅');
      } else {
        onError(response['message'] ?? 'خطا در ذخیره‌سازی');
      }
    });
  }
}
