import 'package:flutter/material.dart';
import '../../core/base_page.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with BasePage {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  void handleLogin() async {
    setState(() => isLoading = true);

    try {
      final result = await ApiService.login(
        email: emailController.text,
        password: passwordController.text,
      );

      final statusCode = result["statusCode"];

      // 🔥 SUKSES LOGIN
      if (statusCode == 200) {
        final token = result["data"]["authorization"]["access_token"];

        await AuthService.saveToken(token);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardPage(),
          ),
        );
      }

      // 🔴 SALAH LOGIN
      else if (statusCode == 401) {
        _showMessage("Email atau password salah");
      }

      // 🔴 SERVER ERROR
      else if (statusCode == 500) {
        _showMessage("Server sedang bermasalah, coba lagi nanti");
      }

      // 🔴 DEFAULT
      else {
        _showMessage("Terjadi kesalahan (kode: $statusCode)");
      }
    } catch (e) {
      // 🔥 HANDLE KHUSUS (kalau backend lempar error)
      if (e.toString().contains("TOKEN_EXPIRED")) {
        _showMessage("Sesi berakhir, silakan login kembali");
      } else {
        _showMessage("Tidak bisa terhubung ke server");
      }

      debugPrint("ERROR LOGIN: $e");
    } finally {
      // 🔥 INI PALING AMAN (pasti ke-set false)
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 48),

              // LOGO
              Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 140,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Selamat datang, silahkan login!",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🔥 EMAIL (UI SAMA)
                    CustomTextField(
                      hint: "Email",
                      controller: emailController,
                      prefixIcon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 13),

                    // 🔥 PASSWORD (UI SAMA)
                    CustomTextField(
                      hint: "Password",
                      controller: passwordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {},
                        child: Text(
                          "Lupa password?",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔥 BUTTON LOGIN
                    isLoading
                        ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                        : CustomButton(
                      text: "Login",
                      onPressed: handleLogin,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                "© 2025 JIM Pekanbaru",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}