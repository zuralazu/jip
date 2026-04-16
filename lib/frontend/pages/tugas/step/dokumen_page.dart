import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/foto_upload_box.dart';

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
                setState(() {});
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