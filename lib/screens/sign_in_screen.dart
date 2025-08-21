import 'package:flutter/material.dart';
import 'package:flutter_ap/services/socketservice.dart';
import 'package:flutter_ap/services/session_service.dart';
import 'dart:convert';
import 'package:flutter_ap/screens/sign_up_screen.dart';
import 'package:flutter_ap/home_page.dart';
import '../screens/MusicPlayer.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const SignInScreen({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late SocketService socketService;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isConnected = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  void _initializeSocket() {
    socketService = SocketService(host: '192.168.1.7', port: 10384);
    _connectSocket();
  }

  void _connectSocket() {
    socketService.connect().then((_) {
      setState(() {
        _isConnected = true;
      });
      print('Socket connected successfully');
      socketService.setOnMessage(_handleSocketMessage);
    }).catchError((error) {
      setState(() {
        _isConnected = false;
      });
      print('Socket connection error: $error');
      _showConnectionError();
    });
  }

  void _handleSocketMessage(String message) {
    try {
      final response = jsonDecode(message);
      setState(() => _isLoading = false);

      if (response['status'] == 'success') {
        _handleLoginSuccess();
      } else {
        _handleLoginError(response['message'] ?? 'Invalid username or password');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _handleLoginError('Invalid server response');
    }
  }

  void _handleLoginSuccess() async {
    await SessionService().saveUserSession(_usernameController.text);
    await GlobalAudioPlayer().reset();


    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(
          username: _usernameController.text,
        ),
      ),
    );

    widget.onLoginSuccess?.call();
  }

  void _handleLoginError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showConnectionError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔌 Connection failed. Trying to reconnect...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );

      // Auto reconnect after 3 seconds
      Future.delayed(const Duration(seconds: 3), _connectSocket);
    }
  }

  void _signIn() {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both username and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isConnected) {
      _showConnectionError();
      _connectSocket();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = {
        'requestType': 'Authorization',
        'action': 'login',
        'data': {
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        },
      };
      socketService.sendMessage(request);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _reconnect() {
    setState(() => _isLoading = true);
    _connectSocket();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    if (_isConnected) {
      socketService.disconnect();
    }
    super.dispose();
  }

  void _goToSignUp() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => SignUpScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 75),

              // Connection status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isConnected ? Icons.wifi : Icons.wifi_off,
                    color: _isConnected ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      color: _isConnected ? Colors.green : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                  if (!_isConnected) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _reconnect,
                      child: const Icon(Icons.refresh, color: Colors.blue, size: 16),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1E),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF1A73E8)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1E),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[400],
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF1A73E8)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_isConnected) ? null : _signIn,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? const Color(0xFF1A73E8) : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: _goToSignUp,
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Color(0xFF1A73E8),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}