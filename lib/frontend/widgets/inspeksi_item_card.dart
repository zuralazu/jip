import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/image_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class InspeksiItemCard extends StatefulWidget {
  final String namaItem;
  final Map<String, dynamic>? formData;
  final String? fieldKey;
  final Function(dynamic)? onChanged;
  final String section;

  const InspeksiItemCard({
    super.key,
    required this.namaItem,
    this.formData,
    this.fieldKey,
    this.onChanged,
    required this.section,
  });

  @override
  State<InspeksiItemCard> createState() => _InspeksiItemCardState();
}

class _InspeksiItemCardState extends State<InspeksiItemCard> {
  List<File> fotoUtama = [];
  TextEditingController catatanController = TextEditingController();
  String statusKondisi = 'Normal';
  bool showKerusakan = false;
  List<File> fotoKerusakan = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> kondisiOptions = ['Normal', 'Rusak', 'Perlu Perbaikan'];

  Color get _kondisiColor {
    switch (statusKondisi) {
      case 'Normal':          return const Color(0xFF1A9E5C);
      case 'Rusak':           return Colors.red;
      case 'Perlu Perbaikan': return const Color(0xFFE67E22);
      default:                return AppColors.textGrey;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFromFormData();

    // ✅ FIX Masalah 2: Kalau item ini belum punya data sama sekali di formData,
    // simpan default "Normal" supaya validasi tidak anggap kondisi kosong
    if (itemData.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _saveDefault();
      });
    }
  }

  // ✅ FIX Masalah 1: Load data dipisah ke method sendiri
  void _loadFromFormData() {
    final data = itemData;

    // Ambil status_kondisi, default "Normal" kalau kosong
    final rawKondisi = data["status_kondisi"]?.toString() ?? '';
    statusKondisi = rawKondisi.isNotEmpty ? rawKondisi : 'Normal';

    showKerusakan = data["showKerusakan"] == true;
    catatanController.text = data["catatan"]?.toString() ?? '';
    fotoUtama = _getFotoUtamaList();
    fotoKerusakan = _getKerusakanImages();
  }

  // ✅ FIX Masalah 2: Simpan default tanpa menunggu user klik kondisi
  void _saveDefault() {
    widget.onChanged?.call({
      "status_kondisi": "Normal",
      "showKerusakan": false,
      "catatan": "",
      "foto_utama": <String>[],
      "foto": null,
      "foto_kerusakan": <String>[],
    });
  }

  // ✅ FIX Masalah 1: didUpdateWidget dipanggil saat parent rebuild
  // Ini yang terjadi saat pindah section lalu balik — widget di-rebuild
  // dengan formData baru, tapi state lama (fotoUtama) tidak ikut update
  @override
  void didUpdateWidget(covariant InspeksiItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Cek apakah data untuk item ini berubah dari luar
    final newData = itemData;
    final newFotoUtama = newData["foto_utama"];

    // Hitung jumlah foto dari formData terbaru
    int countFromFormData = 0;
    if (newFotoUtama is List) {
      countFromFormData = newFotoUtama
          .where((e) => e != null && e.toString().isNotEmpty)
          .length;
    }

    // Kalau jumlah foto di formData berbeda dengan state lokal, reload
    if (countFromFormData != fotoUtama.length) {
      setState(() => _loadFromFormData());
    }

    // Reload juga kalau kondisi berubah dari luar
    final newKondisi = newData["status_kondisi"]?.toString() ?? 'Normal';
    if (newKondisi != statusKondisi && newKondisi.isNotEmpty) {
      setState(() => statusKondisi = newKondisi);
    }
  }

  @override
  void dispose() {
    catatanController.dispose();
    super.dispose();
  }

  // ── DATA HELPERS ─────────────────────────────────────────────────────────────

  Map<String, dynamic> get itemData {
    if (widget.formData == null || widget.fieldKey == null) return {};
    final raw = widget.formData![widget.fieldKey!];
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  List<File> _getFotoUtamaList() {
    final data = itemData;

    // Format baru: list of paths
    final fotoList = data["foto_utama"];
    if (fotoList is List && fotoList.isNotEmpty) {
      return fotoList
          .map((e) => e?.toString() ?? '')
          .where((p) => p.isNotEmpty)
          .map((p) => File(p))
          .where((f) => f.existsSync())
          .toList();
    }

    // Fallback format lama: single string
    final foto = data["foto"];
    if (foto != null && foto.toString().isNotEmpty) {
      final f = File(foto.toString());
      if (f.existsSync()) return [f];
    }

    return [];
  }

  List<File> _getKerusakanImages() {
    final list = itemData["foto_kerusakan"];
    if (list == null || list is! List) return [];
    return list
        .map((e) => e?.toString() ?? '')
        .where((p) => p.isNotEmpty)
        .map((p) => File(p))
        .where((f) => f.existsSync())
        .toList();
  }

  void saveAll() {
    final data = {
      "status_kondisi": statusKondisi,
      "showKerusakan": showKerusakan,
      "catatan": catatanController.text,
      "foto_utama": fotoUtama.map((e) => e.path).toList(),
      "foto": fotoUtama.isNotEmpty ? fotoUtama.first.path : null,
      "foto_kerusakan": fotoKerusakan.map((e) => e.path).toList(),
    };
    widget.onChanged?.call(data);
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── HEADER: nama + dropdown kondisi ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.namaItem,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showKondisiPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kondisiColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kondisiColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusKondisi,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kondisiColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: _kondisiColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── MULTI FOTO UTAMA ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto Kondisi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...fotoUtama.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final file = entry.value;
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              file,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => fotoUtama.removeAt(idx));
                                saveAll();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    // Tombol tambah foto
                    GestureDetector(
                      onTap: () => _pickFotoUtama(context),
                      child: Container(
                        width: 600,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_rounded,
                              color: AppColors.primary.withOpacity(0.7),
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fotoUtama.isEmpty ? 'Tambah\nFoto' : 'Tambah\nLagi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── TOMBOL ADA KERUSAKAN ──
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      'Ada Kerusakan lainnya?',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => showKerusakan = !showKerusakan);
                    saveAll();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      showKerusakan ? 'Tutup' : 'Tambahkan',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── FOTO KERUSAKAN ──
          if (showKerusakan)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Foto Kerusakan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...fotoKerusakan.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final file = entry.value;
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                file,
                                width: 600,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => fotoKerusakan.removeAt(idx));
                                  saveAll();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),

                      GestureDetector(
                        onTap: () => _pickFotoKerusakan(context),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded,
                                  color: Colors.red.withOpacity(0.6), size: 18),
                              const SizedBox(height: 4),
                              Text(
                                'Tambah',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ── CATATAN ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: TextField(
              controller: catatanController,
              onChanged: (_) => saveAll(),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Catatan (Opsional)',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PICKER FOTO UTAMA ────────────────────────────────────────────────────────
  void _pickFotoUtama(BuildContext context) {
    _showImagePickerSheet(
      context,
      onCamera: () async {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        if (image != null) {
          final compressed = await ImageUtils.compressImage(
            File(image.path),
            quality: 70,
            maxWidth: 1280,
            maxHeight: 1280,
          );
          setState(() => fotoUtama.add(compressed));
          saveAll();
        }
      },
      onGallery: () async {
        final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
        if (images.isNotEmpty) {
          for (final img in images) {
            final compressed = await ImageUtils.compressImage(
              File(img.path),
              quality: 70,
              maxWidth: 1280,
              maxHeight: 1280,
            );
            fotoUtama.add(compressed);
          }
          setState(() {});
          saveAll();
        }
      },
    );
  }

  // ── PICKER FOTO KERUSAKAN ────────────────────────────────────────────────────
  void _pickFotoKerusakan(BuildContext context) {
    _showImagePickerSheet(
      context,
      onCamera: () async {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        if (image != null) {
          final compressed = await ImageUtils.compressImage(
            File(image.path),
            quality: 70,
            maxWidth: 1280,
            maxHeight: 1280,
          );
          setState(() => fotoKerusakan.add(compressed));
          saveAll();
        }
      },
      onGallery: () async {
        final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
        if (images.isNotEmpty) {
          for (final img in images) {
            final compressed = await ImageUtils.compressImage(
              File(img.path),
              quality: 70,
              maxWidth: 1280,
              maxHeight: 1280,
            );
            fotoKerusakan.add(compressed);
          }
          setState(() {});
          saveAll();
        }
      },
    );
  }

  void _showImagePickerSheet(
      BuildContext context, {
        required Future<void> Function() onCamera,
        required Future<void> Function() onGallery,
      }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Ambil dari Kamera'),
              onTap: () { Navigator.pop(context); onCamera(); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pilih dari Galeri (bisa banyak)'),
              onTap: () { Navigator.pop(context); onGallery(); },
            ),
          ],
        ),
      ),
    );
  }

  // ── KONDISI PICKER ───────────────────────────────────────────────────────────
  void _showKondisiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Kondisi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ...kondisiOptions.map((opt) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                statusKondisi == opt
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: statusKondisi == opt ? AppColors.primary : AppColors.textGrey,
                size: 20,
              ),
              title: Text(
                opt,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: statusKondisi == opt ? FontWeight.w600 : FontWeight.w400,
                  color: statusKondisi == opt ? AppColors.primary : AppColors.textDark,
                ),
              ),
              onTap: () {
                setState(() => statusKondisi = opt);
                saveAll();
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}