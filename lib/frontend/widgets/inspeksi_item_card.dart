import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'foto_upload_box.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';

class InspeksiItemCard extends StatefulWidget {
  final String namaItem;

  final Map<String, dynamic>? formData;
  final String? fieldKey;
  final Function(dynamic)? onChanged;
  final String section;

  const InspeksiItemCard({super.key, required this.namaItem,this.formData, this.fieldKey, this.onChanged, required this.section,});

  @override
  State<InspeksiItemCard> createState() => _InspeksiItemCardState();
}

class _InspeksiItemCardState extends State<InspeksiItemCard> {
  File? fotoUtama;

  TextEditingController catatanController = TextEditingController();

  String kondisi = 'Normal';
  bool showKerusakan = false;

  List<File> fotoKerusakan = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> kondisiOptions = ['Normal', 'Minus', 'Rusak', 'Tidak Ada'];

  Color get _kondisiColor {
    switch (kondisi) {
      case 'Normal':   return const Color(0xFF1A9E5C);
      case 'Minus':    return const Color(0xFFE67E22);
      case 'Rusak':    return Colors.red;
      case 'Tidak Ada': return AppColors.textGrey;
      default:         return AppColors.textGrey;
    }
  }

  @override
  void initState() {
    super.initState();

    final data = itemData;

    kondisi = data["kondisi"] ?? kondisi;
    showKerusakan = data["showKerusakan"] ?? false;
    catatanController.text = data["catatan"] ?? "";

    fotoUtama = getImage();
    fotoKerusakan = getKerusakanImages();
  }

  void updateFormData() {
    final data = {
      "kondisi": kondisi,
      "showKerusakan": showKerusakan,
      "catatan": catatanController.text,
    };

    if (widget.formData != null && widget.fieldKey != null) {
      final safeMap = Map<String, dynamic>.from(widget.formData!);

      safeMap[widget.fieldKey!] = Map<String, dynamic>.from(data);

      widget.formData!.clear();
      widget.formData!.addAll(safeMap);
    }

    // ✅ KIRIM KE PARENT
    if (widget.onChanged != null) {
      widget.onChanged!(data);
    }
  }

  void saveAll() {
    final data = {
      "kondisi": kondisi,
      "showKerusakan": showKerusakan,
      "catatan": catatanController.text,
      "foto": fotoUtama?.path,
      "foto_kerusakan": fotoKerusakan.map((e) => e.path).toList(),
    };

    // 🔥 FIX: tulis ke formData[section][fieldKey], bukan formData[fieldKey]
    if (widget.formData != null && widget.fieldKey != null) {
      final safeMap = Map<String, dynamic>.from(widget.formData!);

      // Pastikan section map sudah ada
      safeMap[widget.section] ??= <String, dynamic>{};
      final sectionMap = Map<String, dynamic>.from(safeMap[widget.section]);

      sectionMap[widget.fieldKey!] = data;
      safeMap[widget.section] = sectionMap;

      widget.formData!.clear();
      widget.formData!.addAll(safeMap);
    }

    widget.onChanged?.call(data);
  }

  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
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
                          kondisi,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kondisiColor),
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

          // ── UPLOAD FOTO ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: FotoUploadBox(
              label: 'Upload Foto',
              imageFile: fotoUtama,
              onImagePicked: (file) {
                setState(() {
                  fotoUtama = file;
                });
                saveAll();
              },
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

                    // 🔥 SIMPAN
                    if (widget.formData != null && widget.fieldKey != null) {
                      final existing = Map<String, dynamic>.from(
                        widget.formData![widget.fieldKey!] ?? {},
                      );

                      existing["kondisi"] = kondisi;
                      existing["showKerusakan"] = showKerusakan;

                      final safeMap = Map<String, dynamic>.from(widget.formData!);

                      safeMap[widget.section] ??= {};
                      final sectionMap = Map<String, dynamic>.from(safeMap[widget.section]);

                      sectionMap[widget.fieldKey!] = existing;

                      safeMap[widget.section] = sectionMap;

                      widget.formData!.clear();
                      widget.formData!.addAll(safeMap);
                    }
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
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── FIELD KERUSAKAN ──
          if (showKerusakan)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...fotoKerusakan.map((file) => Stack(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(file),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  fotoKerusakan.remove(file);
                                });
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
                      )),

                      FotoUploadBox(
                        label: 'Upload Foto',
                        onImagePicked: (file) {
                          setState(() {
                            fotoKerusakan.add(file); // ✅ BETUL
                          });
                          saveAll();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // ── CATATAN OPSIONAL ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _buildInputField(hint: 'Catatan (Opsional)'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required String hint, int maxLines = 1}) {
    return TextField(
      controller: catatanController, // 🔥
      maxLines: maxLines,
      onChanged: (value) {
        saveAll();
      },
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
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
    );
  }

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
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Pilih Kondisi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 12),
            ...kondisiOptions.map((opt) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                kondisi == opt ? Icons.radio_button_checked : Icons.radio_button_off,
                color: kondisi == opt ? AppColors.primary : AppColors.textGrey,
                size: 20,
              ),
              title: Text(
                opt,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: kondisi == opt ? FontWeight.w600 : FontWeight.w400,
                  color: kondisi == opt ? AppColors.primary : AppColors.textDark,
                ),
              ),
              onTap: () {
                setState(() => kondisi = opt);

                // 🔥 FIX: sama, tulis ke section dulu
                if (widget.formData != null && widget.fieldKey != null) {
                  final safeMap = Map<String, dynamic>.from(widget.formData!);

                  safeMap[widget.section] ??= <String, dynamic>{};
                  final sectionMap = Map<String, dynamic>.from(safeMap[widget.section]);

                  sectionMap[widget.fieldKey!] = {
                    ...Map<String, dynamic>.from(sectionMap[widget.fieldKey!] ?? {}),
                    "kondisi": kondisi,
                    "showKerusakan": showKerusakan,
                  };

                  safeMap[widget.section] = sectionMap;
                  widget.formData!.clear();
                  widget.formData!.addAll(safeMap);
                }

                saveAll(); // panggil saveAll() setelah update kondisi
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _pickImage() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        fotoKerusakan.add(File(image.path));
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        fotoKerusakan.add(File(image.path));
      });
    }
  }

  Map<String, dynamic> get itemData {
    if (widget.formData != null && widget.fieldKey != null) {
      final raw = widget.formData?[widget.fieldKey];
      if (raw == null) return {};
      if (raw is Map<String, dynamic>) return raw;
      if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
      return {};
    }
    return {};
  }

  File? getImage() {
    final path = itemData["foto"];
    if (path == null || path.toString().isEmpty) return null;
    return File(path);
  }

  List<File> getKerusakanImages() {
    final list = itemData["foto_kerusakan"];
    if (list == null) return [];
    return List<String>.from(list).map((e) => File(e)).toList();
  }
}