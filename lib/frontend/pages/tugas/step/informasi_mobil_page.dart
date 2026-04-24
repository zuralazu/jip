import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../widgets/section_header.dart';

class InformasiMobilPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, String> validationErrors;

  const InformasiMobilPage({
    super.key,
    required this.formData,
    required this.onChanged,
    this.validationErrors = const {},
  });

  @override
  State<InformasiMobilPage> createState() => _InformasiMobilPageState();
}

class _InformasiMobilPageState extends State<InformasiMobilPage> {
  final Map<String, TextEditingController> controllers = {};

  void updateForm(String key, String value) {
    widget.formData[key] = value;
    widget.onChanged(Map<String, dynamic>.from(widget.formData));
  }

  TextEditingController _getController(String key) {
    if (!controllers.containsKey(key)) {
      final value = widget.formData[key];
      controllers[key] = TextEditingController(text: value?.toString() ?? "");
    }
    return controllers[key]!;
  }

  @override
  void didUpdateWidget(covariant InformasiMobilPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.formData.forEach((key, value) {
      if (controllers.containsKey(key)) {
        final controller = controllers[key]!;
        final newVal = value?.toString() ?? "";
        if (controller.text != newVal) {
          controller.text = newVal;
        }
      }
    });
  }

  @override
  void dispose() {
    for (var c in controllers.values) {
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
          const SectionHeader(title: 'Informasi Kendaraan'),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
            child: Column(
              children: [
                _buildField('Nomor Polisi', 'nomor_polisi', Icons.confirmation_number_outlined),
                _buildField('Tipe', 'tipe_mobil', Icons.directions_car_outlined),
                _buildField('Transmisi', 'transmisi', Icons.settings_outlined),
                _buildField('Kapasitas Mesin', 'kapasitas_mesin', Icons.speed_outlined, keyboardType: TextInputType.number),
                _buildField('Jenis Bahan Bakar', 'bahan_bakar', Icons.local_gas_station_outlined),
                _buildField('Warna', 'warna_mobil', Icons.palette_outlined),
                _buildField('Jarak Tempuh', 'jarak_tempuh', Icons.straighten_outlined, keyboardType: TextInputType.number),
                _buildField('Kondisi Tabrak', 'kondisi_tabrak', Icons.car_crash_outlined),
                _buildField('Kondisi Banjir', 'kondisi_banjir', Icons.water_outlined),
                const SizedBox(height: 4),
                _buildTextArea('Catatan Tambahan', 'catatan_tambahan'),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildField(String label, String key, IconData icon, {TextInputType? keyboardType}) {
    final hasError = widget.validationErrors.containsKey(key);
    final errorMsg = widget.validationErrors[key];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _getController(key),
        onChanged: (val) => updateForm(key, val),
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13,
            color: hasError ? Colors.red : AppColors.textGrey,
          ),
          prefixIcon: Icon(
            icon,
            size: 18,
            color: hasError ? Colors.red.shade300 : AppColors.textGrey,
          ),
          errorText: errorMsg,
          errorStyle: const TextStyle(fontSize: 11),
          filled: true,
          fillColor: hasError ? Colors.red.shade50 : const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: hasError ? Colors.red : AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea(String hint, String key) {
    final hasError = widget.validationErrors.containsKey(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _getController(key),
        onChanged: (val) => updateForm(key, val),
        maxLines: 3,
        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          errorText: widget.validationErrors[key],
          filled: true,
          fillColor: hasError ? Colors.red.shade50 : const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.shade300),
          ),
        ),
      ),
    );
  }
}