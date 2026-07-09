import 'dart:async';

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
import 'step/kesimpulan_page.dart';
import 'step/kerusakan_lainnya_page.dart';

class DetailInspeksiPage extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> dataTugas;
  const DetailInspeksiPage(
      {super.key, required this.dataTugas, required this.orderId});

  @override
  State<DetailInspeksiPage> createState() => _DetailInspeksiPageState();
}

class _DetailInspeksiPageState extends State<DetailInspeksiPage> with BasePage {
  String inspectionStatus = "draft";
  int currentStep = 0;
  Map<String, dynamic> formData = {};
  bool isLoading = true;

  final Map<int, Map<String, String>> _stepErrors = {};
  final Set<int> _touchedSteps = {};
  final Map<int, Set<String>> _touchedFields = {};

  static final Map<int, Map<String, dynamic>> _formCache = {};

  Timer? _validationTimer;

  // ── Step 6 = Kesimpulan (baru) ──────────────────────────────────────────
  final List<String> stepTitles = [
    'Informasi', 'Dokumen', 'Interior', 'Eksterior', 'Mesin', 'Kaki-kaki', 'Kesimpulan', 'Lainnya',
  ];

  @override
  void dispose() {
    _validationTimer?.cancel();
    super.dispose();
  }


  final List<IconData> stepIcons = [
    Icons.info_outline_rounded,
    Icons.description_outlined,
    Icons.weekend_outlined,
    Icons.directions_car_outlined,
    Icons.settings_outlined,
    Icons.tire_repair_outlined,
    Icons.assignment_turned_in_outlined,
    Icons.add_box_outlined,
  ];

  int get _orderId => widget.orderId;

  Map<String, String> get _currentErrors {
    final allErrors = _stepErrors[currentStep] ?? {};
    if (_touchedSteps.contains(currentStep)) return allErrors;
    final touched = _touchedFields[currentStep] ?? {};
    return Map.fromEntries(allErrors.entries.where((e) => touched.contains(e.key)));
  }

  @override
  void initState() {
    super.initState();
    formData["order_id"] = _orderId;
    loadExistingData();
    loadInformasi();
    loadDokumen();
    loadInspeksiData();
  }

  // ─── LOAD ────────────────────────────────────────────────────────────────

