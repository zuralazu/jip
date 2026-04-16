import 'package:flutter/material.dart';
import '../../core/base_page.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nohpController = TextEditingController();
  final TextEditingController namaInstansiController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();

  File? _logoImage;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;

  @override
  void dispose() {
    // 🔥 Fix: Membersihkan semua controller untuk menghindari memory leak
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    nohpController.dispose();
    namaInstansiController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoImage = File(pickedFile.path);
      });
    }
  }

  void handleRegister() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showMessage("Nama, Email, dan Password wajib diisi!");
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.register(
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
        noHp: nohpController.text,
        namaInstansi: namaInstansiController.text,
        alamat: alamatController.text,
        logoInstansi: _logoImage,
      );

      final statusCode = result["statusCode"];

      if (statusCode == 201) {
        _showSuccessMessage("Registrasi Berhasil! Silakan Login.");

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
        _showMessage(errorMsg);
      } else {
        _showMessage("Terjadi kesalahan (kode: $statusCode)");
      }
    } catch (e) {
      _showMessage("Tidak bisa terhubung ke server");
      debugPrint("ERROR REGISTER: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
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
              const SizedBox(height: 32),

              // LOGO
              Image.asset(
                'assets/images/logo.png',
                width: 140,
              ),

              const SizedBox(height: 32),

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
                      "Registrasi",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Data Diri Kamu dan Perusahaan",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 24),

                    CustomTextField(
                      hint: "Nama Lengkap",
                      controller: nameController,
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      hint: "Email",
                      controller: emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress, // 🔥 Fix: Keyboard email
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      hint: "Password",
                      controller: passwordController,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      hint: "Nomor Handphone",
                      controller: nohpController,
                      prefixIcon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone, // 🔥 Fix: Keyboard phone
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      hint: "Nama Instansi",
                      controller: namaInstansiController,
                      prefixIcon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      hint: "Alamat Instansi",
                      controller: alamatController,
                      prefixIcon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: _pickLogo,
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              style: BorderStyle.solid),
                        ),
                        child: _logoImage == null
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.upload_file,
                                color: Colors.white70),
                            SizedBox(height: 8),
                            Text("Upload Logo Instansi (Opsional)",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_logoImage!,
                              fit: BoxFit.cover, width: double.infinity),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // BUTTON REGISTRASI
                    isLoading
                        ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                        : CustomButton(
                      text: "Registrasi",
                      onPressed: handleRegister,
                    ),

                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Sudah punya akun? ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
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
                "© 2025 JIM Pekanbaru", // 🔥 Fix: Menghapus argumen ganda yang menyebabkan error
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
