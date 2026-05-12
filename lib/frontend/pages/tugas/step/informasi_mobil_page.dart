import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/colors.dart';
import '../../../widgets/section_header.dart';

// ── Formatter: 1000 → 1,000 ──────────────────────────────────────────────────
class _ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Strip all non-digit characters
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    // Format with commas
    final formatted = _addCommas(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _addCommas(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromRight = digits.length - 1 - i;
      if (i != 0 && posFromRight % 3 == 2) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

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
      controllers[key] = TextEditingController(text: value?.toString() ?? '');
    }
    return controllers[key]!;
  }

  @override
  void didUpdateWidget(covariant InformasiMobilPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.formData.forEach((key, value) {
      if (controllers.containsKey(key)) {
        final controller = controllers[key]!;
        final newVal = value?.toString() ?? '';
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
                // ── Free-text fields ──────────────────────────────────────
                _buildField(
                  'Nomor Polisi',
                  'nomor_polisi',
                  Icons.confirmation_number_outlined,
                ),
                _buildField(
                  'Tipe',
                  'tipe_mobil',
                  Icons.directions_car_outlined,
                ),

                // ── Transmisi selector ────────────────────────────────────
                _buildConditionSelector(
                  label: 'Transmisi',
                  key: 'transmisi',
                  icon: Icons.settings_outlined,
                  options: const ['Automatic', 'Manual'],
                  activeColors: const [
                    Color(0xFF1E88E5),
                    Color(0xFF8E24AA),
                  ],
                  icons: const [
                    Icons.auto_mode_outlined,
                    Icons.tune_outlined,
                  ],
                ),

                // ── Kapasitas Mesin (plain number) ────────────────────────
                _buildField(
                  'Kapasitas Mesin (cc)',
                  'kapasitas_mesin',
                  Icons.speed_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),

                // ── Jenis Bahan Bakar selector ────────────────────────────
                _buildConditionSelector(
                  label: 'Jenis Bahan Bakar',
                  key: 'bahan_bakar',
                  icon: Icons.local_gas_station_outlined,
                  options: const ['Solar', 'Bensin'],
                  activeColors: const [
                    Color(0xFF00897B),
                    Color(0xFFFB8C00),
                  ],
                  icons: const [
                    Icons.opacity_outlined,
                    Icons.local_fire_department_outlined,
                  ],
                ),

                // ── Warna ─────────────────────────────────────────────────
                _buildField(
                  'Warna',
                  'warna_mobil',
                  Icons.palette_outlined,
                ),

                // ── Jarak Tempuh (formatted: 1,300) ───────────────────────
                _buildField(
                  'Jarak Tempuh (km)',
                  'jarak_tempuh',
                  Icons.straighten_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_ThousandSeparatorFormatter()],
                ),

                // kondisi_tabrak, kondisi_banjir, dan kesimpulan
                // dipindahkan ke KesimpulanPage (step terakhir)
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Visual condition / option chip selector ───────────────────────────────
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
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
                          color:
                          isSelected ? activeColor : Colors.grey.shade400,
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
                            color:
                            isSelected ? activeColor : AppColors.textGrey,
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
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
            ),
        ],
      ),
    );
  }

  // ── Text field (with optional formatters) ─────────────────────────────────
  Widget _buildField(
      String label,
      String key,
      IconData icon, {
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
      }) {
    final hasError = widget.validationErrors.containsKey(key);
    final errorMsg = widget.validationErrors[key];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _getController(key),
        onChanged: (val) => updateForm(key, val),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
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
          fillColor:
          hasError ? Colors.red.shade50 : const Color(0xFFF8F8F8),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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

  // ── Multi-line text area with label title ─────────────────────────────────
  Widget _buildTextArea(String title, String key) {
    final hasError = widget.validationErrors.containsKey(key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title label above the text area
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: hasError ? Colors.red : AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextField(
            controller: _getController(key),
            onChanged: (val) => updateForm(key, val),
            maxLines: 3,
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Tulis kesimpulan di sini...',
              hintStyle:
              TextStyle(fontSize: 13, color: Colors.grey.shade400),
              errorText: widget.validationErrors[key],
              filled: true,
              fillColor:
              hasError ? Colors.red.shade50 : const Color(0xFFF8F8F8),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
        ],
      ),
    );
  }
}