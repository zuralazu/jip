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

class _ProfilePageState extends State<ProfilePage>
    with BasePage, SingleTickerProviderStateMixin {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    fetchProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void fetchProfile() async {
    try {
      final result = await ApiService.getProfile();
      if (result["statusCode"] == 200) {
        setState(() {
          profile = result["data"]["data"];
          isLoading = false;
        });
        _animController.forward();
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
        top: MediaQuery.of(context).padding.top + 14,
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
          letterSpacing: -0.3,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat data profile',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
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

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            _animController.reset();
            fetchProfile();
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildHeroCard(name, initials, logoUrl, instansi),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSectionLabel('Informasi Akun'),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildInfoCard([
                  _InfoItem(
                    icon: Icons.person_rounded,
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
                    isLast: true,
                  ),
                ]),
              ),

              if (instansi != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSectionLabel(
                    'Instansi',
                    accentColor: const Color(0xFF00695C),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildInfoCard([
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
                ),
              ],

              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildEditButton(),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildLogoutButton(),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
      String name, String initials, String? logoUrl, dynamic instansi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
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
              child: logoUrl != null
                  ? CachedNetworkImage(
                imageUrl: logoUrl,
                width: 77,
                height: 77,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    _buildInitialsAvatar(initials),
                errorWidget: (context, url, error) =>
                    _buildInitialsAvatar(initials),
              )
                  : _buildInitialsAvatar(initials),
            ),
          ),

          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.2,
            ),
          ),

          if (profile!['email'] != null) ...[
            const SizedBox(height: 3),
            Text(
              profile!['email'],
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFAAAAAA),
              ),
            ),
          ],

          Container(
            height: 0.5,
            color: const Color(0xFFF0F0F0),
            margin: const EdgeInsets.symmetric(vertical: 16),
          ),

          Row(
            children: [
              Expanded(
                child: _buildChip(
                  icon: Icons.verified_rounded,
                  label: 'Terverifikasi',
                  color: const Color(0xFF5048E5),
                  bg: const Color(0xFFEEEDFE),
                ),
              ),
              if (instansi != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildChip(
                    icon: Icons.corporate_fare_rounded,
                    label: instansi['nama_instansi'] ?? '',
                    color: const Color(0xFF00695C),
                    bg: const Color(0xFFE0F2F1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label,
      {Color accentColor = const Color(0xFF5048E5)}) {
    return Row(
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
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFFAAAAAA),
            letterSpacing: 1.0,
          ),
        ),
      ],
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

  Widget _buildInfoCard(List<_InfoItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 0.5),
      ),
      child: Column(
        children: items.map(_buildInfoRow).toList(),
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            width: 34,
            height: 34,
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
                    fontSize: 10,
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
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Color(0xFFDDDDDD),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: handleEdit,
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
            Icon(Icons.edit_rounded, color: Colors.white, size: 15),
            SizedBox(width: 8),
            Text(
              'Edit Profile',
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

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: handleLogout,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFFCDD2), width: 1),
          backgroundColor: const Color(0xFFFFF0F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 15),
            SizedBox(width: 8),
            Text(
              'Keluar Akun',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
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
      _animController.reset();
      setState(() => isLoading = true);
      fetchProfile();
    }
  }

  void handleLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFD32F2F), size: 26),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keluar Aplikasi?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kamu akan keluar dari akun ini.\nPastikan kamu sudah menyimpan data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFAAAAAA),
                  height: 1.6,
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: Color(0xFFAAAAAA),
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
                        backgroundColor: const Color(0xFFD32F2F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
                              backgroundColor: const Color(0xFFD32F2F),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Ya, Keluar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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