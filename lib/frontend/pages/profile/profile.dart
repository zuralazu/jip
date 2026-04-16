import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/base_page.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';
import '../../widgets/bottom_bar.dart';
import '../profile/edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with BasePage {
  Map<String, dynamic>? profile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  void fetchProfile() async {
    try {
      final result = await ApiService.getProfile();
      if (result["statusCode"] == 200) {
        setState(() {
          profile = result["data"]["data"];
          isLoading = false;
        });
      } else {
        setState(() {
          profile = null;
          isLoading = false;
        });
      }
    } catch (e) {
      handleApiError(e);
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEBEBEB), width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: const Text(
        'Profile',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (profile == null) {
      return const Center(
        child: Text('Gagal memuat data profile'),
      );
    }

    final instansi = profile!['instansi'];
    final name = profile!['name'] ?? '-';
    final initials = _getInitials(name);
    final String? logoPath = instansi?['logo_instansi'];
    final String serverUrl = ApiService.baseUrl.replaceAll('/api', '');
    final String? logoUrl = (logoPath != null && logoPath.isNotEmpty)
        ? '$serverUrl/storage/$logoPath'
        : null;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => fetchProfile(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          _buildAvatarSection(name, initials, logoUrl),

          const SizedBox(height: 24),

          _buildSectionLabel('Informasi Akun'),
          const SizedBox(height: 10),
          _buildInfoGroup([
            _InfoItem(
              icon: Icons.person_outline_rounded,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF5048E5),
              label: 'Nama',
              value: profile!['name'],
            ),
            _InfoItem(
              icon: Icons.email_outlined,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
              label: 'Email',
              value: profile!['email'],
            ),
            _InfoItem(
              icon: Icons.phone_outlined,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFE65100),
              label: 'No HP',
              value: profile!['no_hp'],
            ),
          ]),

          if (instansi != null) ...[
            const SizedBox(height: 24),
            _buildSectionLabel('Instansi'),
            const SizedBox(height: 10),
            _buildInfoGroup([
              _InfoItem(
                icon: Icons.business_outlined,
                iconBg: const Color(0xFFE0F2F1),
                iconColor: const Color(0xFF00695C),
                label: 'Nama Instansi',
                value: instansi['nama_instansi'],
              ),
              _InfoItem(
                icon: Icons.location_on_outlined,
                iconBg: const Color(0xFFFCE4EC),
                iconColor: const Color(0xFFC2185B),
                label: 'Alamat',
                value: instansi['alamat'],
                isLast: true,
              ),
            ]),
          ],

          const SizedBox(height: 32),

          _buildEditButton(),

          const SizedBox(height: 16),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(String name, String initials, String? logoUrl) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 0.5),
      ),
      child: Column(
        children: [
          ClipOval(
            child: logoUrl != null
                ? CachedNetworkImage(
              imageUrl: logoUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildInitialsAvatar(initials),
              errorWidget: (context, url, error) =>
                  _buildInitialsAvatar(initials),
            )
                : _buildInitialsAvatar(initials),
          ),

          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFFAAAAAA),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A90D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGroup(List<_InfoItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 0.5),
      ),
      child: Column(
        children: items.map((item) => _buildInfoRow(item)).toList(),
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: item.isLast
            ? null
            : const Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: handleEdit,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFFFFFFF), width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.account_circle_outlined, color: Color(0xFF000000), size: 16),
            SizedBox(width: 8),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF040404),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: handleLogout,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFFFF0F0),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFFFCDD2), width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 16),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD32F2F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void handleEdit() async {
    if (profile == null) return;

    final bool? isUpdated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(profileData: profile!),
      ),
    );

    if (isUpdated == true) {
      setState(() {
        isLoading = true;
      });
      fetchProfile();
    }
  }

  void handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.red, size: 26),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keluar Aplikasi?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kamu akan keluar dari akun ini.\nPastikan kamu sudah menyimpan data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final result = await ApiService.logout();
                        if (result["statusCode"] == 200) {
                          await AuthService.logout();
                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (route) => false,
                          );
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Gagal logout, coba lagi'),
                              backgroundColor: Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Ya, Keluar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

class _InfoItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? value;
  final bool isLast;

  const _InfoItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isLast = false,
  });
}