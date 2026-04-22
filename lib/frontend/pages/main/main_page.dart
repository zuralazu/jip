import 'package:flutter/material.dart';
import '../../widgets/bottom_bar.dart';
import '../tugas/tugas_page.dart';
import '../profile/profile.dart';
import '../dashboard/dashboard_page.dart';
import '../login/login_page.dart';
import '../slip-komisi/slip_komisi_page.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;
  const MainPage({super.key, this.initialIndex = 0});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _currentIndex;
  Map<String, dynamic>? dashboardData;

  bool isLoading = true;
  String? errorMessage;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    fetchDashboard();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    setState(() {
      _currentIndex = index;
    });
  }

  void fetchDashboard() async {
    try {
      final result = await ApiService.getDashboard();

      if (result["statusCode"] == 200) {
        final data = result["data"];
        final extracted = data["data"] ?? data;

        if (extracted != null) {
          setState(() {
            dashboardData = extracted;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Struktur data tidak sesuai';
            isLoading = false;
          });
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        setState(() {
          errorMessage = 'Gagal memuat data (${result["statusCode"]})';
          isLoading = false;
        });
      }
    } catch (e) {
      handleApiError(e);
    }
  }

  void handleApiError(dynamic e) {
    setState(() {
      errorMessage = 'Terjadi kesalahan jaringan: $e';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (errorMessage != null || dashboardData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? 'Data tidak tersedia',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  fetchDashboard();
                },
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // PINDAHKAN LIST HALAMAN KE SINI!
    // Kirim dashboardData yang sudah didapat ke DashboardPage
    final List<Widget> pages = [
      DashboardPage(dashboardData: dashboardData!), // <-- Ini kuncinya
      const TugasPage(),
      const SlipKomisiPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: pages, // Gunakan list yang ada di atas
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}