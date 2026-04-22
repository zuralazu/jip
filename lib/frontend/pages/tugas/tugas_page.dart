import 'package:flutter/material.dart';
import '../../core/base_page.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';
import '../../widgets/tugas_card.dart';
import '../../widgets/bottom_bar.dart';
import '../profile/profile.dart';

class TugasPage extends StatefulWidget {
  const TugasPage({super.key});

  @override
  State<TugasPage> createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage> with BasePage {
  List tugasList = [];
  bool isLoading = true;
  String _selectedFilter = 'Semua';

  final List<Map<String, String>> _filters = [
    {'key': 'Semua',    'label': 'Semua'},
    {'key': 'pending',  'label': 'Proses Inspeksi'},
    {'key': 'selesai',  'label': 'Selesai'},
  ];

  List get _filteredList {
    if (_selectedFilter == 'Semua') return tugasList;
    return tugasList
        .where((t) =>
    (t['status_inspeksi'] ?? '').toString().toLowerCase() ==
        _selectedFilter.toLowerCase())
        .toList();
  }

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
      handleApiError(e);
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0: Navigator.pushReplacementNamed(context, '/dashboard'); break;
      case 1: Navigator.pushReplacementNamed(context, '/tugas'); break;
      case 2: Navigator.pushReplacementNamed(context, '/slip-komisi'); break;
      case 3: Navigator.pushReplacementNamed(context, '/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),   // ← chip baru
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/tambah-pesanan');
          if (result == true) fetchTugas();
        },
        backgroundColor: AppColors.yellow,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
        label: const Text(
          'Tambah Pesanan',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
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
                '${tugasList.where((t) => (t['status_inspeksi'] ?? '').toString().toLowerCase() == 'pending').length} Tugas Aktif',
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

  // ── FILTER CHIPS ──────────────────────────────────────────────
  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: _filters.map((tab) {  // ← pakai _filters langsung
          final isActive = _selectedFilter == tab['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = tab['key']!),
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
                    fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── BODY ──────────────────────────────────────────────────────
  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'Semua'
                  ? 'Belum ada tugas'
                  : 'Tidak ada tugas "${_filters.firstWhere((f) => f['key'] == _selectedFilter)['label']}"',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
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
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 90),
        itemCount: _filteredList.length,
        itemBuilder: (context, index) => TugasCard(
          item: _filteredList[index],
          onNavigateBack: fetchTugas,
        ),
      ),
    );
  }
}