import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../widgets/section_header.dart';

class InformasiMobilPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onChanged;

  const InformasiMobilPage({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  @override
  State<InformasiMobilPage> createState() => _InformasiMobilPageState();
}

class _InformasiMobilPageState extends State<InformasiMobilPage> {
  final Map<String, TextEditingController> controllers = {};

  void updateForm(String key, String value) {
    widget.formData[key] = value;
    widget.onChanged(widget.formData);
  }

  TextEditingController _getController(String key) {
    if (!controllers.containsKey(key)) {
      controllers[key] = TextEditingController(
        text: widget.formData[key] ?? "",
      );
    }
    return controllers[key]!;
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
                _buildField('Kapasitas Mesin', 'kapasitas_mesin', Icons.speed_outlined),
                _buildField('Jenis Bahan Bakar', 'bahan_bakar', Icons.local_gas_station_outlined),
                _buildField('Warna', 'warna_mobil', Icons.palette_outlined),
                _buildField('Jarak Tempuh', 'jarak_tempuh', Icons.straighten_outlined),
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

  Widget _buildField(String label, String key, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _getController(key),
        onChanged: (val) => updateForm(key, val),
        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: AppColors.textGrey),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textGrey),
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea(String hint, String key) {
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
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}