  Future<void> loadInspeksiData() async {
    try {
      final results = await Future.wait([
        ApiService.getInterior(_orderId),
        ApiService.getEksterior(_orderId),
        ApiService.getMesin(_orderId),
        ApiService.getKakiKaki(_orderId),
      ]);
      if (!mounted) return;
      setState(() {
        _fillSectionIfEmpty('interior',  results[0]);
        _fillSectionIfEmpty('eksterior', results[1]);
        _fillSectionIfEmpty('mesin',     results[2]);
        _fillSectionIfEmpty('kaki_kaki', results[3]);
      });
    } catch (e) {
      debugPrint("ERROR loadInspeksiData: $e");
      if (e.toString().contains('UNAUTHORIZED') && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }

  void _fillSectionIfEmpty(String key, Map<String, dynamic> res) {
    if (formData[key] != null && (formData[key] as Map).isNotEmpty) return;
    final raw = res["data"]?["data"] ?? res["data"];
    if (raw is List) formData[key] = _parseInspeksiList(raw);
  }

  Map<String, dynamic> _parseInspeksiList(List<dynamic> list) {
    final result = <String, dynamic>{};
    for (final item in list) {
      if (item is! Map) continue;
      final itemId = item["item_id"]?.toString();
      if (itemId == null) continue;
      result[itemId] = {
        "status_kondisi": item["status_kondisi"]?.toString() ?? "Normal",
        "catatan":        item["catatan"]?.toString() ?? "",
        "foto_utama":     _parseFotoList(item["foto_utama"] ?? item["foto"]),
        "foto":           item["foto"]?.toString(),
        "foto_tambahan": _parseFotoList(item["foto_tambahan"]),
      };
    }
    return result;
  }

  List<String> _parseFotoList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    if (raw is String && raw.isNotEmpty) return [raw];
    return [];
  }

  Map<String, dynamic> _mergeSafe(Map<String, dynamic> base, Map<String, dynamic> incoming) {
    const protected = {'interior', 'eksterior', 'mesin', 'kaki_kaki'};
    final result = Map<String, dynamic>.from(base);
    incoming.forEach((key, value) {
      if (protected.contains(key)) return;
      if (value != null && value.toString().isNotEmpty) result[key] = value;
    });
    return result;
  }

  Future<void> loadDokumen() async {
    try {
      final res = await ApiService.getDokumen(widget.orderId);
      if (res["statusCode"] == 200 && mounted) {
        final api    = Map<String, dynamic>.from(res["data"] ?? {});
        final cached = _formCache[_orderId] ?? {};
        setState(() {
          formData = _mergeSafe(api, formData);
          for (final k in ['interior', 'eksterior', 'mesin', 'kaki_kaki']) {
            if (cached[k] != null) formData[k] = cached[k];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("ERROR loadDokumen: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadInformasi() async {
    try {
      final res = await ApiService.getInformasi(widget.orderId);
      if (res["statusCode"] == 200 && mounted) {
        final data   = res["data"]?["data"] ?? res["data"] ?? {};
        final cached = _formCache[_orderId] ?? {};
        setState(() {
          formData = _mergeSafe(data, formData);
          for (final k in ['interior', 'eksterior', 'mesin', 'kaki_kaki']) {
            if (cached[k] != null) formData[k] = cached[k];
          }
        });
      }
    } catch (e) {
      debugPrint("ERROR loadInformasi: $e");
    }
  }

  Future<void> loadExistingData() async {
    try {
      final res  = await ApiService.getTugas();
      final list = res["data"]["data"] as List;
      final tugas = list.firstWhere((e) => e["order_id"] == _orderId, orElse: () => {});
      final cached = _formCache[_orderId] ?? {};
      if (!mounted) return;
      setState(() {
        inspectionStatus = tugas["status_inspeksi"] ?? "draft";
        formData = {...formData, ...cached};
        formData["order_id"] = _orderId;
      });
    } catch (e) {
      debugPrint("ERROR loadExistingData: $e");
      final cached = _formCache[_orderId] ?? {};
      if (mounted) setState(() => formData = {...formData, ...cached});
    }
  }

  // ─── FORM CHANGED ────────────────────────────────────────────────────────

  void _onFormChanged(Map<String, dynamic> data) {
    final changedKeys = <String>[];
    data.forEach((key, newVal) {
      final oldVal = formData[key];
      if (oldVal?.toString() != newVal?.toString()) changedKeys.add(key);
    });

    formData = data;
    _formCache[_orderId] = Map<String, dynamic>.from(data);

    _touchedFields[currentStep] ??= {};
    _touchedFields[currentStep]!.addAll(changedKeys);

    // ← Hitung error tapi JANGAN setState
    // Error bar di bottom hanya perlu update saat user stop ketik
    // pakai debounce supaya tidak rebuild tiap karakter
    _debounceValidation();
  }

  void _debounceValidation() {
    _validationTimer?.cancel();
    _validationTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _stepErrors[currentStep] = _validateStep(currentStep);
        });
      }
    });
  }

  // ─── VALIDATION ──────────────────────────────────────────────────────────

  Map<String, String> _validateStep(int step) {
    final e = <String, String>{};
    switch (step) {
      case 0:
        _req(e, 'nomor_polisi',    'Nomor Polisi wajib diisi');
        _req(e, 'tipe_mobil',      'Tipe Mobil wajib diisi');
        _req(e, 'transmisi',       'Transmisi wajib diisi');
        _req(e, 'kapasitas_mesin', 'Kapasitas Mesin wajib diisi');
        _req(e, 'bahan_bakar',     'Bahan Bakar wajib diisi');
        _req(e, 'warna_mobil',     'Warna Mobil wajib diisi');
        _req(e, 'jarak_tempuh',    'Jarak Tempuh wajib diisi');
        break;
      case 1:
        _req(e, 'foto_stnk',         'Foto STNK wajib diupload');
        _req(e, 'pajak_1_tahun',     'Pajak 1 Tahun wajib diisi');
        _req(e, 'pajak_5_tahun',     'Pajak 5 Tahun wajib diisi');
        _req(e, 'nomor_rangka',      'Nomor Rangka wajib diisi');
        _req(e, 'nomor_mesin',       'Nomor Mesin wajib diisi');
        _req(e, 'foto_bpkb_1',       'Foto BPKB 1 wajib diupload');
        _req(e, 'nama_pemilik',      'Nama Pemilik wajib diisi');
        _req(e, 'nomor_bpkb',        'Nomor BPKB wajib diisi');
        _req(e, 'kepemilikan_mobil', 'Kepemilikan Mobil wajib dipilih');
        _req(e, 'sph',               'SPH wajib dipilih');
        _req(e, 'benang_pembatas',   'Benang Pembatas wajib dipilih');
        _req(e, 'hologram_polri',    'Hologram POLRI wajib dipilih');
        _req(e, 'faktur',            'Faktur wajib dipilih');
        _req(e, 'nik',               'NIK wajib dipilih');
        _req(e, 'form_a',            'Form A wajib dipilih');
        _req(e, 'buku_service',      'Buku Service wajib dipilih');
        _req(e, 'buku_manual',       'Buku Manual wajib dipilih');
        _req(e, 'cek_logo_scanner',  'Cek Logo Scanner wajib dipilih');
        _req(e, 'kir',               'KIR wajib dipilih');
        _req(e, 'samsat_online',     'Samsat Online wajib dipilih');
        break;
      case 2: _validateSection(e, 'interior');  break;
      case 3: _validateSection(e, 'eksterior'); break;
      case 4: _validateSection(e, 'mesin');     break;
      case 5: _validateSection(e, 'kaki_kaki'); break;
    // ── Step 6: Kesimpulan ────────────────────────────────────────────
      case 6:
        _req(e, 'kondisi_tabrak', 'Kondisi Tabrak wajib dipilih');
        _req(e, 'kondisi_banjir', 'Kondisi Banjir wajib dipilih');
        _req(e, 'catatan_tambahan', 'Kesimpulan wajib diisi');
        break;
    }
    return e;
  }

  void _req(Map<String, String> e, String key, String msg) {
    final val = formData[key];
    if (val == null || val.toString().trim().isEmpty) e[key] = msg;
  }

  void _validateSection(Map<String, String> e, String section) {
    final data = formData[section];
    if (data == null || data is! Map || data.isEmpty) {
      e['${section}_empty'] = 'Belum ada data inspeksi di bagian ini';
      return;
    }

    int missingKondisi = 0, total = 0;
    data.forEach((key, value) {
      if (int.tryParse(key.toString()) == null) return;
      total++;
      if (value is Map) {
        final kondisi = value['status_kondisi']?.toString() ?? '';
        // ← foto TIDAK dicek lagi, opsional
        if (kondisi.isEmpty) missingKondisi++;
      } else {
        missingKondisi++;
      }
    });

    if (total == 0) {
      e['${section}_empty'] = 'Belum ada item yang diperiksa';
    } else {
      if (missingKondisi > 0) {
        e['${section}_kondisi'] = '$missingKondisi item belum dipilih kondisinya';
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

  // ─── SAVE / SUBMIT ────────────────────────────────────────────────────────

  void saveDraft() async {
    _touchedSteps.add(currentStep);
    final errors = _validateStep(currentStep);
    setState(() => _stepErrors[currentStep] = errors);

    if (errors.isNotEmpty) {
      _showValidationSheet(errors.values.toList(), stepTitle: stepTitles[currentStep]);
      return;
    }

    _showLoading();
    try {
      final id = _orderId;

      // ← Selalu simpan semua section inspeksi sekaligus

      if (currentStep == 7) {
        _showSuccessToast('Section tersimpan!');
        return;
      }

      await Future.wait([
        if (currentStep == 0) ApiService.saveInformasi(id, formData),
        if (currentStep == 1) ApiService.saveDokumen(id, formData),
        if (currentStep >= 2 && currentStep <= 5) ...[
          ApiService.saveInterior(id, formData),
          ApiService.saveEksterior(id, formData),
          ApiService.saveMesin(id, formData),
          ApiService.saveKakiKaki(id, formData),
        ],
        if (currentStep == 6) ApiService.saveKesimpulan(id, formData),
      ], eagerError: false);

      if (inspectionStatus == 'draft') setState(() => inspectionStatus = 'progress');
      _hideLoading();
      _showSuccessToast('Perubahan berhasil disimpan!');
    } catch (e) {
      _hideLoading();
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showErrorDialog(msg);
    }
  }

  void submitFinal() async {
    final allErrors = _validateAll();
    if (allErrors.isNotEmpty) {
      setState(() {
        allErrors.forEach((step, errs) {
          _touchedSteps.add(step);
          _stepErrors[step] = errs;
        });
      });
      _showAllErrorsSheet(allErrors);
      return;
    }

    final confirm = await _showConfirmDialog();
    if (confirm != true) return;

    _showLoading();
    try {
      final res = await ApiService.submitFinal(_orderId);
      if (res is Map && res["statusCode"] == 400) {
        _hideLoading();
        final be = res["data"]?["errors"];
        if (be is List && be.isNotEmpty) {
          _showBackendErrorDialog(be.cast<String>());
        } else {
          _showErrorDialog(res["data"]?["message"] ?? "Gagal menyelesaikan inspeksi");
        }
        return;
      }
      _formCache.remove(_orderId);
      setState(() => inspectionStatus = "done");
      _hideLoading();
      await _showSuccessDialogAsync("Inspeksi berhasil diselesaikan!");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _hideLoading();
      _showErrorDialog("Gagal submit: ${e.toString()}");
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final namaMobil = widget.dataTugas['nama_mobil'] ?? 'Inspeksi';
    final isLastStep = currentStep == stepTitles.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: _buildAppBar(namaMobil),
      body: Column(
        children: [
          _buildTabBar(),
          _buildProgressStrip(),
          Expanded(
            child: IndexedStack(
              index: currentStep,
              children: [
                InformasiMobilPage(formData: formData, onChanged: _onFormChanged, validationErrors: _currentErrors),
                DokumenPage(formData: formData, onChanged: _onFormChanged, validationErrors: _currentErrors),
                InteriorPage(formData: formData, onChanged: _onFormChanged),
                EksteriorPage(formData: formData, onChanged: _onFormChanged),
                MesinPage(formData: formData, onChanged: _onFormChanged),
                KakiKakiPage(formData: formData, onChanged: _onFormChanged),
                KesimpulanPage(formData: formData, onChanged: _onFormChanged, validationErrors: _currentErrors),
                KerusakanLainnyaPage(orderId: _orderId, isDone: inspectionStatus == 'done',),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottom(isLastStep),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        Text('Inspeksi Kendaraan', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
      ]),
      actions: [_buildStatusChip()],
    );
  }

  Widget _buildStatusChip() {
    final isD  = inspectionStatus == 'done';
    final isP  = inspectionStatus == 'progress';
    final color = isD ? Colors.green.shade400 : isP ? Colors.amber.shade400 : Colors.blueGrey.shade300;
    final label = isD ? 'Selesai' : isP ? 'Progress' : 'Draft';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(stepTitles.length, (i) {
            final isSelected = currentStep == i;
            final isTouched  = _touchedSteps.contains(i);
            final errors     = _stepErrors[i] ?? {};
            final hasError   = isTouched && errors.isNotEmpty;
            final isDone     = isTouched && errors.isEmpty;

            return GestureDetector(
              onTap: () => setState(() => currentStep = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasError
                        ? Colors.red.shade300
                        : Colors.white.withOpacity(isSelected ? 1.0 : 0.35),
                    width: hasError ? 1.5 : 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isDone)
                    Icon(Icons.check_circle_rounded, size: 13,
                        color: isSelected ? Colors.green.shade500 : Colors.green.shade300)
                  else if (hasError)
                    Icon(Icons.error_rounded, size: 13,
                        color: isSelected ? Colors.red.shade500 : Colors.red.shade300)
                  else
                    Icon(stepIcons[i], size: 13,
                        color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.8)),
                  const SizedBox(width: 5),
                  Text(stepTitles[i], style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : Colors.white,
                  )),
                  if (hasError) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: Colors.red.shade500, borderRadius: BorderRadius.circular(10)),
                      child: Text('${errors.length}',
                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Progress Strip ───────────────────────────────────────────────────────

  Widget _buildProgressStrip() {
    int done = 0;
    for (int i = 0; i < stepTitles.length; i++) {
      if (_touchedSteps.contains(i) && (_stepErrors[i] == null || _stepErrors[i]!.isEmpty)) done++;
    }
    final pct = done / stepTitles.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Progres Pengisian',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            Text('$done / ${stepTitles.length} bagian',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: pct == 1.0 ? Colors.green.shade600 : AppColors.primary)),
          ]),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                  pct == 1.0 ? Colors.green.shade500 : AppColors.primary),
            ),
          ),
        ])),
      ]),
    );
  }

