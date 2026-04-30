import 'package:flutter/material.dart';
import '../../core/base_page.dart';
import '../../utils/colors.dart';
import '../../services/api_service.dart';
import '../login/login_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with BasePage {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nohpController = TextEditingController();
  final TextEditingController namaInstansiController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();

  File? _logoImage;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  bool obscurePassword = true;

  // Error state per field
  String? nameError;
  String? emailError;
  String? passwordError;
  String? nohpError;
  String? namaInstansiError;
  String? alamatError;
  String? logoError;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nohpController.dispose();
    namaInstansiController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  // ─── Pick Logo ────────────────────────────────────────────────────────────────

  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoImage = File(pickedFile.path);
        logoError = null;
      });
    }
  }

  void _removeLogo() => setState(() {
    _logoImage = null;
    logoError = "Logo instansi wajib diupload";
  });

  // ─── Validasi ────────────────────────────────────────────────────────────────

  bool _validateName(String value) {
    if (value.trim().isEmpty) {
      setState(() => nameError = "Nama lengkap tidak boleh kosong");
      return false;
    }
    if (value.trim().length < 3) {
      setState(() => nameError = "Nama minimal 3 karakter");
      return false;
    }
    setState(() => nameError = null);
    return true;
  }

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

  bool _validateNohp(String value) {
    if (value.isEmpty) {
      setState(() => nohpError = "Nomor HP tidak boleh kosong");
      return false;
    }
    final phoneRegex = RegExp(r'^[0-9]{9,13}$');
    if (!phoneRegex.hasMatch(value)) {
      setState(() => nohpError = "Nomor HP tidak valid (9–13 digit angka)");
      return false;
    }
    setState(() => nohpError = null);
    return true;
  }

  bool _validateNamaInstansi(String value) {
    if (value.trim().isEmpty) {
      setState(() => namaInstansiError = "Nama perusahaan tidak boleh kosong");
      return false;
    }
    setState(() => namaInstansiError = null);
    return true;
  }

  bool _validateAlamat(String value) {
    if (value.trim().isEmpty) {
      setState(() => alamatError = "Alamat perusahaan tidak boleh kosong");
      return false;
    }
    setState(() => alamatError = null);
    return true;
  }

  bool _validateLogo() {
    if (_logoImage == null) {
      setState(() => logoError = "Logo instansi wajib diupload");
      return false;
    }
    setState(() => logoError = null);
    return true;
  }

  bool _validateAll() {
    final nameOk = _validateName(nameController.text);
    final emailOk = _validateEmail(emailController.text);
    final passwordOk = _validatePassword(passwordController.text);
    final nohpOk = _validateNohp(nohpController.text);
    final namaInstansiOk = _validateNamaInstansi(namaInstansiController.text);
    final alamatOk = _validateAlamat(alamatController.text);
    final logoOk = _validateLogo();
    return nameOk && emailOk && passwordOk && nohpOk && namaInstansiOk && alamatOk && logoOk;
  }

  // ─── Handler ──────────────────────────────────────────────────────────────────

  void handleRegister() async {
    if (!_validateAll()) return;

    setState(() => isLoading = true);

    try {
      final result = await ApiService.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        noHp: nohpController.text,
        namaInstansi: namaInstansiController.text.trim(),
        alamat: alamatController.text.trim(),
        logoInstansi: _logoImage,
      );

      final statusCode = result["statusCode"];

      if (statusCode == 201) {
        _showSnackbar("Registrasi berhasil! Silakan login.", isError: false);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else if (statusCode == 422) {
        final errors = result["data"]["errors"];
        String errorMsg = "Data tidak valid.";
        if (errors != null && errors.values.isNotEmpty) {
          errorMsg = errors.values.first[0].toString();
        }
        _showSnackbar(errorMsg);
      } else {
        _showSnackbar("Terjadi kesalahan (kode: $statusCode)");
      }
    } catch (e) {
      _showSnackbar("Tidak bisa terhubung ke server");
      debugPrint("ERROR REGISTER: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
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

  // ─── Widget Helpers ───────────────────────────────────────────────────────────

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? errorText,
    void Function(String)? onChanged,
    int maxLines = 1,
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
          maxLines: isPassword ? 1 : maxLines,
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
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, height: 1.2),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(color: Colors.white.withOpacity(0.15), thickness: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Logo Instansi",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickLogo,
          child: Container(
            width: double.infinity,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: logoError != null ? Colors.red.shade300 : Colors.white.withOpacity(0.2),
              ),
            ),
            child: _logoImage == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: Colors.white54, size: 28),
                const SizedBox(height: 8),
                Text(
                  "Ketuk untuk upload logo",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            )
                : Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_logoImage!, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _removeLogo,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (logoError != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                logoError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, height: 1.2),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),

              Image.asset('assets/images/logo.png', width: 140),

              const SizedBox(height: 32),

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
                    const Text(
                      "Registrasi",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Lengkapi data diri dan perusahaan kamu",
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
                    ),

                    const SizedBox(height: 28),

                    // ── DATA DIRI ──
                    _buildSectionLabel("DATA DIRI"),

                    _buildField(
                      label: "Nama Lengkap",
                      controller: nameController,
                      icon: Icons.person_outline_rounded,
                      hint: "Masukkan nama lengkap",
                      errorText: nameError,
                      onChanged: (_) {
                        if (nameError != null) setState(() => nameError = null);
                      },
                    ),
                    const SizedBox(height: 20),

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
                    const SizedBox(height: 20),

                    _buildField(
                      label: "Nomor Handphone",
                      controller: nohpController,
                      icon: Icons.phone_android_outlined,
                      hint: "08xxxxxxxxxx",
                      keyboardType: TextInputType.phone,
                      errorText: nohpError,
                      onChanged: (_) {
                        if (nohpError != null) setState(() => nohpError = null);
                      },
                    ),

                    const SizedBox(height: 28),

                    // ── DATA PERUSAHAAN ──
                    _buildSectionLabel("DATA PERUSAHAAN"),

                    _buildField(
                      label: "Nama Perusahaan",
                      controller: namaInstansiController,
                      icon: Icons.business_outlined,
                      hint: "Nama instansi / perusahaan",
                      errorText: namaInstansiError,
                      onChanged: (_) {
                        if (namaInstansiError != null) setState(() => namaInstansiError = null);
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildField(
                      label: "Alamat Perusahaan",
                      controller: alamatController,
                      icon: Icons.location_on_outlined,
                      hint: "Alamat lengkap perusahaan",
                      maxLines: 2,
                      errorText: alamatError,
                      onChanged: (_) {
                        if (alamatError != null) setState(() => alamatError = null);
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildLogoPicker(),

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
                        onPressed: handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Registrasi",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            text: "Sudah punya akun? ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 13,
                            ),
                            children: const [
                              TextSpan(
                                text: "Login di sini",
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