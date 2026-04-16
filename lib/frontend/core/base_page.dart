import 'package:flutter/material.dart';
import '../pages/login/login_page.dart';

mixin BasePage<T extends StatefulWidget> on State<T> {
  bool _isShowingError = false; // ✅ FLAG

  void handleApiError(dynamic e) {
    final error = e.toString();

    if (error.contains("UNAUTHORIZED")) {
      _redirectToLogin();
    } else if (error.contains("SERVER_ERROR")) {
      _showMessage("Server sedang bermasalah");
    } else {
      _showMessage("Terjadi kesalahan");
    }
  }

  void _redirectToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  void _showMessage(String message) {
    if (_isShowingError) return; // ❌ STOP SPAM

    _isShowingError = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    // reset setelah 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      _isShowingError = false;
    });
  }
}