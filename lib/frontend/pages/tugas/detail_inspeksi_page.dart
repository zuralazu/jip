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

  Map<String, String> _validationErrors = {};

  // ✅ FIX Bug 1: Track step mana yang sudah pernah disentuh user
  // Validasi hanya muncul di step yang sudah disentuh
  final Set<int> _touchedSteps = {};

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
      Map<String, dynamic> base,
      Map<String, dynamic> incoming,
      ) {
    final result = Map<String, dynamic>.from(base);
    incoming.forEach((key, value) {
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
        formData = {...formData, ...cached};
        formData["order_id"] = _orderId;
      });
    } catch (e) {
      final cached = _formCache[_orderId] ?? {};
      setState(() {
        formData = {...formData, ...cached};
      });
    }
  }

  void _onFormChanged(Map<String, dynamic> data) {
    formData = data;
    _formCache[_orderId] = Map<String, dynamic>.from(data);

    // ✅ FIX Bug 1: Mark step ini sebagai sudah disentuh
    _touchedSteps.add(currentStep);

    // Re-run validasi hanya untuk step yang sudah disentuh
    setState(() {
      _validationErrors = _validateStep(currentStep);
    });
  }

  // ─── VALIDATION ─────────────────────────────────────────────────────────────

  Map<String, String> _validateStep(int step) {
    final errors = <String, String>{};

    switch (step) {
      case 0:
        _required(errors, 'nomor_polisi', 'Nomor Polisi wajib diisi');
        _required(errors, 'tipe_mobil', 'Tipe Mobil wajib diisi');
        _required(errors, 'transmisi', 'Transmisi wajib diisi');
        _required(errors, 'kapasitas_mesin', 'Kapasitas Mesin wajib diisi');
        _required(errors, 'bahan_bakar', 'Bahan Bakar wajib diisi');
        _required(errors, 'warna_mobil', 'Warna Mobil wajib diisi');
        _required(errors, 'jarak_tempuh', 'Jarak Tempuh wajib diisi');
        _required(errors, 'kondisi_tabrak', 'Kondisi Tabrak wajib diisi');
        _required(errors, 'kondisi_banjir', 'Kondisi Banjir wajib diisi');
        break;

      case 1:
        _required(errors, 'foto_stnk', 'Foto STNK wajib diupload');
        _required(errors, 'pajak_1_tahun', 'Pajak 1 Tahun wajib diisi');
        _required(errors, 'pajak_5_tahun', 'Pajak 5 Tahun wajib diisi');
        _required(errors, 'nomor_rangka', 'Nomor Rangka wajib diisi');
        _required(errors, 'nomor_mesin', 'Nomor Mesin wajib diisi');
        _required(errors, 'foto_bpkb_1', 'Foto BPKB 1 wajib diupload');
        _required(errors, 'nama_pemilik', 'Nama Pemilik wajib diisi');
        _required(errors, 'nomor_bpkb', 'Nomor BPKB wajib diisi');
        _required(errors, 'kepemilikan_mobil', 'Kepemilikan Mobil wajib dipilih');
        _required(errors, 'sph', 'SPH wajib dipilih');
        _required(errors, 'benang_pembatas', 'Benang Pembatas wajib dipilih');
        _required(errors, 'hologram_polri', 'Hologram POLRI wajib dipilih');
        _required(errors, 'faktur', 'Faktur wajib dipilih');
        _required(errors, 'nik', 'NIK wajib dipilih');
        _required(errors, 'form_a', 'Form A wajib dipilih');
        _required(errors, 'buku_service', 'Buku Service wajib dipilih');
        _required(errors, 'buku_manual', 'Buku Manual wajib dipilih');
        _required(errors, 'cek_logo_scanner', 'Cek Logo Scanner wajib dipilih');
        _required(errors, 'kir', 'KIR wajib dipilih');
        _required(errors, 'samsat_online', 'Samsat Online wajib dipilih');
        break;

      case 2:
        _validateInspeksiSection(errors, 'interior');
        break;
      case 3:
        _validateInspeksiSection(errors, 'eksterior');
        break;
      case 4:
        _validateInspeksiSection(errors, 'mesin');
        break;
      case 5:
        _validateInspeksiSection(errors, 'kaki_kaki');
        break;
    }

    return errors;
  }

  void _required(Map<String, String> errors, String key, String message) {
    final val = formData[key];
    if (val == null || val.toString().trim().isEmpty) {
      errors[key] = message;
    }
  }

  void _validateInspeksiSection(Map<String, String> errors, String section) {
    final sectionData = formData[section];
    if (sectionData == null || sectionData is! Map) {
      errors['${section}_empty'] = 'Belum ada item yang diperiksa di bagian ini';
      return;
    }

    int missingKondisi = 0;
    int missingFoto = 0;
    int totalItems = 0;

    sectionData.forEach((key, value) {
      if (int.tryParse(key.toString()) == null) return;
      totalItems++;

      if (value is Map) {
        // ✅ FIX: cek status_kondisi dulu, fallback ke kondisi
        final kondisi = value['status_kondisi']?.toString() ?? value['kondisi']?.toString() ?? '';

        // ✅ FIX: foto sekarang bisa berupa list (foto_utama) atau string (foto)
        final fotoUtamaList = value['foto_utama'];
        final fotoSingle = value['foto']?.toString() ?? '';
        final hasFoto = (fotoUtamaList is List && fotoUtamaList.isNotEmpty) || fotoSingle.isNotEmpty;

        if (kondisi.isEmpty) missingKondisi++;
        if (!hasFoto) missingFoto++;
      } else {
        missingKondisi++;
        missingFoto++;
      }
    });

    if (totalItems == 0) {
      errors['${section}_empty'] = 'Belum ada item yang diperiksa di bagian ini';
    } else {
      if (missingKondisi > 0) {
        errors['${section}_kondisi'] = '$missingKondisi item belum dipilih kondisinya';
      }
      if (missingFoto > 0) {
        errors['${section}_foto'] = '$missingFoto item belum dilengkapi foto';
      }
    }
  }

  Map<int, Map<String, String>> _validateAll() {
    final result = <int, Map<String, String>>{};
    for (int i = 0; i < stepTitles.length; i++) {
      final e = _validateStep(i);
      if (e.isNotEmpty) result[i] = e;
    }
    return result;
  }

  // ─── SAVE / SUBMIT ──────────────────────────────────────────────────────────

  void saveDraft() async {
    // ✅ FIX Bug 1: Mark step ini sebagai touched saat user tekan tombol simpan
    _touchedSteps.add(currentStep);

    final errors = _validateStep(currentStep);
    setState(() => _validationErrors = errors);

    if (errors.isNotEmpty) {
      _showValidationErrorPopup(errors.values.toList(), stepTitle: stepTitles[currentStep]);
      return;
    }

    _showLoading();
    try {
      final orderId = _orderId;
      switch (currentStep) {
        case 0: await ApiService.saveInformasi(orderId, formData); break;
        case 1: await ApiService.saveDokumen(orderId, formData); break;
        case 2: await ApiService.saveInterior(orderId, formData, isFinal: false); break;
        case 3: await ApiService.saveEksterior(orderId, formData, isFinal: false); break;
        case 4: await ApiService.saveMesin(orderId, formData, isFinal: false); break;
        case 5: await ApiService.saveKakiKaki(orderId, formData, isFinal: false); break;
      }

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
    final allErrors = _validateAll();

    if (allErrors.isNotEmpty) {
      _showAllStepsErrorPopup(allErrors);
      return;
    }

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
      final res = await ApiService.submitFinal(_orderId);

      if (res is Map && res["statusCode"] == 400) {
        _hideLoading();
        final backendErrors = res["data"]?["errors"];
        if (backendErrors is List && backendErrors.isNotEmpty) {
          _showBackendErrorPopup(backendErrors.cast<String>());
        } else {
          _showErrorPopup(res["data"]?["message"] ?? "Gagal menyelesaikan inspeksi");
        }
        return;
      }

      _formCache.remove(_orderId);
      setState(() => inspectionStatus = "done");
      _hideLoading();

      await _showSuccessPopupAsync("Inspeksi berhasil diselesaikan!");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _hideLoading();
      final msg = e.toString();
      if (msg.contains("VALIDATION_ERROR") || msg.contains("400")) {
        _showErrorPopup("Masih ada data yang belum lengkap. Periksa kembali semua bagian.");
      } else {
        _showErrorPopup("Gagal submit: $msg");
      }
    }
  }

  // ─── ERROR POPUPS ────────────────────────────────────────────────────────────

  void _showValidationErrorPopup(List<String> errors, {required String stepTitle}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Text("$stepTitle Belum Lengkap"),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Harap lengkapi field berikut:", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...errors.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("• ", style: TextStyle(color: Colors.orange)),
                Expanded(child: Text(e, style: const TextStyle(fontSize: 13))),
              ]),
            )),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
            onPressed: () => Navigator.pop(context),
            child: const Text("Oke, Saya Perbaiki", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAllStepsErrorPopup(Map<int, Map<String, String>> allErrors) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.error_outline_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text("Inspeksi Belum Lengkap"),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Beberapa bagian masih belum lengkap:", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...allErrors.entries.map((entry) {
                final stepName = stepTitles[entry.key];
                final stepErrors = entry.value.values.toList();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stepName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 4),
                      ...stepErrors.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("• ", style: TextStyle(color: Colors.red, fontSize: 12)),
                          Expanded(child: Text(e, style: const TextStyle(fontSize: 12))),
                        ]),
                      )),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
            onPressed: () {
              Navigator.pop(context);
              setState(() => currentStep = allErrors.keys.first);
            },
            child: const Text("Ke Bagian Pertama", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBackendErrorPopup(List<String> errors) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.error_outline_rounded, color: Colors.red),
          SizedBox(width: 8),
          Expanded(child: Text("Data Belum Lengkap", style: TextStyle(fontSize: 15))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Server mendeteksi data berikut belum lengkap:",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            ...errors.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(child: Text(e, style: const TextStyle(fontSize: 13))),
              ]),
            )),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
            onPressed: () => Navigator.pop(context),
            child: const Text("Oke, Saya Lengkapi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final namaMobil = widget.dataTugas['nama_mobil'] ?? 'Inspeksi';
    final isLastStep = currentStep == stepTitles.length - 1;

    final List<Widget> steps = [
      InformasiMobilPage(
        formData: formData,
        onChanged: _onFormChanged,
        // ✅ FIX Bug 1: Hanya kirim validationErrors kalau step sudah disentuh
        validationErrors: _touchedSteps.contains(0) ? _validationErrors : {},
      ),
      DokumenPage(
        formData: formData,
        onChanged: _onFormChanged,
        // ✅ FIX Bug 1: Hanya kirim validationErrors kalau step sudah disentuh
        validationErrors: _touchedSteps.contains(1) ? _validationErrors : {},
      ),
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
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(stepTitles.length, (i) {
                  final isSelected = currentStep == i;

                  // ✅ FIX Bug 1: Dot merah hanya muncul kalau step sudah pernah disentuh
                  final hasError = _touchedSteps.contains(i) && _validateStep(i).isNotEmpty;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        currentStep = i;
                        // ✅ FIX Bug 1: Hanya tampilkan error kalau step sudah pernah disentuh
                        _validationErrors = _touchedSteps.contains(i)
                            ? _validateStep(i)
                            : {};
                      });
                    },
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stepTitles[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              color: isSelected ? AppColors.primary : Colors.white,
                            ),
                          ),
                          if (hasError) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
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

  Widget _buildBottomAction(bool isLastStep) {
    final isDone = inspectionStatus == "done";
    final hasErrors = _validationErrors.isNotEmpty;

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
              backgroundColor: hasErrors ? Colors.grey : AppColors.primary,
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
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text("Berhasil"),
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
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text("Berhasil"),
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