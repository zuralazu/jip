import 'package:flutter/material.dart';
import '../../core/base_page.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../services/api_service.dart';
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void handleLupaPassword() async {
    if (emailController.text.isEmpty || 
        passwordController.text.isEmpty || 
        confirmPasswordController.text.isEmpty) {
      _showMessage("Semua kolom wajib diisi");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showMessage("Konfirmasi password tidak cocok");
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.lupaPassword(
        email: emailController.text,
        password: passwordController.text,
        confirm_password: confirmPasswordController.text,
      );

      final statusCode = result["statusCode"];

      if (statusCode == 200) {
        _showSuccessMessage("Password berhasil diperbarui! Silakan login kembali.");
        
        if (!mounted) return;
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } else if (statusCode == 401) {
        _showMessage("Email tidak terdaftar atau data salah");
      } else {
        _showMessage("Terjadi kesalahan (kode: $statusCode)");
      }
    } catch (e) {
      _showMessage("Tidak bisa terhubung ke server");
      debugPrint("ERROR LUPA PASSWORD: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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

              Image.asset(
                'assets/images/logo.png',
                width: 140,
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
                      "Lengkapi data di bawah untuk mengganti password akun Anda.",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 24),

                    CustomTextField(
                      hint: "Email",
                      controller: emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 13),

                    CustomTextField(
                      hint: "Password Baru",
                      controller: passwordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),

                    const SizedBox(height: 13),

                    CustomTextField(
                      hint: "Konfirmasi Password Baru",
                      controller: confirmPasswordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_reset_rounded,
                    ),

                    const SizedBox(height: 24),

                    isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : CustomButton(
                            text: "Ganti Password",
                            onPressed: handleLupaPassword,
                          ),
                    
                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          "Kembali ke Login",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
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
