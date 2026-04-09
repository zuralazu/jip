import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';

import '../../services/auth_service.dart';
import '../dashboard/dashboard_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();


    // 🎬 controller animasi
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // 🌫️ fade animation
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // 🔍 scale animation
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // ▶️ start animasi
    _controller.forward();

    void checkLogin() async {
      await Future.delayed(const Duration(seconds: 3));

      final token = await AuthService.getToken();

      if (!mounted) return;

      if (token != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardPage(),
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }

    _controller.forward();
    checkLogin();
  }

  @override
  void dispose() {
    _controller.dispose(); // penting!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/images/logo.png',
              width: 150,
            ),
          ),
        ),
      ),
    );
  }
}