import 'package:flutter/material.dart';
import '../../core/base_page.dart';
import '../../utils/colors.dart';
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
  bool obscurePassword = true;
  bool obscureConfirm = true;

  // Error state per field
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Validasi ───────────────────────────────────────────────────────────────

  bool _validateEmail(String value) {
    if (value.trim().isEmpty) {
      setState(() => emailError = "Email tidak boleh kosong");
      return false;
    }
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

  bool _validateConfirmPassword(String value) {
    if (value.isEmpty) {
      setState(() => confirmPasswordError = "Konfirmasi password tidak boleh kosong");
      return false;
    }
    if (value != passwordController.text) {
      setState(() => confirmPasswordError = "Password tidak cocok");
      return false;
    }
    setState(() => confirmPasswordError = null);
    return true;
  }

  bool _validateAll() {
    final emailOk = _validateEmail(emailController.text);
    final passwordOk = _validatePassword(passwordController.text);
    final confirmOk = _validateConfirmPassword(confirmPasswordController.text);
    return emailOk && passwordOk && confirmOk;
  }

  // ─── Handler ─────────────────────────────────────────────────────────────────

  void handleLupaPassword() async {
    if (!_validateAll()) return;

    setState(() => isLoading = true);

    try {
      final result = await ApiService.lupaPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
        confirm_password: confirmPasswordController.text,
      );

      final statusCode = result["statusCode"];

      if (statusCode == 200) {
        _showSnackbar("Password berhasil diperbarui! Silakan login kembali.", isError: false);

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      } else if (statusCode == 401) {
        _showSnackbar("Email tidak terdaftar atau data salah");
      } else {
        _showSnackbar("Terjadi kesalahan (kode: $statusCode)");
      }
    } catch (e) {
      _showSnackbar("Tidak bisa terhubung ke server");
      debugPrint("ERROR LUPA PASSWORD: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Widget Helper ───────────────────────────────────────────────────────────

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool? obscure,
    VoidCallback? onToggleObscure,
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
          obscureText: isPassword ? (obscure ?? true) : false,
          onChanged: (val) {
            if (onChanged != null) onChanged(val);
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            suffixIcon: isPassword
                ? GestureDetector(
              onTap: onToggleObscure,
              child: Icon(
                (obscure ?? true) ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                color: errorText != null ? Colors.red.shade300 : Colors.white.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red.shade300 : Colors.white,
                width: 1.5,
              ),
            ),
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
              const SizedBox(height: 48),

              Image.asset('assets/images/logo.png', width: 140),

              const SizedBox(height: 40),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
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
                      "Ganti Password",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Lengkapi data di bawah untuk mengganti password akun Anda.",
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
                    ),

                    const SizedBox(height: 28),

                    // EMAIL
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

                    // PASSWORD BARU
                    _buildField(
                      label: "Password Baru",
                      controller: passwordController,
                      icon: Icons.lock_outline_rounded,
                      hint: "Min. 6 karakter (huruf/angka)",
                      isPassword: true,
                      obscure: obscurePassword,
                      onToggleObscure: () => setState(() => obscurePassword = !obscurePassword),
                      errorText: passwordError,
                      onChanged: (_) {
                        if (passwordError != null) setState(() => passwordError = null);
                        // Re-validasi confirm password jika sudah diisi
                        if (confirmPasswordController.text.isNotEmpty && confirmPasswordError != null) {
                          setState(() => confirmPasswordError = null);
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // KONFIRMASI PASSWORD
                    _buildField(
                      label: "Konfirmasi Password Baru",
                      controller: confirmPasswordController,
                      icon: Icons.lock_reset_rounded,
                      hint: "Ulangi password baru",
                      isPassword: true,
                      obscure: obscureConfirm,
                      onToggleObscure: () => setState(() => obscureConfirm = !obscureConfirm),
                      errorText: confirmPasswordError,
                      onChanged: (_) {
                        if (confirmPasswordError != null) setState(() => confirmPasswordError = null);
                      },
                    ),

                    const SizedBox(height: 28),

                    // BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: isLoading
                          ? const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                          : ElevatedButton(
                        onPressed: handleLupaPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Ganti Password",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // KEMBALI KE LOGIN
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          "Kembali ke Login",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white.withOpacity(0.4),
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