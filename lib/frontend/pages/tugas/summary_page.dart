import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/colors.dart';
import '../../services/api_service.dart';

class SummaryPage extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> dataTugas;

  const SummaryPage({
    super.key,
    required this.orderId,
    required this.dataTugas,
  });

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool isLoading = true;
  bool isDownloading = false;
  String? errorMsg;

  Map<String, dynamic> header           = {};
  Map<String, dynamic> ringkasan        = {};
  Map<String, dynamic> informasiDokumen = {};
  Map<String, dynamic> rincianFoto      = {};

  // ─── safe cast ───────────────────────────────────────────────────────────────
  Map<String, dynamic> _safeMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  List<dynamic> _safeList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw;
    return [];
  }

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final res   = await ApiService.getDetailTugas(widget.orderId);
      final outer = _safeMap(res['data']);
      final data  = _safeMap(outer['data']);

      setState(() {
        header           = _safeMap(data['header']);
        ringkasan        = _safeMap(data['ringkasan_inspeksi']);
        informasiDokumen = _safeMap(data['informasi_dokumen']);

        final raw = data['rincian_foto_inspeksi'];
        if (raw is Map) {
          rincianFoto = raw.map((k, v) => MapEntry(k.toString(), v));
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg  = 'Gagal memuat data: $e';
        isLoading = false;
      });
    }
  }

  // ─── REVISI 1: Download PDF — otomatis simpan + tombol buka ─────────────────
  Future<void> _downloadPdf() async {
    setState(() => isDownloading = true);

    try {
      final namaKendaraan = header['nama_kendaraan']
          ?? widget.dataTugas['nama_mobil']
          ?? 'Laporan';
      final namaFile = 'Laporan_Inspeksi_$namaKendaraan';

      // ✅ Langsung download dan simpan otomatis
      final savedPath = await ApiService.downloadLaporanPdf(widget.orderId, namaFile);

      if (!mounted) return;

      // ✅ Tampilkan snackbar sukses + tombol BUKA
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PDF berhasil disimpan!',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    savedPath.split('/').last,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ]),
          backgroundColor: const Color(0xFF1A9E5C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          // ✅ Tombol BUKA via share sheet
          action: SnackBarAction(
            label: 'BUKA',
            textColor: Colors.yellow,
            onPressed: () async {
              await Share.shareXFiles(
                [XFile(savedPath, mimeType: 'application/pdf')],
                subject: namaFile,
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('$e', style: const TextStyle(fontSize: 12))),
          ]),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  // ─── helpers ─────────────────────────────────────────────────────────────────
  Color _kondisiColor(String? k) {
    switch ((k ?? '').toLowerCase()) {
      case 'normal':    return const Color(0xFF1A9E5C);
      case 'minus':     return const Color(0xFFE67E22);
      case 'rusak':     return Colors.red;
      case 'tidak ada': return AppColors.textGrey;
      default:          return AppColors.textGrey;
    }
  }

  String _kondisiLabel(String? k) {
    switch ((k ?? '').toLowerCase()) {
      case 'normal':    return 'Normal';
      case 'minus':     return 'Minus';
      case 'rusak':     return 'Rusak';
      case 'tidak ada': return 'Tidak Ada';
      default:          return k ?? '-';
    }
  }

  // ✅ REVISI 2: Widget foto dengan loading indicator
  Widget _photoPreview(
      String? url, {
        double width = double.infinity,
        double height = 180,
      }) {
    if (url == null || url.isEmpty) return _emptyPhotoBox(width, height);

    final isNetwork = url.startsWith('http');
    final isLocal   = url.startsWith('/');

    if (!isNetwork && !isLocal) return _emptyPhotoBox(width, height);

    return GestureDetector(
      onTap: () => _viewFull(url, isNetwork: isNetwork),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: isNetwork
            ? Image.network(
          url,
          width: width == double.infinity ? null : width,
          height: height,
          fit: BoxFit.cover,
          // ✅ REVISI 2: loading placeholder saat gambar belum muncul
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _loadingPhotoBox(width, height, loadingProgress);
          },
          errorBuilder: (_, __, ___) => _emptyPhotoBox(width, height),
        )
            : Image.file(
          File(url),
          width: width == double.infinity ? null : width,
          height: height,
          fit: BoxFit.cover,
          // ✅ REVISI 2: loading placeholder untuk file lokal
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return _shimmerBox(width, height);
          },
          errorBuilder: (_, __, ___) => _emptyPhotoBox(width, height),
        ),
      ),
    );
  }

  // ✅ REVISI 2: Loading box dengan progress indicator (untuk network)
  Widget _loadingPhotoBox(double width, double height, ImageChunkEvent progress) {
    final percent = progress.expectedTotalBytes != null
        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
        : null;

    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: percent,
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            if (percent != null) ...[
              const SizedBox(height: 6),
              Text(
                '${(percent * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ REVISI 2: Shimmer-like loading box untuk file lokal
  Widget _shimmerBox(double width, double height) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _emptyPhotoBox(double width, double height) => Container(
    width: width == double.infinity ? null : width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFFBBBBBB),
        size: 28,
      ),
    ),
  );

  void _viewFull(String src, {required bool isNetwork}) {
    final img = isNetwork
        ? Image.network(src, fit: BoxFit.contain)
        : Image.file(File(src), fit: BoxFit.contain);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          Center(child: InteractiveViewer(child: img)),
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
    child: Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
    ]),
  );

  Widget _infoRow(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 160,
        child: Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
      ),
      const Text(': ', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
      Expanded(
        child: Text(
          (value == null || value.isEmpty || value == '-') ? '-' : value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
      ),
    ]),
  );

  Widget _card({required List<Widget> children}) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _kondisiBadge(String? kondisi) {
    final color = _kondisiColor(kondisi);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _kondisiLabel(kondisi),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _emptyState(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F8F8),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFEEEEEE)),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textGrey),
      const SizedBox(width: 8),
      Text(msg, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
    ]),
  );

  // ─── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final namaMobil = header['nama_kendaraan']
        ?? widget.dataTugas['nama_mobil']
        ?? 'Ringkasan Inspeksi';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(namaMobil,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const Text('Ringkasan Inspeksi',
              style: TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: isDownloading
                ? const SizedBox(
              width: 36, height: 36,
              child: Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                ),
              ),
            )
                : Tooltip(
              message: 'Download PDF',
              child: InkWell(
                onTap: _downloadPdf,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text('PDF',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
          ? _buildError()
          : _buildBody(),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(errorMsg!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() { isLoading = true; errorMsg = null; });
            _loadDetail();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
          child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
        ),
      ]),
    ),
  );

  Widget _buildBody() => SingleChildScrollView(
    padding: const EdgeInsets.only(bottom: 40),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildHeaderCard(),
      _buildRingkasanCard(),
      _sectionHeader('Informasi & Dokumen', Icons.folder_open_rounded),
      _card(children: [
        _infoRow('Nomor Rangka',      informasiDokumen['nomor_rangka']),
        _infoRow('Nomor Mesin',       informasiDokumen['nomor_mesin']),
        _infoRow('Pajak 1 Tahun',     informasiDokumen['pajak_1_tahun']),
        _infoRow('Pajak 5 Tahun',     informasiDokumen['pajak_5_tahun']),
        _infoRow('PKB',               informasiDokumen['pkb']),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 20, color: Color(0xFFEEEEEE)),
        ),
        _infoRow('Nama Pemilik BPKB', informasiDokumen['nama_pemilik_bpkb']),
        _infoRow('Nomor BPKB',        informasiDokumen['nomor_bpkb']),
        _infoRow('Kepemilikan',       informasiDokumen['kepemilikan']),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 20, color: Color(0xFFEEEEEE)),
        ),
        _infoRow('Buku Service', informasiDokumen['buku_service']),
      ]),
      if (rincianFoto.isNotEmpty) ...[
        _sectionHeader('Rincian Inspeksi', Icons.camera_alt_rounded),
        ...rincianFoto.entries.map((e) => _buildKategoriSection(e.key, _safeList(e.value))),
      ] else ...[
        _sectionHeader('Rincian Inspeksi', Icons.camera_alt_rounded),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _emptyState('Belum ada data rincian inspeksi'),
        ),
      ],
    ]),
  );

  Widget _buildHeaderCard() {
    final namaKendaraan = header['nama_kendaraan'] ?? widget.dataTugas['nama_mobil'] ?? '-';
    final spesifikasi   = header['spesifikasi']      ?? '-';
    final inspektor     = header['inspektor']        ?? '-';
    final tanggal       = header['tanggal_inspeksi'] ?? widget.dataTugas['tanggal_waktu'] ?? '-';
    final status        = widget.dataTugas['status_inspeksi'] ?? 'selesai';
    final pelanggan     = widget.dataTugas['nama_pelanggan']  ?? '-';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(namaKendaraan,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: Colors.green.shade400, borderRadius: BorderRadius.circular(20)),
            child: Text(status,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(spesifikasi, style: const TextStyle(fontSize: 12, color: Colors.white60)),
        const SizedBox(height: 14),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 14),
        _whiteRow(Icons.person_outline_rounded, 'Pelanggan', pelanggan),
        const SizedBox(height: 8),
        _whiteRow(Icons.engineering_rounded, 'Inspektor', inspektor),
        const SizedBox(height: 8),
        _whiteRow(Icons.calendar_today_outlined, 'Tanggal', tanggal),
      ]),
    );
  }

  Widget _whiteRow(IconData icon, String label, String value) => Row(children: [
    Icon(icon, color: Colors.white54, size: 14),
    const SizedBox(width: 8),
    Text('$label  ', style: const TextStyle(color: Colors.white54, fontSize: 11)),
    Expanded(
      child: Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  ]);

  Widget _buildRingkasanCard() {
    final total       = (ringkasan['total_titik_inspeksi'] ?? 0) as num;
    final normal      = (ringkasan['titik_normal']         ?? 0) as num;
    final tidakNormal = (ringkasan['titik_tidak_normal']   ?? 0) as num;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ringkasan Inspeksi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 14),
        Row(children: [
          _statBox('Total Titik', total.toString(), AppColors.primary),
          const SizedBox(width: 10),
          _statBox('Normal', normal.toString(), const Color(0xFF1A9E5C)),
          const SizedBox(width: 10),
          _statBox('Tidak Normal', tidakNormal.toString(), Colors.red),
        ]),
        if (total > 0) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (normal / total).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.red.shade100,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF1A9E5C)),
            ),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${((normal / total) * 100).toStringAsFixed(0)}% kondisi normal',
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
            Text(
              '$tidakNormal masalah ditemukan',
              style: TextStyle(
                fontSize: 11,
                color: tidakNormal > 0 ? Colors.red : AppColors.textGrey,
                fontWeight: tidakNormal > 0 ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _statBox(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
      ]),
    ),
  );

  Widget _buildKategoriSection(String kategori, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(_iconForKategori(kategori), color: AppColors.primary, size: 15),
          ),
          const SizedBox(width: 8),
          Text(kategori,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${items.length} item',
                style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
      ...items.map((item) => _buildItemCard(_safeMap(item))),
    ]);
  }

  IconData _iconForKategori(String nama) {
    final n = nama.toLowerCase();
    if (n.contains('interior'))  return Icons.airline_seat_recline_extra_rounded;
    if (n.contains('eksterior')) return Icons.directions_car_filled_rounded;
    if (n.contains('mesin'))     return Icons.settings_rounded;
    if (n.contains('kaki'))      return Icons.car_repair_rounded;
    if (n.contains('dokumen'))   return Icons.folder_open_rounded;
    return Icons.checklist_rounded;
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final namaItem     = item['nama_item']?.toString()      ?? '-';
    final kondisi      = item['status_kondisi']?.toString() ?? 'normal';
    final catatan      = item['catatan']?.toString()        ?? '';

    final List<String> fotoUtamaList = _parseFotoList(item['foto']);
    final List<String> fotoTambahan = _parseFotoList(item['foto_tambahan']);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header nama + badge kondisi
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Expanded(
              child: Text(namaItem,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ),
            const SizedBox(width: 8),
            _kondisiBadge(kondisi),
          ]),
        ),

        // ✅ REVISI 3: tampilkan semua foto utama (multi)
        if (fotoUtamaList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fotoUtamaList.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Foto Kondisi (${fotoUtamaList.length})',
                      style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                    ),
                  ),
                if (fotoUtamaList.length == 1)
                // Satu foto: tampil full width
                  _photoPreview(fotoUtamaList.first, height: 160)
                else
                // Multi foto: grid wrap
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fotoUtamaList
                        .map((url) => _photoPreview(url, width: 100, height: 100))
                        .toList(),
                  ),
              ],
            ),
          ),

        // Foto kerusakan (multi, sudah ada sebelumnya)
        if (fotoTambahan.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Foto Kerusakan (${fotoTambahan.length})',
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: fotoTambahan
                    .map((f) => _photoPreview(f?.toString(), width: 80, height: 80))
                    .toList(),
              ),
            ]),
          ),

        // Catatan
        if (catatan.isNotEmpty && catatan != 'null')
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.notes_rounded, size: 13, color: Color(0xFFE67E22)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(catatan,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7D5A00))),
                ),
              ]),
            ),
          )
        else
          const SizedBox(height: 4),
      ]),
    );
  }

  // ✅ Helper: parse foto list dari berbagai format (array URL atau string tunggal)
  List<String> _parseFotoList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.isNotEmpty) return [raw];
    return [];
  }
}