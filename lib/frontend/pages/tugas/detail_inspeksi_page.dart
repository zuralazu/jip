import 'package:flutter/material.dart';
import '../../core/base_page.dart';
import '../../services/api_service.dart';
import '../../utils/colors.dart';
import 'step/informasi_mobil_page.dart';
import 'step/dokumen_page.dart';
import 'step/interior_page.dart';
import 'step/eksterior_page.dart';
import 'step/mesin_page.dart';
import 'step/kaki_kaki_page.dart';

class DetailInspeksiPage extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> dataTugas;
  const DetailInspeksiPage({super.key, required this.dataTugas, required this.orderId});


  @override
  State<DetailInspeksiPage> createState() => _DetailInspeksiPageState();
}

class _DetailInspeksiPageState extends State<DetailInspeksiPage> with BasePage {

  String inspectionStatus = "draft";
  int currentStep = 0;
  Map<String, dynamic> formData = {};
  bool isLoading = true;


  // 🔥 Cache foto lokal per orderId — static agar bertahan saat back & masuk lagi
  static final Map<int, Map<String, dynamic>> _formCache = {};

  final List<String> stepTitles = [
    'Informasi', 'Dokumen', 'Interior', 'Eksterior', 'Mesin', 'Kaki-kaki',
  ];

  int get _orderId => widget.orderId;

  @override
  void initState() {
    super.initState();
    formData["order_id"] = _orderId;
    loadExistingData();
    loadInformasi();
    loadDokumen();
  }

  Map<String, dynamic> mergeSafe(
      Map<String, dynamic> base,      // dari API (nilai lama)
      Map<String, dynamic> incoming,  // dari user (nilai baru, prioritas lebih tinggi)
      ) {
    final result = Map<String, dynamic>.from(base);

    incoming.forEach((key, value) {
      // ✅ incoming (user) selalu menang, kecuali null/kosong
      if (value != null && value.toString().isNotEmpty) {
        result[key] = value;
      }
    });

    return result;
  }

