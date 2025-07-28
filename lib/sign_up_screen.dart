import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_ap/services/socket_service.dart';
import 'package:flutter_ap/widgets/loading_overlay.dart';
import 'package:flutter_ap/utils/ui_helpers.dart';
import 'dart:convert';
=======
import 'package:flutter_ap/sign_in_screen.dart';
import 'package:flutter_ap/services/socket_service.dart';
import 'dart:convert';

>>>>>>> origin/master

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
<<<<<<< HEAD
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  late SocketService socketService;

=======
  late SocketService socketService;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

>>>>>>> origin/master
  @override
  void initState() {
    super.initState();
    socketService = SocketService(host: '192.168.1.6', port: 10384);
<<<<<<< HEAD
    socketService.connect();
    socketService.setOnMessage((message) {
      final response = jsonDecode(message);
      setState(() => _isLoading = false);

      if (response['status'] == 'success') {
        showSuccessMessage(context, '✅ ثبت‌نام موفق بود');
        Navigator.pop(context);
      } else {
        showErrorMessage(context, response['message'] ?? 'خطا در ثبت‌نام');
      }
    });
  }

  void _signUp() {
    setState(() => _isLoading = true);
    final request = {
      'requestType': 'Authorization',
      'action': 'signup',
      'data': {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'email': _emailController.text,
      },
    };
    socketService.sendMessage(request);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    socketService.disconnect();
    super.dispose();
  }
=======
    socketService.connect().then((_) {
      socketService.setOnMessage((message) {
        final response = jsonDecode(message);

        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Sign up successful!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ ${response['message'] ?? 'Sign up failed'}')),
          );
        }
      });
    });
  }


  @override
  void dispose() {
    socketService.disconnect();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _signUp(String username, String email, String password) {
    final message = {
      'requestType': 'Authorization',
      'action': 'signup',
      'data': {
        'username': username,
        'email': email,
        'password': password,
      },
    };
    socketService.sendMessage(message);
  }

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
>>>>>>> origin/master

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        appBar: AppBar(
          title: Text('ثبت‌نام', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
<<<<<<< HEAD
              _buildInput(_usernameController, 'نام کاربری'),
              SizedBox(height: 20),
              _buildInput(_passwordController, 'رمز عبور', isPassword: true),
              SizedBox(height: 20),
              _buildInput(_emailController, 'ایمیل'),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _signUp,
                child: Text('ثبت‌نام'),
=======
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
              SizedBox(height: 40),
              _buildInputField(
                hint: 'Username',
                controller: _usernameController,
              ),
              SizedBox(height: 20),
              _buildInputField(
                hint: 'Email',
                controller: _emailController,
              ),
              SizedBox(height: 20),
              _buildPasswordField(
                hint: 'Password',
                controller: _passwordController,
                obscure: _obscurePassword,
                toggle: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              SizedBox(height: 20),
              _buildPasswordField(
                hint: 'Confirm Password',
                controller: _confirmController,
                obscure: _obscureConfirmPassword,
                toggle: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    final username = _usernameController.text.trim();
                    final email = _emailController.text.trim();
                    final password = _passwordController.text;
                    final confirmPassword = _confirmController.text;

                    if (!isValidEmail(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Please enter a valid email address')),
                      );
                      return;
                    }

                    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('⚠️ Please fill all fields')),
                      );
                      return;
                    }

                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('🔒 Passwords do not match')),
                      );
                      return;
                    }
                    _signUp(username, email, password);
                  },
                  child: Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2196F3),
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
                    'Already have an account?',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        FadePageRoute(page: SignInScreen()),
                      );
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
>>>>>>> origin/master
              ),
            ],
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildInput(TextEditingController controller, String label, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
=======
  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
>>>>>>> origin/master
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
<<<<<<< HEAD
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
=======
        fillColor: Color(0xFF1E1E1E),
        contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color(0xFF3A3A3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color(0xFF3A3A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color(0xFF2196F3)),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Color(0xFF1E1E1E),
        contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[400],
          ),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color(0xFF3A3A3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color(0xFF3A3A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color(0xFF2196F3)),
        ),
>>>>>>> origin/master
      ),
    );
  }
}
<<<<<<< HEAD
=======

bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  FadePageRoute({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
>>>>>>> origin/master
