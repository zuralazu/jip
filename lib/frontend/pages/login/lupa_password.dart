import 'package:flutter/material.dart';
import '../../core/base_page.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_page.dart';
import '../login/register_page.dart';
import '../login/login_page.dart';

class LupaPassword extends StatefulWidget {
  const LupaPassword({super.key});

  @override
  State<LupaPassword> createState() => _LupaPasswordState();
}

class _LupaPasswordState extends State<LupaPassword> with BasePage {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;

  void handleLupaPassword() async {
    setState(() => isLoading = true);

    try {
      final result = await ApiService.lupaPassword(
        email: emailController.text,
        password: passwordController.text,
        confirm_password: confirmPasswordController.text,
      );

      final statusCode = result["statusCode"];

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

      else if (statusCode == 401) {
        _showMessage("Email atau password salah");
      }

      else if (statusCode == 500) {
        _showMessage("Server sedang bermasalah, coba lagi nanti");
      }

      else {
        _showMessage("Terjadi kesalahan (kode: $statusCode)");
      }
    } catch (e) {
      if (e.toString().contains("TOKEN_EXPIRED")) {
        _showMessage("Sesi berakhir, silakan login kembali");
      } else {
        _showMessage("Tidak bisa terhubung ke server");
      }

      debugPrint("ERROR LOGIN: $e");
    } finally {
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

              Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 140,
                  ),
                ],
              ),

              const SizedBox(height: 40),

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
                      "Ganti Password",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Ganti Password Kamu dengan Melangkapi Inputan Kolom dibawah!",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 24),

                    CustomTextField(
                      hint: "Email",
                      controller: emailController,
                      prefixIcon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 13),

                    CustomTextField(
                      hint: "Password",
                      controller: passwordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),

                    const SizedBox(height: 13),

                    CustomTextField(
                      hint: "Konfirmasi Password",
                      controller: confirmPasswordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),

                    const SizedBox(height: 20),

                    isLoading
                        ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                        : CustomButton(
                      text: "Login",
                      onPressed: handleLupaPassword,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: Text(
                    "Kembali",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
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