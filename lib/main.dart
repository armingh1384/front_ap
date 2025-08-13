import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_ap/screens/sign_in_screen.dart';
import 'package:flutter_ap/home_page.dart';
import 'package:flutter_ap/services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();



  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  String? _username;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await SessionService().isLoggedIn();
    final username = await SessionService().getUsername();

    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _username = username;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),
      ),
      home: _isLoggedIn
          ? HomePage(username: _username ?? '')
          : SignInScreen(onLoginSuccess: _checkLoginStatus),
    );
  }
}
