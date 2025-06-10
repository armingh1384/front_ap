import 'package:flutter/material.dart';
import 'package:flutter_ap/sign_up_screen.dart';
import 'package:flutter_ap/services/socket_service.dart';
import 'dart:convert';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late SocketService socketService;
  bool _obscurePassword = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    socketService = SocketService(host: '192.168.1.6', port: 10384);
    socketService.connect();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    socketService.disconnect();
    super.dispose();
  }

  void _signIn() {
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
  }

  @override
  Widget build(BuildContext context) {
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
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required String hint}) {
    return TextField(
      controller: _usernameController,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Color(0xFF1C1C1E),
        contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color(0xFF2C2C2E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color(0xFF2C2C2E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color(0xFF1A73E8)),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Color(0xFF1C1C1E),
        contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[400],
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color(0xFF2C2C2E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color(0xFF2C2C2E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color(0xFF1A73E8)),
        ),
      ),
    );
  }
}