import 'package:flutter/material.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/inspeksi_item_card.dart';

class InteriorPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onChanged;

  const InteriorPage({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  @override
  State<InteriorPage> createState() => _InteriorPageState();
}

class _InteriorPageState extends State<InteriorPage> {

  static const List<String> _items = [
    'Dashboard',
    'Stir',
    'Handle Porsneling',
    'Doortrim',
    'Speedometer',
    'Kolong Stir',
    'Jok dan Kolong Jok',
    'Karpet',
    'Plafon dan Pilar',
    'Headunit',
    'Door Lock',
    'Power Window',
    'Elektrik Spion',
    'AC',
    'Airbag',
    'Sun Roof / Moon Roof',
  ];

  Map<String, dynamic> get interiorData {
    return Map<String, dynamic>.from(widget.formData['interior'] ?? {});
  }

  void updateItem(String item, dynamic value) {
    final updatedInterior = Map<String, dynamic>.from(interiorData);
    updatedInterior[item] = value;

    widget.formData['interior'] = updatedInterior;
    widget.onChanged(widget.formData);

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    widget.formData['interior'] ??= <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    final data = interiorData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Pemeriksaan Interior'),

          ..._items.map((item) {
            return InspeksiItemCard(
              namaItem: item,

              // ✅ WAJIB INI
              formData: Map<String, dynamic>.from(
                widget.formData['interior'] ?? {},
              ),

              // ✅ KEY PER ITEM
              fieldKey: item,

              onChanged: (value) {
                final currentInterior = Map<String, dynamic>.from(
                  widget.formData['interior'] ?? {},
                );

                currentInterior[item] = value;

                widget.formData['interior'] = currentInterior;
                widget.onChanged(widget.formData);

                setState(() {});
              },
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}