  Future<void> loadDokumen() async {
    try {
      final res = await ApiService.getDokumen(widget.orderId);

      if (res["statusCode"] == 200) {
        final apiData = Map<String, dynamic>.from(res["data"] ?? {});

        setState(() {
          // ✅ formData (input user) yang menimpa apiData, bukan sebaliknya
          formData = mergeSafe(apiData, formData);
          isLoading = false;
        });
      }
    } catch (e) {
      print("ERROR LOAD DOKUMEN: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> loadInformasi() async {
    try {
      final res = await ApiService.getInformasi(widget.orderId);

      if (res["statusCode"] == 200) {
        final data = res["data"]?["data"] ?? res["data"] ?? {};

        setState(() {
          formData = mergeSafe(data, formData);
        });
      }
    } catch (e) {
      print("ERROR LOAD INFORMASI: $e");
    }
  }

  Future<void> loadExistingData() async {
    try {

      final res = await ApiService.getTugas();
      final tugas = (res["data"]["data"] as List)
          .firstWhere((e) => e["order_id"] == _orderId, orElse: () => {});

      final cached = _formCache[_orderId] ?? {};

      setState(() {
        inspectionStatus = tugas["status_inspeksi"] ?? "draft";

        formData = {
          ...formData,
          ...cached,
        };

        formData["order_id"] = _orderId;
      });
    } catch (e) {
      final cached = _formCache[_orderId] ?? {};



      setState(() {
        formData = {
          ...formData,
          ...cached,
        };
      });
    }
  }

  // 🔥 Dipanggil tiap kali ada perubahan di child page
  void _onFormChanged(Map<String, dynamic> data) {
    formData = data;

    // 🔥 simpan semua field
    _formCache[_orderId] = Map<String, dynamic>.from(data);

    setState(() {});
  }

  // 🔥 Ekstrak semua path foto lokal dan simpan ke static cache
  // void _saveLocalPhotosToCache(Map<String, dynamic> data) {
  //   final cache = Map<String, dynamic>.from(_localPhotoCache[_orderId] ?? {});
  //
  //   // Foto di root (dokumen)
  //   for (final key in ['foto_stnk', 'foto_bpkb_1', 'foto_bpkb_2', 'foto_bpkb_3', 'foto_bpkb_4']) {
  //     if (data[key] != null) cache[key] = data[key];
  //   }
  //
  //   // Foto di nested sections (interior, eksterior, mesin, kaki_kaki)
  //   for (final section in ['interior', 'eksterior', 'mesin', 'kaki_kaki']) {
  //     if (data[section] is Map) {
  //       cache[section] ??= {};
  //       final sectionCache = Map<String, dynamic>.from(cache[section] ?? {});
  //       final sectionData = data[section] as Map;
  //       sectionData.forEach((k, v) {
  //         if (v is Map && (v['foto'] != null || v['foto_kerusakan'] != null)) {
  //           sectionCache[k] = v;
  //         } else if (v is Map) {
  //           sectionCache[k] = {...(sectionCache[k] as Map? ?? {}), ...v};
  //         }
  //       });
  //       cache[section] = sectionCache;
  //     }
  //   }
  //
  //   _localPhotoCache[_orderId] = cache;
  // }

  @override
  Widget build(BuildContext context) {
    final namaMobil = widget.dataTugas['nama_mobil'] ?? 'Inspeksi';
    final isLastStep = currentStep == stepTitles.length - 1;

    final List<Widget> steps = [
      InformasiMobilPage(formData: formData, onChanged: _onFormChanged),
      DokumenPage(formData: formData, onChanged: _onFormChanged),
      InteriorPage(formData: formData, onChanged: _onFormChanged),
      EksteriorPage(formData: formData, onChanged: _onFormChanged),
      MesinPage(formData: formData, onChanged: _onFormChanged),
      KakiKakiPage(formData: formData, onChanged: _onFormChanged),
    ];

    return Scaffold(
      bottomNavigationBar: _buildBottomAction(isLastStep),
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(namaMobil,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(),
              style: TextStyle(
                color: _statusTextColor(),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(stepTitles.length, (i) {
                  final isSelected = currentStep == i;
                  return GestureDetector(
                    onTap: () => setState(() => currentStep = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(isSelected ? 1 : 0.5),
                        ),
                      ),
                      child: Text(
                        stepTitles[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected ? AppColors.primary : Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(child: steps[currentStep]),
        ],
      ),
    );
  }

  // 🔥 Bottom action: tombol berbeda tergantung tab
  Widget _buildBottomAction(bool isLastStep) {
    final isDone = inspectionStatus == "done";

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: isLastStep
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Di kaki-kaki: tampilkan KEDUA tombol
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isDone ? null : saveDraft,
                child: const Text(
                  "Simpan Perubahan",
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: isDone ? null : submitFinal,
                child: const Text(
                  "Simpan Inspeksi",
                  style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        )
            : SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: isDone ? null : saveDraft,
            child: const Text(
              "Simpan Perubahan",
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor() {
    switch (inspectionStatus) {
      case 'done': return Colors.green.shade50;
      case 'progress': return AppColors.yellow;
      default: return AppColors.yellow;
    }
  }

  Color _statusTextColor() {
    switch (inspectionStatus) {
      case 'done': return Colors.green.shade700;
      default: return AppColors.primary;
    }
  }

  String _statusLabel() {
    switch (inspectionStatus) {
      case 'done': return 'Selesai';
      case 'progress': return 'Progress';
      default: return 'Draft';
    }
  }

  void saveDraft() async {
    _showLoading();
    try {
      final orderId = _orderId;
      switch (currentStep) {
        case 0: await ApiService.saveInformasi(orderId, formData); break;
        case 1:
          print("=== FORM DATA DOKUMEN ===");
          print("foto_stnk: ${formData['foto_stnk']}");
          print("pajak_1_tahun: ${formData['pajak_1_tahun']}");
          print("nomor_rangka: ${formData['nomor_rangka']}");
          print("foto_bpkb_1: ${formData['foto_bpkb_1']}");

          await ApiService.saveDokumen(orderId, formData); break;
        case 2:
          print("=== BEFORE SAVE INTERIOR ===");
          print("formData keys: ${formData.keys.toList()}");
          print("formData['interior']: ${formData['interior']}");

          await ApiService.saveInterior(orderId, formData, isFinal: false); break;
        case 3: await ApiService.saveEksterior(orderId, formData, isFinal: false); break;
        case 4: await ApiService.saveMesin(orderId, formData, isFinal: false); break;
        case 5: await ApiService.saveKakiKaki(orderId, formData, isFinal: false); break;
      }

      // Update status ke progress
      if (inspectionStatus == 'draft') {
        setState(() => inspectionStatus = 'progress');
      }

      _hideLoading();
      _showSuccessPopup("Perubahan berhasil disimpan");
    } catch (e) {
      _hideLoading();
      _showErrorPopup("Gagal simpan: ${e.toString()}");
    }
  }

  void submitFinal() async {
    // 🔥 Konfirmasi sebelum finalisasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Selesaikan Inspeksi?"),
        content: const Text(
            "Setelah disimpan sebagai inspeksi final, data tidak bisa diubah lagi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya, Selesaikan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoading();
    try {
      // Simpan kaki-kaki dulu sebagai final
      await ApiService.saveKakiKaki(_orderId, formData, isFinal: true);
      await ApiService.submitFinal(_orderId);

      // 🔥 Hapus cache lokal setelah done
      _formCache.remove(_orderId);

      setState(() => inspectionStatus = "done");
      _hideLoading();

      await _showSuccessPopupAsync("Inspeksi berhasil diselesaikan!");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _hideLoading();
      _showErrorPopup("Gagal submit: ${e.toString()}");
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoading() {
    if (mounted) Navigator.pop(context);
  }

  void _showSuccessPopup(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          const Text("Berhasil"),
        ]),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  Future<void> _showSuccessPopupAsync(String message) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          const Text("Berhasil"),
        ]),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Gagal"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup"))],
      ),
    );
  }
}