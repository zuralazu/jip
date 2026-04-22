import 'package:flutter/material.dart';
import '../../core/base_page.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../utils/currency_format.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/transaction_card.dart';
import '../../services/auth_service.dart';
import '../tugas/tugas_page.dart';
import '../../widgets/bottom_bar.dart';
import 'dart:async';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with BasePage {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String? errorMessage;

  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    fetchDashboard();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void fetchDashboard() async {
    try {
      final result = await ApiService.getDashboard();

      if (result["statusCode"] == 200) {
        final data = result["data"];
        // PERBAIKAN 1: Tambahkan "?" pada data?["data"]
        // Mencegah error jika result["data"] bernilai null dari API
        final extracted = data?["data"] ?? data;

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
        setState(() {
          errorMessage = 'Gagal memuat data (${result["statusCode"]})';
          isLoading = false;
        });
      }
    } catch (e) {
      handleApiError(e); // Asumsi fungsi ini ada di mixin BasePage kamu
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
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 26),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keluar Aplikasi?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kamu akan keluar dari akun ini.\nPastikan kamu sudah menyimpan data.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal', style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final result = await ApiService.logout();
                        if (result["statusCode"] == 200) {
                          await AuthService.logout();
                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Gagal logout, coba lagi'),
                              backgroundColor: Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
              Text(errorMessage ?? 'Data tidak tersedia', style: const TextStyle(color: Colors.red)),
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

    final header    = dashboardData!["header"]    as Map<String, dynamic>? ?? {};
    final statistik = dashboardData!["statistik"] as Map<String, dynamic>? ?? {};
    final riwayat   = dashboardData!["riwayat_transaksi"] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(header),
          _buildStatRow(statistik),
          const SizedBox(height: 8),
          Expanded(child: _buildTransactionList(riwayat)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> header) {
    final now = _currentTime;
    String greeting;
    IconData greetingIcon;
    if (now.hour < 11) { greeting = 'Selamat Pagi'; greetingIcon = Icons.wb_sunny_outlined; }
    else if (now.hour < 15) { greeting = 'Selamat Siang'; greetingIcon = Icons.light_mode_outlined; }
    else if (now.hour < 18) { greeting = 'Selamat Sore'; greetingIcon = Icons.wb_twilight_outlined; }
    else { greeting = 'Selamat Malam'; greetingIcon = Icons.nights_stay_outlined; }

    final formattedDate = _formatDate(now);
    final formattedTime = _formatTime(now);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(greetingIcon, color: AppColors.yellow, size: 16),
              const SizedBox(width: 6),
              Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF2ECC71), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('Aktif', style: TextStyle(color: Color(0xFF2ECC71), fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                // PERBAIKAN 2: Berikan nilai default 'Pengguna' agar terhindar dari error "Halo, null!"
                child: Text(
                  'Halo, ${header['nama_inspektor'] ?? 'Pengguna'}!',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formattedTime, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(formattedDate, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Pantau kinerja dan total pendapatan\nkamu di sini. Semangat!', style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    const hari = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return '${hari[dt.weekday % 7]}, ${dt.day} ${bulan[dt.month]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s WIB';
  }

  Widget _buildStatRow(Map<String, dynamic> statistik) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          StatCard(
            label: 'Pendapatan\n(Selesai)',
            // PERBAIKAN 3: Berikan fallback (?? 0) agar CurrencyFormat tidak pernah menerima null
            value: CurrencyFormat.toRupiah(statistik['pendapatan_selesai'] ?? 0),
            icon: Icons.wallet_outlined,
            iconBg: AppColors.yellow.withOpacity(0.2),
            iconColor: AppColors.yellow,
          ),
          const SizedBox(width: 12),
          StatCard(
            label: 'Total Tugas',
            value: '${statistik['total_tugas'] ?? 0}',
            icon: Icons.list_alt_outlined,
            iconBg: AppColors.primary.withOpacity(0.1),
            iconColor: AppColors.primary,
          ),
          const SizedBox(width: 12),
          StatCard(
            label: 'Inspeksi\nSelesai',
            value: '${statistik['inspeksi_selesai'] ?? 0}',
            icon: Icons.check_circle_outline_rounded,
            iconBg: const Color(0xFF2ECC71).withOpacity(0.15),
            iconColor: const Color(0xFF2ECC71),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List riwayat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('Riwayat Share Cost Transaksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ),
          const Divider(height: 12, thickness: 0.5, color: Color(0xFFEEEEEE)),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: riwayat.length,
              itemBuilder: (context, index) => TransactionCard(item: riwayat[index]),
            ),
          ),
        ],
      ),
    );
  }
}