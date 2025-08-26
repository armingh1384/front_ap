import 'package:flutter/material.dart';
import '../mywidgets/profile_field.dart';
import '../models/user.dart';
import '../services/SocketService.dart';
import '../services/user_service.dart';
import '../utils/ui_helpers.dart';
import 'dart:convert';
import '../screens/sign_in_screen.dart';

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
  late TextEditingController deletePasswordController;

  late SocketService socketService;
  late UserService userService;
  late String oldusername;

  bool isLoading = false;
  bool isPasswordValid = true;
  String passwordError = '';

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.username);
    emailController = TextEditingController();
    passwordController = TextEditingController();
    deletePasswordController = TextEditingController();

    oldusername = widget.username;

    socketService = SocketService(host: '10.134.120.165', port: 10384);

    socketService.connect().then((_) {
      userService = UserService(socketService);
      _setupSocketListeners();
      _loadUserData();
    });

    passwordController.addListener(_validatePassword);
  }

  void _setupSocketListeners() {
    socketService.setOnMessage(_handleSocketMessage);
  }

  void _handleSocketMessage(String message) {
    try {
      final response = jsonDecode(message);
      if (response['status'] == 'success') {
        setState(() => isLoading = false);
        final data = response['data'];
        setState(() {
          usernameController.text = data['username'] ?? '';
          emailController.text = data['email'] ?? '';
          passwordController.text = data['password'] ?? '';
          oldusername = data['username'] ?? widget.username;
        });
        _validatePassword();
      } else {
        showErrorMessage(context, 'Failed to load user profile.');
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _validatePassword() {
    final password = passwordController.text;
    setState(() {
      isPasswordValid = _isValidPassword(password);
      passwordError = isPasswordValid
          ? ''
          : 'Password must be at least 8 characters with uppercase, lowercase and numbers';
    });
  }

  bool _isValidPassword(String password) {
    if (password.isEmpty) return true;
    final passwordRegex = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9]).{8,}$');
    return passwordRegex.hasMatch(password);
  }

  void _loadUserData() {
    setState(() => isLoading = true);
    final request = {
      'requestType': 'user',
      'action': 'getProfile',
      'data': {'username': oldusername},
    };
    socketService.sendMessage(request);
  }

  void _saveChanges() {
    if (passwordController.text.isNotEmpty && !isPasswordValid) {
      showErrorMessage(context, 'ENTER VALID PASSWORD');
      return;
    }

    final updatedUser = User(
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    userService.updateUser(
      updatedUser,
      oldusername,
          (msg) => showSuccessMessage(context, 'Profile updated successfully!'),
          (err) => showErrorMessage(context, err),
    );
  }

  void _deleteAccount() {
    deletePasswordController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your password to confirm account deletion:'),
            const SizedBox(height: 16),
            TextField(
              controller: deletePasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (deletePasswordController.text.isEmpty) {
                showErrorMessage(context, 'Please enter your password');
                return;
              }
              Navigator.pop(context);
              _confirmDeleteAccount(deletePasswordController.text);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(String password) {
    final request = {
      'requestType': 'user',
      'action': 'removeuser',
      'data': {
        'username': oldusername,
        'password': password,
      },
    };

    socketService.sendMessage(request);
    showSuccessMessage(context, 'Account deletion request sent.');

    socketService.disconnect().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SignInScreen()),
              (route) => false,
        );
      });
    });
  }

  @override
  void dispose() {
    socketService.disconnect();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    deletePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _glassContainer(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white12,
                child: Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              ProfileField(label: 'Username', controller: usernameController),
              const SizedBox(height: 16),
              ProfileField(label: 'Email', controller: emailController),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileField(
                    label: 'Password',
                    controller: passwordController,
                    obscureText: true,
                  ),
                  if (!isPasswordValid && passwordController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 16),
                      child: Text(
                        passwordError,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('Delete Account', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.04), Colors.white.withOpacity(0.01)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: child,
    );
  }
}