  // ── Bottom Bar ───────────────────────────────────────────────────────────

  Widget _buildBottom(bool isLastStep) {
    final isDone    = inspectionStatus == 'done';
    final errors    = _stepErrors[currentStep] ?? {};
    final hasErrors = _touchedSteps.contains(currentStep) && errors.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (hasErrors)
            GestureDetector(
              onTap: () => _showValidationSheet(errors.values.toList(), stepTitle: stepTitles[currentStep]),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${errors.length} field belum lengkap — tap untuk lihat',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Colors.orange.shade600),
                ]),
              ),
            ),

          // ── Step terakhir (Kesimpulan): tampilkan tombol Simpan + Selesaikan ──
          if (isLastStep)
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDone ? Colors.grey.shade300 : AppColors.primary,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isDone ? null : saveDraft,
                  icon: Icon(Icons.save_outlined, size: 15, color: Colors.white),
                  label: Text('Simpan', style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13,
                      color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDone ? Colors.grey.shade400 : Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: isDone ? null : submitFinal,
                  icon: Icon(isDone ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                      size: 15, color: Colors.white),
                  label: Text(isDone ? 'Sudah Selesai' : 'Selesaikan Inspeksi',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ])
          else
          // ── Step lainnya: hanya tombol Simpan ───────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone
                      ? Colors.grey.shade400
                      : hasErrors
                      ? Colors.orange.shade600
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: isDone ? null : saveDraft,
                icon: Icon(hasErrors ? Icons.warning_amber_rounded : Icons.save_outlined,
                    size: 16, color: Colors.white),
                label: Text(hasErrors ? 'Perbaiki & Simpan' : 'Simpan Perubahan',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
              ),
            ),
        ]),
      ),
    );
  }

  // ─── SHEETS & DIALOGS ─────────────────────────────────────────────────────

  void _showValidationSheet(List<String> errors, {required String stepTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _handle(),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$stepTitle Belum Lengkap',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              Text('${errors.length} field perlu dilengkapi',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ])),
          ]),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 12),
          ...errors.asMap().entries.map((en) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text('${en.key + 1}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange.shade700))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(en.value, style: const TextStyle(fontSize: 13, height: 1.5))),
            ]),
          )),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Oke, Saya Perbaiki',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  void _showAllErrorsSheet(Map<int, Map<String, String>> allErrors) {
    final totalErr = allErrors.values.fold(0, (s, e) => s + e.length);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.4,
        builder: (_, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(children: [
                _handle(),
                const SizedBox(height: 12),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Inspeksi Belum Lengkap',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    Text('$totalErr field di ${allErrors.length} bagian',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ])),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: List.generate(stepTitles.length, (i) {
                    final hasErr = allErrors.containsKey(i);
                    return GestureDetector(
                      onTap: hasErr ? () { Navigator.pop(context); setState(() => currentStep = i); } : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: hasErr ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: hasErr ? Colors.red.shade200 : Colors.green.shade200),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(hasErr ? Icons.close_rounded : Icons.check_rounded, size: 11,
                              color: hasErr ? Colors.red.shade600 : Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(stepTitles[i], style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: hasErr ? Colors.red.shade700 : Colors.green.shade700)),
                        ]),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey.shade100, height: 1),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                children: allErrors.entries.map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () { Navigator.pop(context); setState(() => currentStep = entry.key); },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(stepIcons[entry.key], size: 15, color: Colors.red.shade600),
                            const SizedBox(width: 7),
                            Text(stepTitles[entry.key],
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.red.shade700)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(10)),
                              child: Text('${entry.value.length} error',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red.shade700)),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.red.shade400),
                          ]),
                          const SizedBox(height: 8),
                          ...entry.value.values.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(margin: const EdgeInsets.only(top: 5), width: 4, height: 4,
                                  decoration: BoxDecoration(color: Colors.red.shade400, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e, style: const TextStyle(fontSize: 12, height: 1.4))),
                            ]),
                          )),
                        ]),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () { Navigator.pop(context); setState(() => currentStep = allErrors.keys.first); },
                    child: const Text('Masuk ke Section',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_circle_outline_rounded, size: 32, color: Colors.green.shade600),
            ),
            const SizedBox(height: 16),
            const Text('Selesaikan Inspeksi?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Setelah diselesaikan, data tidak dapat diubah lagi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
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
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ya, Selesaikan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showBackendErrorDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: Colors.red.shade400),
            const SizedBox(height: 12),
            const Text('Data Belum Lengkap',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Server mendeteksi data berikut:', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 12),
            ...errors.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.cancel_outlined, size: 15, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Expanded(child: Text(e, style: const TextStyle(fontSize: 13))),
              ]),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Oke', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── UTILITIES ────────────────────────────────────────────────────────────

  Widget _handle() => Container(
    width: 40, height: 4,
    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
  );

