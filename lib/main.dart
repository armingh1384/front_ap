import 'package:flutter/material.dart';
import 'package:flutter_ap/sign_up_screen.dart';
import 'package:flutter_ap/sign_in_screen.dart';
import 'package:flutter_ap/home_page.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SignInScreen(),
        '/signup': (context) => SignUpScreen(),
        '/home': (context) {
          final username = ModalRoute.of(context)!.settings.arguments as String;
          return HomePage(username: username);
        },
      },
    );
  }
}
