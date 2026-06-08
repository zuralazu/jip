// inspeksi_item_card.dart — FULL REPLACE

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import '../../main.dart';
import '../utils/colors.dart';
import '../utils/image_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart'; // tambah ke pubspec: camera: ^0.10.5+9
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
  List<dynamic> fotoUtama = [];
  late TextEditingController catatanController;
  String statusKondisi = 'Normal';
  bool showKerusakan = false;
  List<File> fotoKerusakan = [];
  final ImagePicker _picker = ImagePicker();

  // ── Anti scroll-jump: kalau user lagi fokus di field, skip rebuild ──
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  // ── Track apakah sudah di-init supaya didUpdateWidget tidak override ──
  bool _initialized = false;

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
    catatanController = TextEditingController();
    _focusNode.addListener(() => _isFocused = _focusNode.hasFocus);
    _loadFromFormData();
    _initialized = true;

    if (itemData.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _saveDefault();
      });
    }
  }

  void _loadFromFormData() {
    final data = itemData;
    final rawKondisi = data["status_kondisi"]?.toString() ?? '';
    statusKondisi = rawKondisi.isNotEmpty ? rawKondisi : 'Normal';
    showKerusakan = data["showKerusakan"] == true;

    // Jangan override catatan kalau user lagi ngetik
    if (!_isFocused) {
      catatanController.text = data["catatan"]?.toString() ?? '';
    }

    fotoUtama = _getFotoUtamaList();
    fotoKerusakan = _getKerusakanImages();
  }

  void _saveDefault() {
    widget.onChanged?.call({
      "status_kondisi": "Normal",
      "showKerusakan": false,
      "catatan": "",
      "foto_utama": <String>[],
      "foto": null,
      "foto_tambahan": <String>[],
    });
  }

  @override
  void didUpdateWidget(covariant InspeksiItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isFocused) return;

    final newData = itemData;

    // ── Guard foto utama (sudah ada) ──
    final newFotoUtama = newData["foto_utama"];
    final serverUrls = <String>[];
    if (newFotoUtama is List) {
      for (final e in newFotoUtama) {
        final s = e?.toString() ?? '';
        if (s.startsWith('http')) serverUrls.add(s);
      }
    }
    final currentUrls = fotoUtama.whereType<String>().toList();
    final urlsChanged = serverUrls.length != currentUrls.length ||
        !serverUrls.every((u) => currentUrls.contains(u));

    final newKondisi = newData["status_kondisi"]?.toString() ?? 'Normal';
    final kondisiChanged = newKondisi.isNotEmpty && newKondisi != statusKondisi;

    if (kondisiChanged) {
      setState(() => statusKondisi = newKondisi);
    }

    if (urlsChanged && serverUrls.isNotEmpty) {
      setState(() {
        final localFiles = fotoUtama.whereType<File>().toList();
        fotoUtama = [...serverUrls, ...localFiles];
      });
    }

    // ── TAMBAH: Guard foto kerusakan ──
    // Hanya update dari formData kalau state lokal kosong
    // Jangan override kalau user sudah tambah foto di sesi ini
    if (fotoKerusakan.isEmpty) {
      final newKerusakan = _getKerusakanImages();
      if (newKerusakan.isNotEmpty) {
        setState(() => fotoKerusakan = newKerusakan);
      }
    }
  }

  @override
  void dispose() {
    catatanController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── DATA HELPERS ─────────────────────────────────────────────────────────

  Map<String, dynamic> get itemData {
    if (widget.formData == null || widget.fieldKey == null) return {};
    final raw = widget.formData![widget.fieldKey!];
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  List<dynamic> _getFotoUtamaList() {
    final data = itemData;
    final fotoList = data["foto_utama"];
    final result = <dynamic>[];

    if (fotoList is List) {
      for (final e in fotoList) {
        final path = e?.toString() ?? '';
        if (path.isEmpty) continue;
        if (path.startsWith('http')) {
          result.add(path);
        } else {
          final f = File(path);
          if (f.existsSync()) result.add(f);
        }
      }
    }

    final savedUrls = data["foto_utama_urls"];
    if (result.isEmpty && savedUrls is List) {
      for (final url in savedUrls) {
        if (url != null && url.toString().isNotEmpty) {
          result.add(url.toString());
        }
      }
    }

    if (result.isEmpty) {
      final foto = data["foto"]?.toString() ?? '';
      if (foto.isNotEmpty) {
        if (foto.startsWith('http')) {
          result.add(foto);
        } else {
          final f = File(foto);
          if (f.existsSync()) result.add(f);
        }
      }
    }

    return result;
  }

  List<File> _getKerusakanImages() {
    final list = itemData["foto_tambahan"];
    debugPrint('GET_KERUSAKAN: raw=$list');
    if (list == null || list is! List) return [];
    return list
        .map((e) => e?.toString() ?? '')
        .where((p) => p.isNotEmpty)
        .map((p) => File(p))
        .where((f) => f.existsSync())
        .toList();
  }

  void saveAll() {
    debugPrint('SAVEALL: fotoKerusakan=${fotoKerusakan.length} paths=${fotoKerusakan.map((e) => e.path).toList()}');
    widget.onChanged?.call({
      "status_kondisi": statusKondisi,
      "showKerusakan": showKerusakan,
      "catatan": catatanController.text,
      "foto_utama": fotoUtama.whereType<File>().map((e) => e.path).toList(),
      "foto": fotoUtama.whereType<File>().isNotEmpty
          ? fotoUtama.whereType<File>().first.path
          : null,
      "foto_tambahan": fotoKerusakan.map((e) => e.path).toList(),
      "foto_utama_urls": fotoUtama.whereType<String>().toList(),
    });
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

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

          // ── HEADER ──
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
                        Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _kondisiColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── FOTO UTAMA (Opsional) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Foto Kondisi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Opsional',
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...fotoUtama.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: item is File
                                ? Image.file(item, width: 80, height: 80, fit: BoxFit.cover)
                                : Image.network(item.toString(), width: 80, height: 80, fit: BoxFit.cover),
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
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),

                    // Tombol tambah foto — dengan flash support
                    GestureDetector(
                      onTap: () => _pickFotoUtama(context),
                      child: Container(
                        width: 80,
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey),
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
                              child: Image.file(file, width: 90, height: 90, fit: BoxFit.cover),
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
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.4), width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, color: Colors.red.withOpacity(0.6), size: 18),
                              const SizedBox(height: 4),
                              Text(
                                'Tambah',
                                style: TextStyle(fontSize: 9, color: Colors.red.withOpacity(0.7), fontWeight: FontWeight.w500),
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

          // ── CATATAN — pakai FocusNode supaya tidak trigger rebuild ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: TextField(
              controller: catatanController,
              focusNode: _focusNode,
              // ← onChanged hanya simpan data, TIDAK setState
              onChanged: (_) => saveAll(),

              onTap: () {
                // Hanya fokus kalau user memang tap textfield ini
                _focusNode.requestFocus();
              },


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

  // ── PICKER DENGAN FLASH ───────────────────────────────────────────────────

  void _pickFotoUtama(BuildContext context) {
    // ← unfocus dulu sebelum buka sheet
    FocusScope.of(context).unfocus();

    _showImagePickerSheet(
      context,
      onCamera: () async {
        final file = await Navigator.of(context).push<File>(
          MaterialPageRoute(builder: (_) => const _CameraWithFlash()),
        );
        if (file != null) {
          final compressed = await ImageUtils.compressImage(
            file, quality: 70, maxWidth: 1280, maxHeight: 1280,
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
              File(img.path), quality: 70, maxWidth: 1280, maxHeight: 1280,
            );
            fotoUtama.add(compressed);
          }
          setState(() {});
          saveAll();
        }
      },
    );
  }

  void _pickFotoKerusakan(BuildContext context) {
    // ← unfocus dulu sebelum buka sheet
    FocusScope.of(context).unfocus();

    _showImagePickerSheet(
      context,
      onCamera: () async {
        final file = await Navigator.of(context).push<File>(
          MaterialPageRoute(builder: (_) => const _CameraWithFlash()),
        );
        if (file != null) {
          final compressed = await ImageUtils.compressImage(
            file, quality: 70, maxWidth: 1280, maxHeight: 1280,
          );
          debugPrint('AFTER COMPRESS: fotoKerusakan=${fotoKerusakan.length}');
          setState(() => fotoKerusakan.add(compressed));
          saveAll();
          debugPrint('AFTER SETSTATE: fotoKerusakan=${fotoKerusakan.length}');
        }
      },
      onGallery: () async {
        final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
        if (images.isNotEmpty) {
          for (final img in images) {
            final compressed = await ImageUtils.compressImage(
              File(img.path), quality: 70, maxWidth: 1280, maxHeight: 1280,
            );
            fotoKerusakan.add(compressed);
          }
          debugPrint('AFTER PICK: fotoKerusakan=${fotoKerusakan.length}');
          setState(() {});
          saveAll();
          debugPrint('AFTER SAVEALL: fotoKerusakan=${fotoKerusakan.length}');
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16, top: 8),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const Text('Tambah Foto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SheetOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Kamera',
                      sublabel: 'Dengan flash',
                      color: AppColors.primary,
                      onTap: () { Navigator.pop(context); onCamera(); },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Galeri',
                      sublabel: 'Pilih banyak',
                      color: const Color(0xFF8E24AA),
                      onTap: () { Navigator.pop(context); onGallery(); },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── KONDISI PICKER ───────────────────────────────────────────────────────

  void _showKondisiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Pilih Kondisi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 12),
            ...kondisiOptions.map((opt) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                statusKondisi == opt ? Icons.radio_button_checked : Icons.radio_button_off,
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

// ── Helper widget opsi sheet ─────────────────────────────────────────────────
class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({required this.icon, required this.label, required this.sublabel, required this.color, required this.onTap});

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
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(sublabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

// ── Kamera custom dengan flash toggle ────────────────────────────────────────
class _CameraWithFlash extends StatefulWidget {
  const _CameraWithFlash();

  @override
  State<_CameraWithFlash> createState() => _CameraWithFlashState();
}

class _CameraWithFlashState extends State<_CameraWithFlash> {
  CameraController? _controller;
  bool _isReady = false;
  FlashMode _flashMode = FlashMode.auto;
  bool _isTakingPhoto = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (globalCameras.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // ← debug dulu
    for (int i = 0; i < globalCameras.length; i++) {
      debugPrint('CAMERA $i: ${globalCameras[i].name} — ${globalCameras[i].lensDirection}');
    }

    // Pastikan ambil kamera BELAKANG
    final backCamera = globalCameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => globalCameras.first,
    );

    _controller = CameraController(
      backCamera,  // ← eksplisit pilih belakang
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off); // ← default OFF, bukan auto
      setState(() {
        _flashMode = FlashMode.off;
        _isReady = true;
      });
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _cycleFlash() async {
    final modes = [FlashMode.auto, FlashMode.always, FlashMode.off, FlashMode.torch];
    final next = modes[(modes.indexOf(_flashMode) + 1) % modes.length];
    await _controller?.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.auto:   return Icons.flash_auto_rounded;
      case FlashMode.always: return Icons.flash_on_rounded;
      case FlashMode.off:    return Icons.flash_off_rounded;
      case FlashMode.torch:  return Icons.flashlight_on_rounded;
      default:               return Icons.flash_auto_rounded;
    }
  }

  String get _flashLabel {
    switch (_flashMode) {
      case FlashMode.auto:   return 'Auto';
      case FlashMode.always: return 'On';
      case FlashMode.off:    return 'Off';
      case FlashMode.torch:  return 'Torch';
      default:               return 'Auto';
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_isReady || _isTakingPhoto) return;
    setState(() => _isTakingPhoto = true);

    try {
      final XFile photo = await _controller!.takePicture();

      // ← simpan ke galeri
      try {
        await Gal.putImage(photo.path, album: 'JIM');
      } catch (e) {
        debugPrint('Gagal simpan ke galeri: $e');
      }

      if (mounted) Navigator.pop(context, File(photo.path));
    } catch (e) {
      debugPrint('Gagal ambil foto: $e');
      setState(() => _isTakingPhoto = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isReady
          ? Stack(
        fit: StackFit.expand,
        children: [
          // Preview
          CameraPreview(_controller!),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8, right: 8, bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  // Flash toggle
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_flashIcon, color: _flashMode == FlashMode.off ? Colors.white : Colors.black, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _flashLabel,
                            style: TextStyle(
                              color: _flashMode == FlashMode.off ? Colors.white : Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          // Bottom shutter
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                top: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
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
                      shape: BoxShape.circle,
                      color: Colors.white,
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
        ],
      )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}