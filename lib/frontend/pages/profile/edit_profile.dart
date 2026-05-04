import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/colors.dart';
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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    nohpController.dispose();
    namaInstansiController.dispose();
    alamatController.dispose();
    super.dispose();
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
      _showSnackBar('Nama dan Email wajib diisi!', isError: true);
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
        _showSnackBar('Profile berhasil diperbarui', isError: false);
        Navigator.pop(context, true);
      } else {
        final errorMsg = result["data"]["message"] ??
            "Gagal menyimpan data (Kode: ${result["statusCode"]})";
        _showSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      _showSnackBar('Tidak bisa terhubung ke server', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          children: [
            _buildAvatarCard(),
            const SizedBox(height: 16),
            _buildFormCard(
              label: 'DATA PRIBADI',
              accentColor: const Color(0xFF5048E5),
              children: [
                _buildField(
                  label: 'Nama Lengkap',
                  controller: nameController,
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF5048E5),
                  hint: 'Masukkan nama lengkap',
                ),
                const SizedBox(height: 10),
                _buildField(
                  label: 'Email',
                  controller: emailController,
                  icon: Icons.email_outlined,
                  iconColor: const Color(0xFF2E7D32),
                  hint: 'Masukkan email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                _buildField(
                  label: 'Nomor HP',
                  controller: nohpController,
                  icon: Icons.phone_outlined,
                  iconColor: const Color(0xFFE65100),
                  hint: 'Masukkan nomor HP',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFormCard(
              label: 'DATA INSTANSI',
              accentColor: const Color(0xFF00695C),
              children: [
                _buildField(
                  label: 'Nama Instansi',
                  controller: namaInstansiController,
                  icon: Icons.business_outlined,
                  iconColor: const Color(0xFF00695C),
                  hint: 'Masukkan nama instansi',
                ),
                const SizedBox(height: 10),
                _buildField(
                  label: 'Alamat Instansi',
                  controller: alamatController,
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFFC2185B),
                  hint: 'Masukkan alamat instansi',
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFEBEBEB), width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCard() {
    final name = widget.profileData['name'] ?? '';
    final initials = _getInitials(name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 0.5),
      ),
      child: GestureDetector(
        onTap: _pickLogo,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                // Gradient ring
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4A90D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: ClipOval(
                    child: _newLogoImage != null
                        ? Image.file(_newLogoImage!, fit: BoxFit.cover)
                        : (_oldLogoUrl != null
                        ? CachedNetworkImage(
                      imageUrl: _oldLogoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          _buildInitialsAvatar(initials),
                      errorWidget: (context, url, error) =>
                          _buildInitialsAvatar(initials),
                    )
                        : _buildInitialsAvatar(initials)),
                  ),
                ),
                // Camera badge
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5048E5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap untuk ganti foto',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      color: const Color(0xFF6C63FF),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String label,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 13,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFAAAAAA),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 5),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFAAAAAA),
            ),
          ),
        ),
        Focus(
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isFocused
                      ? iconColor.withOpacity(0.06)
                      : const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused ? iconColor.withOpacity(0.4) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(icon, color: iconColor, size: 16),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isLoading
          ? Container(
        decoration: BoxDecoration(
          color: const Color(0xFF5048E5).withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
        ),
      )
          : ElevatedButton(
        onPressed: handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5048E5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'Simpan Perubahan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }
}