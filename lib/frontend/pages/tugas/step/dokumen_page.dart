import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/foto_upload_box.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class DokumenPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onChanged;

  const DokumenPage({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  @override
  State<DokumenPage> createState() => _DokumenPageState();
}

class _DokumenPageState extends State<DokumenPage> {
  final Map<String, TextEditingController> _controllers = {};

  bool isScanningOcr = false;

  File? getImage(String key) {
    final path = widget.formData[key];
    if (path == null || path.toString().isEmpty) return null;
    return File(path);
  }

  TextEditingController _getController(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(
        text: widget.formData[key] ?? "",
      );
    }
    return _controllers[key]!;
  }

  Future<void> _scanOCR(String imagePath, {required bool isStnk}) async {
    setState(() {
      isScanningOcr = true;
    });

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String rawText = recognizedText.text;

      textRecognizer.close();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menganalisis dokumen...'), duration: Duration(seconds: 1)),
      );

      _parseOcrText(rawText, isStnk: isStnk);

    } catch (e) {
      debugPrint("Error OCR: $e");
    } finally {
      setState(() {
        isScanningOcr = false;
      });
    }
  }

  void _parseOcrText(String rawText, {required bool isStnk}) {
    String textUpper = rawText.toUpperCase();
    List<String> lines = textUpper.split('\n');

    RegExp rangkaRegExp = RegExp(r'\b[A-Z0-9]{17}\b');
    var rangkaMatch = rangkaRegExp.firstMatch(textUpper);
    String? foundRangka;

    if (rangkaMatch != null) {
      foundRangka = rangkaMatch.group(0)!;
      updateForm("nomor_rangka", foundRangka);
      _getController("nomor_rangka").text = foundRangka;
    }

    String? foundBpkb;
    RegExp bpkbPattern = RegExp(r'[A-Z][\s\-.]?\d{6,9}');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (line.contains("REGISTRASI") || line.contains("8PKB") || line.contains("BPKB")) {

        String cleanedLine = line.replaceAll(RegExp(r'(REGISTRASI\s*UO|REGISTRASI\s*NO|REGISTRASI|NOMOR|NO\.|NO|BPKB|8PKB|:|-|\s)'), '');

        if (cleanedLine.length > 1) {
          String firstChar = cleanedLine.substring(0, 1);
          String restChars = cleanedLine.substring(1).replaceAll('O', '0');
          cleanedLine = firstChar + restChars;
        }

        var match = bpkbPattern.firstMatch(cleanedLine);

        if (match != null) {
          foundBpkb = match.group(0)!;
          break;
        }
        else if (i + 1 < lines.length) {
          String nextLine = lines[i + 1].replaceAll(RegExp(r'(REGISTRASI|NOMOR|NO|BPKB|8PKB|:|-|\s)'), '');
          if (nextLine.length > 1) {
            nextLine = nextLine.substring(0, 1) + nextLine.substring(1).replaceAll('O', '0');
          }
          var matchNext = bpkbPattern.firstMatch(nextLine);
          if (matchNext != null) {
            foundBpkb = matchNext.group(0)!;
            break;
          }
        }
      }
    }

    if (foundBpkb != null) {
      updateForm("nomor_bpkb", foundBpkb);
      _getController("nomor_bpkb").text = foundBpkb;
    }

    RegExp mesinRegExp = RegExp(r'\b[A-Z0-9\-]{5,15}\b');
    var matches = mesinRegExp.allMatches(textUpper);

    for (var match in matches) {
      String potentialMesin = match.group(0)!;
      String cleanMesin = potentialMesin.replaceAll('-', '');

      if (cleanMesin != foundRangka &&
          (foundBpkb == null || cleanMesin != foundBpkb) &&
          cleanMesin.contains(RegExp(r'[0-9]')) &&
          cleanMesin.contains(RegExp(r'[A-Z]'))) {

        updateForm("nomor_mesin", potentialMesin);
        _getController("nomor_mesin").text = potentialMesin;
        break;
      }
    }

    String? foundNama;
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (line.contains("NAMA") || line.contains("PEMILIK")) {
        String cleanLine = line.replaceAll(RegExp(r'(NAMA\s*PEMILIK|NAMA|PEMILIK)'), '');
        cleanLine = cleanLine.replaceAll(RegExp(r'[:;.\-\_1]'), '').trim();

        if (cleanLine.length > 3 && !cleanLine.contains("ALAMAT")) {
          foundNama = cleanLine;
          break;
        }
        else if (i + 1 < lines.length) {
          String nextLine = lines[i + 1].replaceAll(RegExp(r'[:;.\-\_]'), '').trim();
          if (nextLine.length > 3 && !nextLine.contains("ALAMAT")) {
            foundNama = nextLine;
            break;
          }
        }
      }
    }

    if (foundNama != null) {
      updateForm("nama_pemilik", foundNama);
      _getController("nama_pemilik").text = foundNama;
    }

    if (isStnk) {
      String? finalDateDb;

      RegExp wordDateRegExp = RegExp(r'\b([0-9A-Z]{1,2})\s+([A-Z0-9]{3,10})\s+(\d{4})\b');
      var wordMatch = wordDateRegExp.firstMatch(textUpper);

      if (wordMatch != null) {
        String rawDay = wordMatch.group(1)!;

        String cleanDay = rawDay
            .replaceAll('T', '7')
            .replaceAll('O', '0')
            .replaceAll('Q', '0')
            .replaceAll('S', '5')
            .replaceAll('I', '1')
            .replaceAll('L', '1')
            .replaceAll('Z', '2')
            .replaceAll('B', '8');

        String dd = cleanDay.padLeft(2, '0');
        String wordMonth = wordMatch.group(2)!;
        String yyyy = wordMatch.group(3)!;

        String mm = '01'; // Default

        if (wordMonth.contains('JAN')) mm = '01';
        else if (wordMonth.contains('FEB')) mm = '02';
        else if (wordMonth.contains('MAR')) mm = '03';
        else if (wordMonth.contains('APR')) mm = '04';
        else if (wordMonth.contains('MEI')) mm = '05';
        else if (wordMonth.contains('JUN')) mm = '06';
        else if (wordMonth.contains('JUL')) mm = '07';
        else if (wordMonth.contains('AGU') || wordMonth.contains('AGS')) mm = '08';
        else if (wordMonth.contains('SEP')) mm = '09';
        else if (wordMonth.contains('OKT')) mm = '10';
        else if (wordMonth.contains('NOV')) mm = '11';
        else if (wordMonth.contains('DES')) mm = '12';

        if (int.tryParse(cleanDay) != null) {
          finalDateDb = "$yyyy-$mm-$dd";
        }
      }
      else {
        RegExp numDateRegExp = RegExp(r'\b(\d{2})[-./](\d{2})[-./](\d{4})\b');
        var numMatches = numDateRegExp.allMatches(textUpper);

        if (numMatches.isNotEmpty) {
          String dd = numMatches.first.group(1)!;
          String mm = numMatches.first.group(2)!;
          String yyyy = numMatches.first.group(3)!;
          finalDateDb = "$yyyy-$mm-$dd";
        }
      }

      if (finalDateDb != null) {
        updateForm("pajak_5_tahun", finalDateDb);
        _getController("pajak_5_tahun").text = finalDateDb;
      }
    }

    debugPrint("=====================================");
    debugPrint(rawText);
  }

  @override
  void didUpdateWidget(covariant DokumenPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.formData.forEach((key, value) {
      if (_controllers.containsKey(key)) {
        final controller = _controllers[key]!;
        if (controller.text != (value ?? "")) {
          controller.text = value ?? "";
        }
      }
    });
  }

  // TextEditingController _getController(String key) {
  //   return TextEditingController(
  //     text: widget.formData[key] ?? "",
  //   );
  // }

  void updateForm(String key, dynamic value) {
    setState(() {
      widget.formData[key] = value;
    });
    widget.onChanged(widget.formData);
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Pemeriksaan Dokumen'),

          // ================= STNK =================
          _DokumenCard(
            judulDokumen: 'STNK',
            labelFoto: 'Foto STNK',
            uploadWidget: FotoUploadBox(
              label: 'Upload Foto STNK',
              imageFile: getImage("foto_stnk"),
              onImagePicked: (file) {
                updateForm("foto_stnk", file.path);
                _scanOCR(file.path, isStnk:true);
              },
              onRemove: () {
                updateForm("foto_stnk", null);
                setState(() {});
              },
            ),
            extraFields: [
              _buildDateField('Pajak 1 Tahun', "pajak_1_tahun"),
              _buildDateField('Pajak 5 Tahun', "pajak_5_tahun"),
              _buildTextField('PKB', "pkb"),
              _buildTextField('Nomor Rangka', "nomor_rangka"),
              _buildTextField('Nomor Mesin', "nomor_mesin"),
            ],
          ),

          const SizedBox(height: 12),

          // ================= BPKB =================
          _DokumenCard(
            judulDokumen: 'BPKB',
            labelFoto: 'Foto BPKB',
            uploadWidget: Column(
              children: [
                FotoUploadBox(
                  label: 'Foto BPKB 1',
                  imageFile: getImage("foto_bpkb_1"),
                  onImagePicked: (file) {
                    updateForm("foto_bpkb_1", file.path);
                    setState(() {});
                  },
                  onRemove: () {
                    updateForm("foto_bpkb_1", null);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                FotoUploadBox(
                  label: 'Foto BPKB 2',
                  imageFile: getImage("foto_bpkb_2"),
                  onImagePicked: (file) {
                    updateForm("foto_bpkb_2", file.path);
                    setState(() {});
                  },
                  onRemove: () {
                    updateForm("foto_bpkb_2", null);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                FotoUploadBox(
                  label: 'Foto BPKB 3',
                  imageFile: getImage("foto_bpkb_3"),
                  onImagePicked: (file) {
                    updateForm("foto_bpkb_3", file.path);
                    setState(() {});
                  },
                  onRemove: () {
                    updateForm("foto_bpkb_3", null);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                FotoUploadBox(
                  label: 'Foto BPKB 4',
                  imageFile: getImage("foto_bpkb_4"),
                  onImagePicked: (file) {
                    updateForm("foto_bpkb_4", file.path);
                    setState(() {});
                  },
                  onRemove: () {
                    updateForm("foto_bpkb_4", null);
                    setState(() {});
                  },
                ),
                if (isScanningOcr)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text("Membaca Teks Dokumen...", style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
              ],
            ),
            extraFields: [
              _buildTextField('Nama Pemilik', "nama_pemilik"),
              _buildTextField('Nomor BPKB', "nomor_bpkb"),
              _buildKepemilikanSelector(),

              _buildOptionSelector('SPH', "sph"),
              _buildOptionSelector('Benang Pembatas', "benang_pembatas"),
              _buildOptionSelector('Hologram POLRI', "hologram_polri"),
              _buildOptionSelector('Faktur', "faktur"),
              _buildOptionSelector('NIK', "nik"),
              _buildOptionSelector('Form A', "form_a"),
            ],
          ),

          const SizedBox(height: 12),

          _DokumenCard(
            judulDokumen: 'Dokumen Lainnya',
            labelFoto: '',
            uploadWidget: const SizedBox(), // kosong
            extraFields: [
              _buildOptionSelector('Buku Service', "buku_service"),
              _buildOptionSelector('Buku Manual', "buku_manual"),
              _buildOptionSelector('Cek Logo Scanner', "cek_logo_scanner"),
              _buildOptionSelector('KIR', "kir"),
              _buildOptionSelector('Samsat Online', "samsat_online"),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, String key) {
    final controller = _getController(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );

          if (picked != null) {
            final val = picked.toString().split(" ")[0];
            controller.text = val;
            updateForm(key, val);
          }
        },
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _getController(key),
        onChanged: (val) => updateForm(key, val),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildKepemilikanSelector() {
    final options = ["pribadi", "perusahaan"];
    final selected = widget.formData["kepemilikan_mobil"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Kepemilikan Mobil"),
        const SizedBox(height: 6),

        Row(
          children: options.map((val) {
            final isSelected = selected == val;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    updateForm("kepemilikan_mobil", val);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Text(val.toUpperCase()),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptionSelector(String label, String key) {
    final options = ["ada", "tidak_ada", "rusak"];
    final selected = widget.formData[key];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),

          Row(
            children: options.map((val) {
              final isSelected = selected == val;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      updateForm(key, val);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 16,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          val.replaceAll("_", " ").toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Widget _buildTextField(String label, Function(String) onChanged) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 10),
  //     child: TextField(
  //       onChanged: onChanged,
  //       style: const TextStyle(fontSize: 13),
  //       decoration: InputDecoration(
  //         labelText: label,
  //         filled: true,
  //         fillColor: const Color(0xFFF8F8F8),
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(10),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  //
  // Widget _buildDateField(String label, Function(String) onChanged) {
  //   final controller = TextEditingController();
  //
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 10),
  //     child: TextField(
  //       controller: controller,
  //       readOnly: true,
  //       onTap: () async {
  //         final picked = await showDatePicker(
  //           context: context,
  //           initialDate: DateTime.now(),
  //           firstDate: DateTime(2000),
  //           lastDate: DateTime(2100),
  //         );
  //
  //         if (picked != null) {
  //           final val = picked.toString().split(" ")[0];
  //           controller.text = val;
  //           onChanged(val);
  //         }
  //       },
  //       decoration: InputDecoration(
  //         labelText: label,
  //         suffixIcon: const Icon(Icons.calendar_today),
  //         filled: true,
  //         fillColor: const Color(0xFFF8F8F8),
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(10),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

class _DokumenCard extends StatelessWidget {
  final String judulDokumen;
  final String labelFoto;
  final Widget uploadWidget;
  final List<Widget> extraFields;

  const _DokumenCard({
    required this.judulDokumen,
    required this.labelFoto,
    required this.uploadWidget,
    required this.extraFields,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judulDokumen,
                style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),
            Text(labelFoto),

            const SizedBox(height: 10),
            uploadWidget,

            const SizedBox(height: 14),
            ...extraFields,
          ],
        ),
      ),
    );
  }
}