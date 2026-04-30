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

                // ── Kondisi Tabrak ──────────────────────────────────────────
                _buildConditionSelector(
                  label: 'Kondisi Tabrak',
                  key: 'kondisi_tabrak',
                  icon: Icons.car_crash_outlined,
                  options: const ['Bebas Tabrak', 'Tabrak Ringan', 'Tabrak Berat'],
                  activeColors: const [
                    Color(0xFF4CAF50),
                    Color(0xFFFFA726),
                    Color(0xFFF44336),
                  ],
                  icons: const [
                    Icons.check_circle_outline,
                    Icons.warning_amber_outlined,
                    Icons.dangerous_outlined,
                  ],
                ),

                // ── Kondisi Banjir ──────────────────────────────────────────
                _buildConditionSelector(
                  label: 'Kondisi Banjir',
                  key: 'kondisi_banjir',
                  icon: Icons.water_outlined,
                  options: const ['Bebas Banjir', 'Banjir Ringan', 'Banjir Berat'],
                  activeColors: const [
                    Color(0xFF4CAF50),
                    Color(0xFFFFA726),
                    Color(0xFFF44336),
                  ],
                  icons: const [
                    Icons.check_circle_outline,
                    Icons.water_damage_outlined,
                    Icons.flood_outlined,
                  ],
                ),

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

  // ── NEW: Visual condition chip selector ───────────────────────────────────
  Widget _buildConditionSelector({
    required String label,
    required String key,
    required IconData icon,
    required List<String> options,
    required List<Color> activeColors,
    required List<IconData> icons,
  }) {
    final hasError = widget.validationErrors.containsKey(key);
    final errorMsg = widget.validationErrors[key];
    final currentValue = widget.formData[key]?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: hasError ? Colors.red.shade400 : AppColors.textGrey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: hasError ? Colors.red : AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Chip row
          Row(
            children: List.generate(options.length, (i) {
              final option = options[i];
              final isSelected = currentValue == option;
              final activeColor = activeColors[i];

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    updateForm(key, option);
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      right: i < options.length - 1 ? 6 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor.withOpacity(0.12)
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? activeColor
                            : hasError
                            ? Colors.red.shade300
                            : Colors.grey.shade300,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons[i],
                          size: 20,
                          color: isSelected ? activeColor : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? activeColor : AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          // Error message
          if (hasError && errorMsg != null)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 4),
              child: Text(
                errorMsg,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade700,
                ),
              ),
            ),
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