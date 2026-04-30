import 'package:flutter/material.dart';
import 'package:jip/frontend/pages/main/main_page.dart';
import '../../core/base_page.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
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
  bool obscurePassword = true;

  // Error state per field
  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ─── Validasi ───────────────────────────────────────────────────────────────

  bool _validateEmail(String value) {
    // Cek kosong
    if (value.trim().isEmpty) {
      setState(() => emailError = "Email tidak boleh kosong");
      return false;
    }

    // Cek format email dasar: ada @, ada titik di domain
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      setState(() => emailError = "Format email tidak valid");
      return false;
    }

    setState(() => emailError = null);
    return true;
  }

  bool _validatePassword(String value) {
    if (value.isEmpty) {
      setState(() => passwordError = "Password tidak boleh kosong");
      return false;
    }

    // Minimal 6 karakter, hanya huruf atau angka
    if (value.length < 6) {
      setState(() => passwordError = "Password minimal 6 karakter");
      return false;
    }

    final passwordRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!passwordRegex.hasMatch(value)) {
      setState(() => passwordError = "Password hanya boleh huruf dan angka");
      return false;
    }

    setState(() => passwordError = null);
    return true;
  }

  bool _validateAll() {
    final emailOk = _validateEmail(emailController.text);
    final passwordOk = _validatePassword(passwordController.text);
    return emailOk && passwordOk;
  }

  // ─── Login Handler ───────────────────────────────────────────────────────────

  void handleLogin() async {
    // Jalankan semua validasi dulu
    if (!_validateAll()) return;

    setState(() => isLoading = true);

    try {
      final result = await ApiService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final statusCode = result["statusCode"];

      if (statusCode == 200) {
        final token = result["data"]["authorization"]["access_token"];
        await AuthService.saveToken(token);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      } else if (statusCode == 401) {
        _showSnackbar("Email atau password salah");
      } else if (statusCode == 500) {
        _showSnackbar("Server sedang bermasalah, coba lagi nanti");
      } else {
        _showSnackbar("Terjadi kesalahan (kode: $statusCode)");
      }
    } catch (e) {
      if (e.toString().contains("TOKEN_EXPIRED")) {
        _showSnackbar("Sesi berakhir, silakan login kembali");
      } else {
        _showSnackbar("Tidak bisa terhubung ke server");
      }
      debugPrint("ERROR LOGIN: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Widget Helpers ──────────────────────────────────────────────────────────

  /// TextField dengan label di atas, outline style, dan error message inline
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword ? obscurePassword : false,
          onChanged: (val) {
            // Real-time clear error saat user mulai mengetik lagi
            if (onChanged != null) onChanged(val);
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            suffixIcon: isPassword
                ? GestureDetector(
              onTap: () => setState(() => obscurePassword = !obscurePassword),
              child: Icon(
                obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white54,
                size: 20,
              ),
            )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red.shade300
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red.shade300 : Colors.white,
                width: 1.5,
              ),
            ),
            // ⚠️ Error: tidak pakai errorText bawaan Flutter supaya bisa custom style
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                errorText,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

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
              Image.asset('assets/images/logo.png', width: 140),

              const SizedBox(height: 48),

              // CARD LOGIN
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  // Sedikit shadow biar terasa lebih dalam
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Selamat datang, silahkan login!",
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
                    ),

                    const SizedBox(height: 28),

                    // EMAIL FIELD
                    _buildField(
                      label: "Email",
                      controller: emailController,
                      icon: Icons.email_outlined,
                      hint: "contoh@email.com",
                      keyboardType: TextInputType.emailAddress,
                      errorText: emailError,
                      onChanged: (_) {
                        if (emailError != null) setState(() => emailError = null);
                      },
                    ),

                    const SizedBox(height: 20),

                    // PASSWORD FIELD
                    _buildField(
                      label: "Password",
                      controller: passwordController,
                      icon: Icons.lock_outline_rounded,
                      hint: "Min. 6 karakter (huruf/angka)",
                      isPassword: true,
                      errorText: passwordError,
                      onChanged: (_) {
                        if (passwordError != null) setState(() => passwordError = null);
                      },
                    ),

                    const SizedBox(height: 12),

                    // LUPA PASSWORD
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LupaPassword()),
                        ),
                        child: Text(
                          "Lupa password?",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // BUTTON LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: isLoading
                          ? const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                          : ElevatedButton(
                        onPressed: handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // REGISTER LINK
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterPage()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            text: "Pengguna baru? ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
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

              const SizedBox(height: 40),

              Text(
                "© 2025 JIM Pekanbaru",
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}