import 'package:flutter/material.dart';
import '../../core/base_page.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_page.dart';
import '../login/register_page.dart';
import '../login/lupa_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with BasePage {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    // 🔥 Fix: Selalu dispose controller untuk menghindari memory leak
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showMessage("Email dan password tidak boleh kosong");
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.login(
        email: emailController.text,
        password: passwordController.text,
      );

      final statusCode = result["statusCode"];

      if (statusCode == 200) {
        final token = result["data"]["authorization"]["access_token"];
        await AuthService.saveToken(token);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      } else if (statusCode == 401) {
        _showMessage("Email atau password salah");
      } else if (statusCode == 500) {
        _showMessage("Server sedang bermasalah, coba lagi nanti");
      } else {
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
              const SizedBox(height: 60),

              // LOGO
              Image.asset(
                'assets/images/logo.png',
                width: 140,
              ),

              const SizedBox(height: 48),

              // CARD LOGIN
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
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

                    const SizedBox(height: 32),

                    // EMAIL
                    CustomTextField(
                      hint: "Email",
                      controller: emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // PASSWORD
                    CustomTextField(
                      hint: "Password",
                      controller: passwordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),

                    const SizedBox(height: 12),

                    // LUPA PASSWORD
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LupaPassword()),
                          );
                        },
                        child: Text(
                          "Lupa password?",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // BUTTON LOGIN
                    isLoading
                        ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                        : CustomButton(
                      text: "Login",
                      onPressed: handleLogin,
                    ),

                    const SizedBox(height: 24),

                    // REGISTER LINK
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterPage()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Pengguna baru? ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                            children: const [
                              TextSpan(
                                text: "Registrasi di sini",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

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