import 'package:flutter/material.dart';
import '../../core/base_page.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../utils/currency_format.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/transaction_card.dart';
import '../../services/auth_service.dart';
import '../tugas/tugas_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with BasePage {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String? errorMessage;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboard();
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
        setState(() {
          errorMessage = 'Gagal memuat data (${result["statusCode"]})';
          isLoading = false;
        });
      }
    } catch (e) {
      handleApiError(e);
    }
  }

  // Ganti handleLogout dengan ini
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
              // Icon
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

              // Judul
              const Text(
                'Keluar Aplikasi?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),

              // Subjudul
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

              // Tombol
              Row(
                children: [
                  // Batal
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

                  // Ya, Keluar
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
                            context,
                            '/login',
                                (route) => false,
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
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  fetchDashboard();
                },
                child: const Text('Coba Lagi',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final header    = dashboardData!["header"]    as Map<String, dynamic>? ?? {};
    final statistik = dashboardData!["statistik"] as Map<String, dynamic>? ?? {};
    final riwayat   = dashboardData!["riwayat_transaksi"] as List? ?? [];

    // ── Layout utama: TIDAK scroll, transaction list yang scroll ──
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header biru (fixed)
          _buildHeader(header),

          // Stat row (fixed)
          _buildStatRow(statistik),

          const SizedBox(height: 8),

          // Transaction list (Expanded → internal ListView yang scroll)
          Expanded(
            child: _buildTransactionList(riwayat),
          ),

          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── HEADER BIRU ──────────────────────────────────────────────
  Widget _buildHeader(Map<String, dynamic> header) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${header['nama_inspektor']}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pantau kinerja dan total pendapatan\nkamu di sini. Semangat!',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Saldo Komisi',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormat.toRupiah(header['saldo_komisi']),
                      style: const TextStyle(
                        color: AppColors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {},
              icon: const Icon(Icons.assignment_outlined,
                  color: AppColors.primary, size: 18),
              label: const Text(
                'Laksanakan Tugas Inspeksi',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── STAT ROW ─────────────────────────────────────────────────
  Widget _buildStatRow(Map<String, dynamic> statistik) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          StatCard(
            label: 'Pendapatan\n(Selesai)',
            // ← format rupiah
            value: CurrencyFormat.toRupiah(statistik['pendapatan_selesai']),
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

  // ── TRANSACTION LIST — card fixed, isi yang scroll ────────────
  Widget _buildTransactionList(List riwayat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul — padding bawah 0 supaya tidak ada jarak ke list
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Riwayat Share Cost Transaksi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),

          // Divider tipis langsung di bawah judul
          const Divider(height: 12, thickness: 0.5, color: Color(0xFFEEEEEE)),

          // ListView yang scroll di dalam card
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,  // ← hapus padding default
              itemCount: riwayat.length,
              itemBuilder: (context, index) =>
                  TransactionCard(item: riwayat[index]),
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM NAV ────────────────────────────────────────────────
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
                onTap: () {
                  if (isLogout) {
                    handleLogout();
                    return;
                  }

                  setState(() => _currentIndex = i);

                  // 🔥 NAVIGASI
                  if (i == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TugasPage(),
                      ),
                    );
                  }
                },
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
}