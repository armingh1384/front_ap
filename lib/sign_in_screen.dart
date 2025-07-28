import 'package:flutter/material.dart';
import 'package:flutter_ap/sign_up_screen.dart';
import 'package:flutter_ap/services/socket_service.dart';
<<<<<<< HEAD
import 'package:flutter_ap/widgets/loading_overlay.dart';
import 'package:flutter_ap/utils/ui_helpers.dart';
import 'package:flutter_ap/services/session_service.dart'; // افزودن این خط

=======
>>>>>>> origin/master
import 'dart:convert';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late SocketService socketService;
<<<<<<< HEAD
  late SessionService sessionService;

  bool _obscurePassword = true;
  bool _isLoading = false;

=======
  bool _obscurePassword = true;
>>>>>>> origin/master
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    socketService = SocketService(host: '192.168.1.6', port: 10384);
<<<<<<< HEAD
    sessionService = SessionService();

    _checkPreviousLogin();
    socketService.connect();
    socketService.setOnMessage(_handleSocketMessage);
  }

  void _checkPreviousLogin() async {
    String? username = await sessionService.getUsername();
    if (username != null && mounted) {
      Navigator.pushReplacementNamed(context, '/home', arguments: username);
    }
  }

  void _handleSocketMessage(String message) async {
    final response = jsonDecode(message);
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      await sessionService.saveUsername(_usernameController.text);

      showSuccessMessage(context, '✅ ورود موفق بود');
      Future.delayed(const Duration(milliseconds: 500), () {
=======
    socketService.connect();
    socketService.setOnMessage((message) {
      final response = jsonDecode(message);
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Login successful'),
            backgroundColor: Colors.green,
          ),

        );
>>>>>>> origin/master
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: _usernameController.text,
        );
<<<<<<< HEAD
      });
    } else {
      showErrorMessage(context, response['message'] ?? 'نام کاربری یا رمز عبور نادرست است');
    }
=======

        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${response['message'] ?? 'Invalid username or password'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

>>>>>>> origin/master
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    socketService.disconnect();
    super.dispose();
  }

  void _signIn() {
<<<<<<< HEAD
    final request = {
      'requestType': 'Authorization',
      'action': 'login',
      'data': {
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
      },
    };

    setState(() => _isLoading = true);
    socketService.sendMessage(request);
=======
    try {
      final request = {
        'requestType': 'Authorization',
        'action': 'login',
        'data': {
          'username': _usernameController.text,
          'password': _passwordController.text,
        },
      };

      print('Sending login request: ${jsonEncode(request)}');
      socketService.sendMessage(request);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login request sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error sending login request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send login request'),
          backgroundColor: Colors.red,
        ),
      );
    }
>>>>>>> origin/master
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Icon(Icons.music_note, size: 100, color: Colors.white),
                const SizedBox(height: 60),
                _buildInputField(hint: 'نام کاربری'),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _signIn,
                    child: const Text('ورود'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: const Text('ثبت‌نام نکرده‌اید؟ ثبت‌نام کنید'),
                )
              ],
            ),
=======
    return Scaffold(
      backgroundColor: Color(0xFF0E0E0E),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 75),
              _buildInputField(hint: 'Username'),
              SizedBox(height: 30),
              _buildPasswordField(),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _signIn,
                  child: Text(
                    'Sign In',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A73E8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account?',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: Duration(milliseconds: 500),
                          pageBuilder: (context, animation, secondaryAnimation) => SignUpScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF1A73E8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              )
            ],
>>>>>>> origin/master
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required String hint}) {
    return TextField(
      controller: _usernameController,
<<<<<<< HEAD
      style: const TextStyle(color: Colors.white),
=======
      style: TextStyle(color: Colors.white),
>>>>>>> origin/master
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'رمز عبور',
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[850],
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}