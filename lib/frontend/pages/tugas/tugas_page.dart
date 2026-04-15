import 'package:flutter/material.dart';
import '../../core/base_page.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';
import '../../widgets/tugas_card.dart';

class TugasPage extends StatefulWidget {
  const TugasPage({super.key});

  @override
  State<TugasPage> createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage>
    with BasePage {
  List tugasList = [];
  bool isLoading = true;
  int _currentIndex = 1; // Tugas Saya = index 1

  @override
  void initState() {
    super.initState();
    fetchTugas();
  }

  void fetchTugas() async {
    try {
      final result = await ApiService.getTugas();

      if (result["statusCode"] == 200) {
        final body = result["data"];

        if (body is Map<String, dynamic> && body["data"] is List) {
          setState(() {
            tugasList = body["data"];
            isLoading = false;
          });
        } else {
          setState(() {
            tugasList = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          tugasList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      handleApiError(e); // 🔥 AUTO HANDLE TOKEN EXPIRED

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
      // Sudah di halaman ini
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/slip-komisi');
        break;
      case 3:
        handleLogout();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Tugas Inspeksi Saya',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (!isLoading && tugasList.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${tugasList.length} Tugas Aktif',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (tugasList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Belum ada tugas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tugas inspeksi kamu akan muncul di sini',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => fetchTugas(),
      // Di dalam _TugasPageState, ganti ListView.builder jadi ini:
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: tugasList.length,
        itemBuilder: (context, index) => TugasCard(
          item: tugasList[index],
          onNavigateBack: fetchTugas, // 🔥 refresh list setelah balik dari detail
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.speed_rounded, 'label': 'Dashboard'},
      {'icon': Icons.assignment_outlined, 'label': 'Tugas Saya'},
      {'icon': Icons.receipt_long_outlined, 'label': 'Slip Komisi'},
      {'icon': Icons.logout_rounded, 'label': 'Logout'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _currentIndex == i;
              final isLogout = i == 3;

              return GestureDetector(
                onTap: () => _onNavTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.yellow.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isLogout
                              ? Colors.red.withOpacity(0.15)
                              : isActive
                              ? AppColors.yellow
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          items[i]['icon'] as IconData,
                          size: 20,
                          color: isLogout
                              ? Colors.red.shade300
                              : isActive
                              ? AppColors.primaryDark
                              : Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isLogout
                              ? Colors.red.shade300
                              : isActive
                              ? Colors.white
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
  // Jangan lupa tambahkan fungsi handleLogout di _TugasPageState — sama persis dengan yang ada di dashboard:
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
}