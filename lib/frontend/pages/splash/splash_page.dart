import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // sesuai figma
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 150, // bisa disesuaikan
        ),
      ),
    );
  }
}