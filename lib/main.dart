import 'package:flutter/material.dart';
import 'frontend/pages/splash/splash_page.dart';
import 'frontend/pages/login/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JIM Pekanbaru',
      initialRoute: '/login',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}