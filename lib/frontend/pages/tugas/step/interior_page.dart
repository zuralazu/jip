import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
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

  // 🔥 FALLBACK ID sesuai JSON backend
  static const Map<String, int> fallbackMap = {
    "Dashboard": 1,
    "Stir": 2,
    "Handle Porsneling": 3,
    "Doortrim": 4,
    "Speedometer": 5,
    "Kolong Stir": 6,
    "Jok dan Kolong Jok": 7,
    "Karpet": 8,
    "Plafon dan Pilar": 9,
    "Headunit": 10,
    "Door Lock": 11,
    "Power Window": 12,
    "Elektrik Spion": 13,
    "AC": 14,
    "Airbag": 15,
    "Sun Roof / Moon Roof": 16,
  };

  Map<String, int> itemIdMap = {};

  @override
  void initState() {
    super.initState();
    widget.formData['interior'] ??= <String, dynamic>{};
    loadItemIds();
  }

  // ✅ Contoh di KakiKakiPage
  Future<void> loadItemIds() async {
    try {
      final kategori = await ApiService.getKategoriItems();

      // 🔥 Pastikan list of Map, bukan list of String
      if (kategori.isEmpty || kategori.first is! Map) {
        print("KATEGORI DATA TIDAK VALID, pakai fallback");
        return; // langsung pakai fallbackMap
      }

      final kakiKategori = kategori.firstWhere(
            (k) => k["nama_kategori"].toString().toLowerCase().contains("interior"),
        orElse: () => null, // 🔥 jangan crash
      );

      if (kakiKategori == null) {
        print("KATEGORI KAKI TIDAK DITEMUKAN, pakai fallback");
        return;
      }

      final Map<String, int> tempMap = {};
      for (var item in kakiKategori["daftar_item"]) {
        tempMap[item["nama_item"]] = item["item_id"];
      }

      setState(() => itemIdMap = tempMap);

    } catch (e) {
      print("ERROR LOAD KAKI-KAKI: $e");
      // fallbackMap otomatis dipakai di build()
    }
  }

  Map<String, dynamic> get interiorData {
    final raw = widget.formData['interior'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  void updateItem(String itemName, dynamic value) {
    final updated = Map<String, dynamic>.from(interiorData);

    final itemId = itemIdMap[itemName] ?? fallbackMap[itemName];

    if (itemId != null) {
      Map<String, dynamic> safeValue;
      if (value is Map) {
        safeValue = Map<String, dynamic>.from(value);
      } else {
        safeValue = {"kondisi": "normal", "catatan": ""};
      }
      updated[itemId.toString()] = safeValue;
    }

    widget.formData['interior'] = updated;
    widget.onChanged(widget.formData);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Pemeriksaan Interior'),

          ..._items.map((item) {
            final itemId =
            (itemIdMap[item] ?? fallbackMap[item])?.toString();

            return InspeksiItemCard(
              namaItem: item,
              fieldKey: itemId ?? "temp_$item",
              section: "interior",
              formData: interiorData,
              onChanged: (val) => updateItem(item, val),
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}