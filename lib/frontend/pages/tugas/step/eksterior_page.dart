import 'package:flutter/material.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/inspeksi_item_card.dart';

class EksteriorPage extends StatelessWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onChanged;

  const EksteriorPage({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  static const List<String> _items = [
    'Kap Mesin',
    'Bumper Depan',
    'Lampu Depan',
    'Fender Depan Kiri',
    'Pintu Depan Kiri',
    'Pilar A',
    'Pilar B',
    'Pilar C',
    'Pintu Belakang Kiri',
    'Quarter Kiri',
    'Pintu Bagasi',
    'End Panel',
    'Stop Lamp',
    'Quarter Kanan',
    'Pintu Belakang Kanan',
    'Pintu Depan Kanan',
    'Fender Depan Kanan',
    'Kaca Mobil / Seal',
    'List Plang Bawah',
    'Spion',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Pemeriksaan Eksterior'),

          ..._items.map((item) {
            final key = item.toLowerCase().replaceAll(" ", "_");

            return InspeksiItemCard(
              namaItem: item,
              formData: formData,
              fieldKey: "eksterior_$key",
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}