// ── Modern Loading Bottom Sheet ──────────────────────────────────────────
  void _showLoading({String stepLabel = 'Mengirim ke server'}) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoadingSheet(stepLabel: stepLabel),
    );
  }

  void _hideLoading() {
    if (mounted) Navigator.pop(context);
  }

  void _showSuccessToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      ]),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _showSuccessDialogAsync(String msg) async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 64, height: 64,
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded, size: 36, color: Colors.green.shade600),
            ),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Data inspeksi telah tersimpan.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // handle
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),

          // icon
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.error_outline_rounded, size: 28, color: Colors.red.shade500),
          ),
          const SizedBox(height: 16),

          const Text('Gagal Menyimpan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(msg,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400, height: 1.5)),
          const SizedBox(height: 24),

          // error card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, size: 15, color: Colors.red.shade400),
              const SizedBox(width: 10),
              Expanded(child: Text(msg,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.5))),
            ]),
          ),
          const SizedBox(height: 20),

          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(color: Colors.grey.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Perbaiki Sekarang',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _LoadingSheet extends StatefulWidget {
  final String stepLabel;
  const _LoadingSheet({required this.stepLabel});

  @override
  State<_LoadingSheet> createState() => _LoadingSheetState();
}

class _LoadingSheetState extends State<_LoadingSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(_slide),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle pill
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),

            // spinner
            SizedBox(
              width: 52, height: 52,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeCap: StrokeCap.round,
              ),
            ),
            const SizedBox(height: 18),

            // title
            const Text(
              'Menyimpan data...',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            Text(
              'Harap tunggu sebentar',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),

            // step indicators
            _buildStepRow(Icons.check_circle_rounded, 'Validasi data form', _StepState.done),
            _buildStepRow(Icons.autorenew_rounded,    widget.stepLabel,     _StepState.active),
            _buildStepRow(Icons.cloud_done_outlined,  'Konfirmasi tersimpan', _StepState.pending),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(IconData icon, String label, _StepState state) {
    final colors = {
      _StepState.done:    [const Color(0xFFF0FDF4), const Color(0xFF16A34A)],
      _StepState.active:  [const Color(0xFFEFF6FF), AppColors.primary],
      _StepState.pending: [const Color(0xFFF9FAFB), Colors.grey.shade400],
    }[state]!;

    final badgeColors = {
      _StepState.done:    [const Color(0xFFDCFCE7), const Color(0xFF15803D)],
      _StepState.active:  [const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)],
      _StepState.pending: [Colors.grey.shade100, Colors.grey.shade400],
    }[state]!;

    final badgeLabels = {
      _StepState.done:    'Selesai',
      _StepState.active:  'Proses',
      _StepState.pending: 'Menunggu',
    }[state]!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: .5)),
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: colors[0], borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 16, color: colors[1] as Color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
              color: badgeColors[0] as Color,
              borderRadius: BorderRadius.circular(20)),
          child: Text(badgeLabels,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColors[1] as Color)),
        ),
      ]),
    );
  }
}

enum _StepState { done, active, pending }