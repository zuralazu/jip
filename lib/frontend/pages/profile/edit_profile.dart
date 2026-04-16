import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfilePage({super.key, required this.profileData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController nohpController;
  late TextEditingController namaInstansiController;
  late TextEditingController alamatController;

  File? _newLogoImage;
  String? _oldLogoUrl;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final instansi = widget.profileData['instansi'] ?? {};

    nameController = TextEditingController(text: widget.profileData['name'] ?? '');
    emailController = TextEditingController(text: widget.profileData['email'] ?? '');
    nohpController = TextEditingController(text: widget.profileData['no_hp'] ?? '');
    namaInstansiController = TextEditingController(text: instansi['nama_instansi'] ?? '');
    alamatController = TextEditingController(text: instansi['alamat'] ?? '');

    final String? logoPath = instansi['logo_instansi'];
    if (logoPath != null && logoPath.isNotEmpty) {
      final String serverUrl = ApiService.baseUrl.replaceAll('/api', '');
      _oldLogoUrl = '$serverUrl/storage/$logoPath';
    }
  }

  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newLogoImage = File(pickedFile.path);
      });
    }
  }

  void handleSave() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama dan Email wajib diisi!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await ApiService.updateProfile(
        name: nameController.text,
        email: emailController.text,
        noHp: nohpController.text,
        namaInstansi: namaInstansiController.text,
        alamat: alamatController.text,
        logoInstansi: _newLogoImage,
      );

      if (result["statusCode"] == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile berhasil diperbarui"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        String errorMsg = result["data"]["message"] ?? "Gagal menyimpan data (Kode: ${result["statusCode"]})";

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red, duration: const Duration(seconds: 4))
        );
        print("====== ERROR BACKEND: ${result["data"]} ======");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak bisa terhubung ke server"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildTextField(String hint, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        prefixIcon: Icon(icon, color: Colors.black45),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickLogo,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: ClipOval(
                      child: _newLogoImage != null
                          ? Image.file(_newLogoImage!, fit: BoxFit.cover)
                          : (_oldLogoUrl != null
                          ? CachedNetworkImage(
                        imageUrl: _oldLogoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Icon(Icons.business, size: 40, color: Colors.grey),
                        errorWidget: (context, url, error) => const Icon(Icons.business, size: 40, color: Colors.grey),
                      )
                          : const Icon(Icons.business, size: 40, color: Colors.grey)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Data Pribadi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildTextField("Nama Lengkap", nameController, Icons.person),
                  const SizedBox(height: 12),
                  _buildTextField("Email", emailController, Icons.email),
                  const SizedBox(height: 12),
                  _buildTextField("Nomor HP", nohpController, Icons.phone_android),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Data Instansi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildTextField("Nama Instansi", namaInstansiController, Icons.business),
                  const SizedBox(height: 12),
                  _buildTextField("Alamat Instansi", alamatController, Icons.location_on),
                ],
              ),
            ),

            const SizedBox(height: 32),

            isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : CustomButton(text: "Simpan Perubahan", onPressed: handleSave),
          ],
        ),
      ),
    );
  }
}