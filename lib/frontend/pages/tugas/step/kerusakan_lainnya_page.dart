import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../../../../main.dart';
import '/main.dart';
import '../../../services/api_service.dart';
import '../../../config/app_config.dart';
import '../../../utils/colors.dart';
import '../../../utils/image_utils.dart';

class KerusakanLainnyaPage extends StatefulWidget {
  final int orderId;
  final bool isDone;

  const KerusakanLainnyaPage({
    super.key,
    required this.orderId,
    required this.isDone,
  });

  @override
  State<KerusakanLainnyaPage> createState() => _KerusakanLainnyaPageState();
}

class _KerusakanLainnyaPageState extends State<KerusakanLainnyaPage> {
  @override
  // bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiService.getKerusakanLainnya(widget.orderId);
      if (!mounted) return;
      final list = res['data']?['data'] ?? res['data'] ?? [];
      setState(() {
        _items = List<Map<String, dynamic>>.from(
          (list as List).map((e) => Map<String, dynamic>.from(e)),
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR load kerusakan lainnya: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── TAMBAH ──────────────────────────────────────────────────────────────

  void _showTambahSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KerusakanFormSheet(
        orderId: widget.orderId,
        onSaved: (item) {
          setState(() => _items.add(item));
        },
      ),
    );
  }

  // ─── EDIT ────────────────────────────────────────────────────────────────

  void _showEditSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KerusakanFormSheet(
        orderId: widget.orderId,
        existing: item,
        onSaved: (updated) {
          setState(() {
            final idx = _items.indexWhere((e) => e['id'] == item['id']);
            if (idx != -1) _items[idx] = updated;
          });
        },
      ),
    );
  }

  // ─── HAPUS ───────────────────────────────────────────────────────────────

  Future<void> _hapus(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.delete_outline_rounded, size: 28, color: Colors.red.shade500),
            ),
            const SizedBox(height: 16),
            const Text('Hapus Section Ini?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Section "${item['nama_kerusakan']}" akan dihapus permanen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Hapus',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteKerusakanLainnya(widget.orderId, item['id']);
      setState(() => _items.removeWhere((e) => e['id'] == item['id']));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Section berhasil dihapus'),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      debugPrint('ERROR hapus kerusakan: $e');
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // super.build(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        _items.isEmpty ? _buildEmptyState() : _buildList(),
        if (!widget.isDone)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _showTambahSheet,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Tambah Kerusakan',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_box_outlined, size: 40, color: AppColors.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum Ada Section Tambahan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan section kerusakan lainnya yang tidak ada di 7 kategori utama.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
          ),
          const SizedBox(height: 80), // ruang buat FAB
        ]),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _items.length,
      itemBuilder: (_, i) => _KerusakanCard(
        item: _items[i],
        isDone: widget.isDone,
        onEdit: () => _showEditSheet(_items[i]),
        onDelete: () => _hapus(_items[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD
// ─────────────────────────────────────────────────────────────────────────────

class _KerusakanCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _KerusakanCard({
    required this.item,
    required this.isDone,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _tingkatColor {
    switch (item['tingkat_kerusakan']) {
      case 'berat':  return Colors.red.shade600;
      case 'sedang': return Colors.orange.shade600;
      default:       return Colors.green.shade600;
    }
  }

  String get _tingkatLabel {
    switch (item['tingkat_kerusakan']) {
      case 'berat':  return 'Berat';
      case 'sedang': return 'Sedang';
      default:       return 'Ringan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fotos = _parseFotos(item['foto']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _tingkatColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber_rounded, color: _tingkatColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  item['nama_kerusakan'] ?? '-',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _tingkatColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _tingkatLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _tingkatColor),
                  ),
                ),
              ]),
            ),
            if (!isDone) ...[
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade500),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ]),
        ),

        // ── Deskripsi ──
        if (item['deskripsi'] != null && item['deskripsi'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              item['deskripsi'],
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
            ),
          ),

        // ── Foto grid ──
        if (fotos.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Foto (${fotos.length})',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: fotos.map((url) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: 80, height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
                    ),
                  ),
                )).toList(),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  List<String> _parseFotos(dynamic raw) {
    if (raw == null) return [];
    List<String> paths = [];
    if (raw is List) {
      paths = raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    } else if (raw is String && raw.isNotEmpty) {
      paths = [raw];
    }
    // Foto dari backend path relatif (/Photo/...), prefix dengan base URL server
    return paths.map((p) {
      if (p.startsWith('http')) return p;
      final base = AppConfig.baseUrl.replaceAll('/api', '');
      return '$base$p';
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORM BOTTOM SHEET (Tambah / Edit)
// ─────────────────────────────────────────────────────────────────────────────

class _KerusakanFormSheet extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic>? existing;
  final Function(Map<String, dynamic>) onSaved;

  const _KerusakanFormSheet({
    required this.orderId,
    this.existing,
    required this.onSaved,
  });

  @override
  State<_KerusakanFormSheet> createState() => _KerusakanFormSheetState();
}

class _KerusakanFormSheetState extends State<_KerusakanFormSheet> {
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  String _tingkat = 'ringan';
  List<File> _newFotos = [];          // foto baru dari device
  List<String> _existingFotoUrls = []; // foto lama dari server (edit mode)
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.existing!;
      _namaController.text = e['nama_kerusakan'] ?? '';
      _deskripsiController.text = e['deskripsi'] ?? '';
      _tingkat = e['tingkat_kerusakan'] ?? 'ringan';
      _existingFotoUrls = _parseFotos(e['foto']);
    }
  }

  List<String> _parseFotos(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    if (raw is String && raw.isNotEmpty) return [raw];
    return [];
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  // ─── PICK FOTO ───────────────────────────────────────────────────────────

  void _pickFoto() {
    final totalFoto = _existingFotoUrls.length + _newFotos.length;
    if (totalFoto >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Maksimal 5 foto'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16, top: 8),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const Text('Tambah Foto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _PickerOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Kamera',
                  sublabel: 'Dengan flash',
                  color: AppColors.primary,
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await Navigator.of(context).push<File>(
                      MaterialPageRoute(builder: (_) => const _CameraSheet()),
                    );
                    if (file != null) {
                      final compressed = await ImageUtils.compressImage(
                        file, quality: 70, maxWidth: 1280, maxHeight: 1280,
                      );
                      setState(() => _newFotos.add(compressed));
                    }
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: _PickerOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Galeri',
                  sublabel: 'Pilih banyak',
                  color: const Color(0xFF8E24AA),
                  onTap: () async {
                    Navigator.pop(context);
                    final remaining = 5 - _existingFotoUrls.length - _newFotos.length;
                    final images = await _picker.pickMultiImage(imageQuality: 80, limit: remaining);
                    for (final img in images) {
                      final compressed = await ImageUtils.compressImage(
                        File(img.path), quality: 70, maxWidth: 1280, maxHeight: 1280,
                      );
                      _newFotos.add(compressed);
                    }
                    setState(() {});
                  },
                )),
              ]),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── SAVE ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Nama section wajib diisi'),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> res;

      if (_isEdit) {
        res = await ApiService.updateKerusakanLainnya(
          orderId: widget.orderId,
          id: widget.existing!['id'],
          namaKerusakan: _namaController.text.trim(),
          deskripsi: _deskripsiController.text.trim(),
          tingkatKerusakan: _tingkat,
          fotos: _newFotos,
        );
      } else {
        res = await ApiService.storeKerusakanLainnya(
          orderId: widget.orderId,
          namaKerusakan: _namaController.text.trim(),
          deskripsi: _deskripsiController.text.trim(),
          tingkatKerusakan: _tingkat,
          fotos: _newFotos,
        );
      }

      final saved = Map<String, dynamic>.from(res['data']?['data'] ?? res['data'] ?? {});
      if (mounted) {
        widget.onSaved(saved);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('ERROR save kerusakan: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_box_outlined, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              _isEdit ? 'Edit Section' : 'Tambah Section Baru',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
          ]),
          const SizedBox(height: 20),

          // Nama Kerusakan
          _label('Nama Section / Kerusakan', required: true),
          const SizedBox(height: 6),
          TextField(
            controller: _namaController,
            style: const TextStyle(fontSize: 14),
            decoration: _inputDecoration('Contoh: Kaca Film, Audio, dsb.'),
          ),
          const SizedBox(height: 16),

          // Tingkat Kerusakan
          _label('Tingkat Kerusakan'),
          const SizedBox(height: 8),
          Row(children: ['ringan', 'sedang', 'berat'].map((t) {
            final colors = {
              'ringan': Colors.green.shade600,
              'sedang': Colors.orange.shade600,
              'berat':  Colors.red.shade600,
            };
            final labels = {
              'ringan': 'Ringan',
              'sedang': 'Sedang',
              'berat':  'Berat',
            };
            final isSelected = _tingkat == t;
            final color = colors[t]!;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tingkat = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: t != 'berat' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 16,
                      color: isSelected ? color : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[t]!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? color : Colors.grey.shade500,
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 16),

          // Deskripsi
          _label('Deskripsi'),
          const SizedBox(height: 6),
          TextField(
            controller: _deskripsiController,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: _inputDecoration('Jelaskan kerusakan secara singkat (opsional)'),
          ),
          const SizedBox(height: 16),

          // Foto
          Row(children: [
            _label('Foto'),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Maks. 5',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              // Foto lama (edit mode)
              ..._existingFotoUrls.asMap().entries.map((entry) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      entry.value, width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80, height: 80,
                        color: Colors.grey.shade100,
                        child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _existingFotoUrls.removeAt(entry.key)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )),
              // Foto baru
              ..._newFotos.asMap().entries.map((entry) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(entry.value, width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _newFotos.removeAt(entry.key)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )),
              // Tombol tambah
              if (_existingFotoUrls.length + _newFotos.length < 5)
                GestureDetector(
                  onTap: _pickFoto,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_a_photo_rounded, color: AppColors.primary.withOpacity(0.7), size: 22),
                      const SizedBox(height: 4),
                      Text('Tambah', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: AppColors.primary.withOpacity(0.7), fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Tombol Simpan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : Text(
                _isEdit ? 'Simpan Perubahan' : 'Tambah Section',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      if (required) ...[
        const SizedBox(width: 4),
        Text('*', style: TextStyle(color: Colors.red.shade500, fontWeight: FontWeight.w700)),
      ],
    ]);
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAMERA SHEET (reuse pattern dari inspeksi_item_card.dart)
// ─────────────────────────────────────────────────────────────────────────────

class _CameraSheet extends StatefulWidget {
  const _CameraSheet();

  @override
  State<_CameraSheet> createState() => _CameraSheetState();
}

class _CameraSheetState extends State<_CameraSheet> {
  CameraController? _controller;
  bool _isReady = false;
  FlashMode _flashMode = FlashMode.off;
  bool _isTakingPhoto = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (globalCameras.isEmpty) { if (mounted) Navigator.pop(context); return; }

    final backCamera = globalCameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => globalCameras.first,
    );

    _controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _cycleFlash() async {
    final modes = [FlashMode.off, FlashMode.auto, FlashMode.always, FlashMode.torch];
    final next = modes[(modes.indexOf(_flashMode) + 1) % modes.length];
    await _controller?.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.auto:   return Icons.flash_auto_rounded;
      case FlashMode.always: return Icons.flash_on_rounded;
      case FlashMode.torch:  return Icons.flashlight_on_rounded;
      default:               return Icons.flash_off_rounded;
    }
  }

  String get _flashLabel {
    switch (_flashMode) {
      case FlashMode.auto:   return 'Auto';
      case FlashMode.always: return 'On';
      case FlashMode.torch:  return 'Torch';
      default:               return 'Off';
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_isReady || _isTakingPhoto) return;
    setState(() => _isTakingPhoto = true);
    try {
      final photo = await _controller!.takePicture();
      if (mounted) Navigator.pop(context, File(photo.path));
    } catch (e) {
      setState(() => _isTakingPhoto = false);
    }
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isReady
          ? Stack(fit: StackFit.expand, children: [
        CameraPreview(_controller!),
        // Top bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 8, right: 8, bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _cycleFlash,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _flashMode == FlashMode.off
                        ? Colors.white.withOpacity(0.15)
                        : Colors.amber.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_flashIcon,
                        color: _flashMode == FlashMode.off ? Colors.white : Colors.black, size: 18),
                    const SizedBox(width: 6),
                    Text(_flashLabel,
                        style: TextStyle(
                          color: _flashMode == FlashMode.off ? Colors.white : Colors.black,
                          fontSize: 13, fontWeight: FontWeight.w600,
                        )),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
            ]),
          ),
        ),
        // Shutter
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24, top: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
            child: Center(
              child: GestureDetector(
                onTap: _takePhoto,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: _isTakingPhoto ? 64 : 72,
                  height: _isTakingPhoto ? 64 : 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                  ),
                  child: _isTakingPhoto
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : null,
                ),
              ),
            ),
          ),
        ),
      ])
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PICKER OPTION WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon, required this.label, required this.sublabel,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(sublabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ]),
      ),
    );
  }
}