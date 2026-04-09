import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/transaction_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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
    final result = await ApiService.getDashboard();

    // Debug: print dulu struktur responsenya
    debugPrint('FULL RESPONSE: $result');
    debugPrint('STATUS CODE: ${result["statusCode"]}');
    debugPrint('DATA: ${result["data"]}');

    if (result["statusCode"] == 200) {
      final data = result["data"];

      // Cek struktur: ada yang langsung "data", ada yang tidak
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

    // Tampilkan error kalau ada
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
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  fetchDashboard();
                },
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Akses data dengan null-safety
    final header    = dashboardData!["header"]    as Map<String, dynamic>? ?? {};
    final statistik = dashboardData!["statistik"] as Map<String, dynamic>? ?? {};
    final riwayat   = dashboardData!["riwayat_transaksi"] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(header),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow(statistik),
                  const SizedBox(height: 16),
                  _buildTransactionList(riwayat),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
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
          // Baris atas: Sapaan + Saldo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sapaan
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

              // Kartu Saldo
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2)),
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
                      'Rp. ${header['saldo_komisi']}',
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

          // Tombol Tugas
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
              icon: const Icon(
                Icons.assignment_outlined,
                color: AppColors.primary,
                size: 18,
              ),
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
            value: 'Rp. ${statistik['pendapatan_selesai']}',
            icon: Icons.wallet_outlined,
            iconBg: AppColors.yellow.withOpacity(0.2),
            iconColor: AppColors.yellow,
          ),
          const SizedBox(width: 12),
          StatCard(
            label: 'Total Tugas',
            value: '${statistik['total_tugas']}',
            icon: Icons.list_alt_outlined,
            iconBg: AppColors.primary.withOpacity(0.1),
            iconColor: AppColors.primary,
          ),
          const SizedBox(width: 12),
          StatCard(
            label: 'Inspeksi\nSelesai',
            value: '${statistik['inspeksi_selesai']}',
            icon: Icons.check_circle_outline_rounded,
            iconBg: const Color(0xFF2ECC71).withOpacity(0.15),
            iconColor: const Color(0xFF2ECC71),
          ),
        ],
      ),
    );
  }

  // ── TRANSACTION LIST ──────────────────────────────────────────
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Text(
              'Riwayat Share Cost Transaksi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: riwayat.length,
            itemBuilder: (context, index) =>
                TransactionCard(item: riwayat[index]),
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _currentIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.yellow.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon dengan bubble kuning kalau aktif
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.yellow
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          items[i]['icon'] as IconData,
                          size: 22,
                          color: isActive
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
                          color: isActive
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