import 'package:flutter/material.dart';
import 'package:flutter_ap/sign_in_screen.dart';
import 'package:flutter_ap/sign_up_screen.dart';
<<<<<<< HEAD
import 'package:flutter_ap/home_page.dart';
import 'package:flutter_ap/screens/songs_page.dart';
import 'package:flutter_ap/screens/profile_page.dart'; // ← اضافه کردن صفحه پروفایل

=======
import 'package:flutter_ap/sign_in_screen.dart';
import 'package:flutter_ap/home_page.dart';
>>>>>>> origin/master
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
<<<<<<< HEAD
      title: 'Music App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),
        primaryColor: Colors.deepPurple,
      ),
      initialRoute: '/',
      routes: {
        /// صفحه ورود
        '/': (context) => const SignInScreen(),

        /// صفحه ثبت‌نام
        '/signup': (context) => const SignUpScreen(),

        /// صفحه اصلی (پس از ورود موفق)
=======
      initialRoute: '/',
      routes: {
        '/': (context) => SignInScreen(),
        '/signup': (context) => SignUpScreen(),
>>>>>>> origin/master
        '/home': (context) {
          final username = ModalRoute.of(context)!.settings.arguments as String;
          return HomePage(username: username);
        },
<<<<<<< HEAD

        /// مسیر نمایش لیست آهنگ‌ها
        '/songs': (context) => const SongsPage(),

        /// مسیر پروفایل
        '/profile': (context) {
          final username = ModalRoute.of(context)!.settings.arguments as String;
          return ProfilePage(username: username);
        },
=======
>>>>>>> origin/master
      },
    );
  }
}
