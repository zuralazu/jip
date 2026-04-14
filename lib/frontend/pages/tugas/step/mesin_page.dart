import 'package:flutter/cupertino.dart';

import '../../../widgets/inspeksi_item_card.dart';
import '../../../widgets/section_header.dart';

class MesinPage extends StatelessWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onChanged; // ✅ TAMBAH

  const MesinPage({
    super.key,
    required this.formData,
    required this.onChanged, // ✅ TAMBAH
  });

  static const List<String> _items = [
    'Bullhead Depan',
    'Bullhead Kiri',
    'Bullhead Kanan',
    'Support Depan Kiri',
    'Support Depan Kanan',
    'Crossbeam Depan',
    'Tiang Vertikal',
    'Kondisi Tampak Mesin',
    'Tutup Pengisian Oli dan Dipstick',
    'Kopling dan Transmisi',
    'Starter',
    'Aki / Baterai',
    'Perangkat Air Conditioner',
    'Hasil Scanner',
    'Knalpot',
  ];

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> mesinData =
    Map<String, dynamic>.from(formData['mesin'] ?? {});

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Pemeriksaan Mesin & Transmisi'),

          ..._items.map((item) {
            return InspeksiItemCard(
              namaItem: item,
              fieldKey: item,          // ✅ penting
              formData: mesinData,     // ✅ kirim data

              onChanged: (value) {     // ✅ tangkap perubahan
                final updatedMesin =
                Map<String, dynamic>.from(mesinData);

                updatedMesin[item] = value;

                final updatedForm =
                Map<String, dynamic>.from(formData);

                updatedForm['mesin'] = updatedMesin;

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