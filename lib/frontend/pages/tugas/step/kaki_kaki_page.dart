import 'package:flutter/cupertino.dart';

import '../../../widgets/inspeksi_item_card.dart';
import '../../../widgets/section_header.dart';

class KakiKakiPage extends StatelessWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onChanged; // ✅ tambah

  const KakiKakiPage({
    super.key,
    required this.formData,
    required this.onChanged, // ✅ tambah
  });

  static const List<String> _items = [
    'Rack Stir',
    'Power Steering',
    'Rem',
    'Suspensi',
    'Tahun Ban dan Ketebalan',
    'Ban Serap',
    'Velg',
  ];

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> kakiKakiData =
    Map<String, dynamic>.from(formData['kaki_kaki'] ?? {});

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Pemeriksaan Kaki-Kaki'),

          ..._items.map((item) {
            return InspeksiItemCard(
              namaItem: item,
              fieldKey: item,            // ✅ penting
              formData: kakiKakiData,    // ✅ kirim data

              onChanged: (value) {
                final updatedKakiKaki =
                Map<String, dynamic>.from(kakiKakiData);

                updatedKakiKaki[item] = value;

                final updatedForm =
                Map<String, dynamic>.from(formData);

                updatedForm['kaki_kaki'] = updatedKakiKaki;

                onChanged(updatedForm); // ✅ kirim ke parent
              },
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}