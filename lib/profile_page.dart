import 'package:flutter/material.dart';
import '../widgets/profile_field.dart';
import '../models/user.dart';
import '../services/socket_service.dart';
import '../services/user_service.dart';
import '../utils/ui_helpers.dart';

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({Key? key, required this.username}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late SocketService socketService;
  late UserService userService;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.username);
    emailController = TextEditingController();
    passwordController = TextEditingController();

    socketService = SocketService(host: '192.168.1.6', port: 10384);
    socketService.connect();
    userService = UserService(socketService);

    _loadUserData();
  }

  void _loadUserData() {
    final request = {
      'requestType': 'User',
      'action': 'getProfile',
      'data': {'username': widget.username},
    };
    socketService.sendMessage(request);
    socketService.setOnMessage((message) {
      final response = jsonDecode(message);
      if (response['status'] == 'success') {
        final user = User.fromJson(response['data']);
        emailController.text = user.email;
        passwordController.text = user.password;
        setState(() {});
      } else {
        showErrorMessage(context, 'خطا در بارگذاری اطلاعات کاربر');
      }
    });
  }

  void _saveChanges() {
    final updatedUser = User(
      username: usernameController.text,
      email: emailController.text,
      password: passwordController.text,
    );

    userService.updateUser(updatedUser, (msg) {
      showSuccessMessage(context, msg);
    }, (err) {
      showErrorMessage(context, err);
    });
  }

  @override
  void dispose() {
    socketService.disconnect();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0E0E0E),
      appBar: AppBar(
        title: Text('👤 پروفایل من'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[700],
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
            SizedBox(height: 20),
            ProfileField(label: 'نام کاربری', controller: usernameController),
            SizedBox(height: 10),
            ProfileField(label: 'ایمیل', controller: emailController),
            SizedBox(height: 10),
            ProfileField(label: 'رمز عبور', controller: passwordController, obscureText: true),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: Text('ذخیره تغییرات'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
