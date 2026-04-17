import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import 'detail_komisi_page.dart';

class SlipKomisiPage extends StatefulWidget {
  const SlipKomisiPage({super.key});

  @override
  State<SlipKomisiPage> createState() => _SlipKomisiPageState();
}

class _SlipKomisiPageState extends State<SlipKomisiPage>
    with SingleTickerProviderStateMixin {
  List slipList = [];
  bool isLoading = true;
  String _filterStatus = 'semua'; // semua | proses | cair
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    fetchSlipKomisi();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void fetchSlipKomisi() async {
    setState(() => isLoading = true);
    try {
      final result = await ApiService.getSlipKomisi();
      if (result['statusCode'] == 200) {
        final body = result['data'];
        if (body is Map<String, dynamic> && body['data'] is List) {  // 'status' bukan dicek, 'data' tetap ada
          setState(() {
            slipList = body['data'];
            isLoading = false;
          });
          _animController.forward(from: 0);
        }
      } else {
        setState(() {
          slipList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List get filteredList {
    if (_filterStatus == 'semua') return slipList;
    return slipList
        .where((s) =>
    (s['status'] ?? '').toString().toLowerCase() == _filterStatus)
        .toList();
  }

  int get totalCair => slipList
      .where((s) => (s['status'] ?? '').toString().toLowerCase() == 'cair')
      .length;

  int get totalProses => slipList
      .where((s) => (s['status'] ?? '').toString().toLowerCase() == 'proses')
      .length;

  String _formatRupiah(dynamic nominal) {
    if (nominal == null) return 'Rp 0';
    final n = int.tryParse(nominal.toString()) ?? 0;
    final formatted = n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(),
          _buildSummaryCards(),
          _buildFilterTabs(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Slip Komisi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Riwayat pencairan komisi inspeksi kamu',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // Hapus totalNominal fold, ganti jadi count saja atau hilangkan
  Widget _buildSummaryCards() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Row(
        children: [
          _summaryCard(
            icon: Icons.receipt_long_rounded,
            label: 'Total Slip',
            value: '${slipList.length}',
            iconColor: AppColors.yellow,
            flex: 1,
          ),
          const SizedBox(width: 10),
          _summaryCard(
            icon: Icons.check_circle_rounded,
            label: 'Sudah Cair',
            value: '$totalCair',
            iconColor: const Color(0xFF4ADE80),
            flex: 1,
          ),
          const SizedBox(width: 10),
          _summaryCard(
            icon: Icons.pending_actions_rounded,
            label: 'Dalam Proses',
            value: '$totalProses',
            iconColor: const Color(0xFF60A5FA),
            flex: 1,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required int flex,
    bool small = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: small ? 12 : 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      {'key': 'semua', 'label': 'Semua'},
      {'key': 'proses', 'label': 'Proses'},
      {'key': 'cair', 'label': 'Cair'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: tabs.map((tab) {
          final isActive = _filterStatus == tab['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filterStatus = tab['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  tab['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 38,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _filterStatus == 'semua'
                  ? 'Belum ada slip komisi'
                  : 'Tidak ada slip berstatus "${_filterStatus == 'proses' ? 'Proses' : 'Cair'}"',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Slip akan muncul saat tugas selesai',
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => fetchSlipKomisi(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final item = filteredList[index];
          return _SlipKomisiCard(
            item: item,
            index: index,
            formatRupiah: _formatRupiah,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailKomisiPage(slipData: item),
                ),
              );
              if (result == true) fetchSlipKomisi();
            },
          );
        },
      ),
    );
  }
}

class _SlipKomisiCard extends StatelessWidget {
  final Map item;
  final int index;
  final String Function(dynamic) formatRupiah;
  final VoidCallback onTap;

  const _SlipKomisiCard({
    required this.item,
    required this.index,
    required this.formatRupiah,
    required this.onTap,
  });

  // Status check pakai 'status' bukan 'status_komisi'
  Color get _statusColor {
    final s = (item['status'] ?? '').toString().toLowerCase();
    if (s == 'cair') return const Color(0xFF16A34A);
    return const Color(0xFFF59E0B);
  }

  Color get _statusBg {
    final s = (item['status'] ?? '').toString().toLowerCase();
    if (s == 'cair') return const Color(0xFFDCFCE7);
    return const Color(0xFFFEF3C7);
  }

  IconData get _statusIcon {
    final s = (item['status'] ?? '').toString().toLowerCase();
    if (s == 'cair') return Icons.check_circle_rounded;
    return Icons.schedule_rounded;
  }

  String get _statusLabel => item['status']?.toString() ?? 'Proses';

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 60)),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top section
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['slip_komisi']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['waktu']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, size: 12, color: _statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel,
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 1,
                color: Colors.grey.shade100,
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),

              // Bottom section
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.local_atm_rounded,
                        size: 16, color: AppColors.textGrey),
                    const SizedBox(width: 6),
                    Text(
                      item['biaya_inspeksi']?.toString() ?? 'Rp 0',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.remove_red_eye_rounded,
                              size: 13, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Lihat Detail',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}