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
  final Map<String, dynamic> dataTugas;

  const DetailInspeksiPage({super.key, required this.dataTugas});

  @override
  State<DetailInspeksiPage> createState() => _DetailInspeksiPageState();
}

class _DetailInspeksiPageState extends State<DetailInspeksiPage>
    with BasePage {
  int currentStep = 0;
  Map<String, dynamic> formData = {};

  final List<String> stepTitles = [
    'Informasi',
    'Dokumen',
    'Interior',
    'Eksterior',
    'Mesin',
    'Kaki-kaki',
  ];

  @override
  void initState() {
    super.initState();

    formData["order_id"] = widget.dataTugas["order_id"];
  }

  Widget build(BuildContext context) {
    final namaMobil = widget.dataTugas['nama_mobil'] ?? 'Inspeksi';

    final List<Widget> steps = [
      InformasiMobilPage(
        formData: formData,
        onChanged: (data) {
          formData = data;
        },
      ),
      DokumenPage(
        formData: formData,
        onChanged: (data) {
          formData = data;
        },
      ),
      InteriorPage(
        formData: formData,
        onChanged: (data) {
          formData = data;
        },),
      EksteriorPage(
        formData: formData,
        onChanged: (data) {
          formData = data;
        },
      ),
      MesinPage(
        formData: formData,
        onChanged: (data) {
          formData = data;
        },
      ),
      KakiKakiPage(
        formData: formData,
        onChanged: (data) {
          formData = data;
        },
      ),
    ];

    return Scaffold(
      bottomNavigationBar: _buildBottomAction(),

      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          namaMobil,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Draft',
              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── TAB BAR ──
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(stepTitles.length, (i) {
                  final isSelected = currentStep == i;
                  return GestureDetector(
                      onTap: () {
                        setState(() => currentStep = i);
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

          // ── CONTENT ──
          Expanded(child: steps[currentStep]),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    final isLastStep = currentStep == stepTitles.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLastStep ? Colors.green : AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isLastStep ? submitFinal : saveDraft,
        child: Text(
          isLastStep ? "Simpan Inspeksi" : "Simpan Perubahan",
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _hideLoading() {
    Navigator.pop(context);
  }

  void _showResultDialog({required bool success, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(success ? "Berhasil" : "Gagal"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void saveDraft() async {
    try {
      final orderId = widget.dataTugas['order_id'];

      if (currentStep == 0) {
        await ApiService.saveInformasi(orderId, formData);
      } else if (currentStep == 1) {
        await ApiService.saveDokumen(orderId, formData);
      } else if (currentStep == 2) {
        await ApiService.saveInterior(orderId, formData);
      }
      // else if (currentStep == 3) {
      //   await ApiService.saveEksterior(orderId, formData);
      // } else if (currentStep == 4) {
      //   await ApiService.saveMesin(orderId, formData);
      // } else if (currentStep == 5) {
      //   await ApiService.saveKakiKaki(orderId, formData);
      // }

      _showSuccessPopup("Draft berhasil disimpan");
    } catch (e) {
      _showErrorPopup("Gagal simpan draft: ${e.toString()}");
    }
  }

  void submitFinal() async {
    try {
      final orderId = widget.dataTugas['order_id'];

      await ApiService.submitFinal(orderId);

      _showSuccessPopup("Inspeksi berhasil dikirim");

      Navigator.pop(context);
    } catch (e) {
      _showErrorPopup("Gagal submit: ${e.toString()}");
    }
  }

  void _showSuccessPopup(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Berhasil"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Gagal"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }
}