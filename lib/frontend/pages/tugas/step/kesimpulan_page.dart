import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../widgets/section_header.dart';

class KesimpulanPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onChanged;
  final Map<String, String> validationErrors;

  const KesimpulanPage({
    super.key,
    required this.formData,
    required this.onChanged,
    this.validationErrors = const {},
  });

  @override
  State<KesimpulanPage> createState() => _KesimpulanPageState();
}

class _KesimpulanPageState extends State<KesimpulanPage> {
  late final TextEditingController _kesimpulanController;

  @override
  void initState() {
    super.initState();
    _kesimpulanController = TextEditingController(
      text: widget.formData['catatan_tambahan']?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant KesimpulanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newVal = widget.formData['catatan_tambahan']?.toString() ?? '';
    if (_kesimpulanController.text != newVal) {
      _kesimpulanController.text = newVal;
    }
  }

  @override
  void dispose() {
    _kesimpulanController.dispose();
    super.dispose();
  }

  void _updateForm(String key, String value) {
    widget.formData[key] = value;
    widget.onChanged(Map<String, dynamic>.from(widget.formData));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Kesimpulan Inspeksi'),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Kondisi Tabrak ──────────────────────────────────────
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

                // ── Kondisi Banjir ──────────────────────────────────────
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

                // ── Kesimpulan ──────────────────────────────────────────
                _buildTextArea(),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Chip selector ─────────────────────────────────────────────────────────
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
          // Label
          Row(
            children: [
              Icon(icon, size: 16, color: hasError ? Colors.red.shade400 : AppColors.textGrey),
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

          // Chips
          Row(
            children: List.generate(options.length, (i) {
              final option = options[i];
              final isSelected = currentValue == option;
              final activeColor = activeColors[i];

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    _updateForm(key, option);
                    setState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
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
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

          // Error
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

  // ── Textarea kesimpulan ───────────────────────────────────────────────────
  Widget _buildTextArea() {
    final hasError = widget.validationErrors.containsKey('catatan_tambahan');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(
                Icons.notes_rounded,
                size: 16,
                color: hasError ? Colors.red.shade400 : AppColors.textGrey,
              ),
              const SizedBox(width: 6),
              Text(
                'Kesimpulan Keseluruhan',
                style: TextStyle(
                  fontSize: 13,
                  color: hasError ? Colors.red : AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        TextField(
          controller: _kesimpulanController,
          onChanged: (val) => _updateForm('catatan_tambahan', val),
          maxLines: 5,
          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Tulis kesimpulan hasil inspeksi di sini...',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            errorText: widget.validationErrors['catatan_tambahan'],
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
      ],
    );
  }
}