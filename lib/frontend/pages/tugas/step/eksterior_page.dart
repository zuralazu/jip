import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/inspeksi_item_card.dart';

class EksteriorPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onChanged;

  const EksteriorPage({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  @override
  State<EksteriorPage> createState() => _EksteriorPageState();
}

class _EksteriorPageState extends State<EksteriorPage> {

  static const List<String> _items = [
    'Kap Mesin',
    'Bumper Depan',
    'Lampu Depan',
    'Fender Depan Kiri',
    'Fender Depan Kanan',
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
    'Kaca Mobil / Seal',
    'List Plang Bawah',
    'Spion',
  ];

  // 🔥 FALLBACK ID sesuai JSON backend
  static const Map<String, int> fallbackMap = {
    "Kap Mesin": 17,
    "Bumper Depan": 18,
    "Lampu Depan": 19,
    "Fender Depan Kiri": 20,
    "Fender Depan Kanan": 21,
    "Pintu Depan Kiri": 22,
    "Pilar A": 23,
    "Pilar B": 24,
    "Pilar C": 25,
    "Pintu Belakang Kiri": 26,
    "Quarter Kiri": 27,
    "Pintu Bagasi": 28,
    "End Panel": 29,
    "Stop Lamp": 30,
    "Quarter Kanan": 31,
    "Pintu Belakang Kanan": 32,
    "Kaca Mobil / Seal": 33,
    "List Plang Bawah": 34,
    "Spion": 35,
  };

  Map<String, int> itemIdMap = {};

  @override
  void initState() {
    super.initState();
    widget.formData['eksterior'] ??= <String, dynamic>{};
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
            (k) => k["nama_kategori"].toString().toLowerCase().contains("eksterior"),
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

  Map<String, dynamic> get eksteriorData {
    final raw = widget.formData['eksterior'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  void updateItem(String itemName, dynamic value) {
    final updated = Map<String, dynamic>.from(eksteriorData);

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

    widget.formData['eksterior'] = updated;
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
          const SectionHeader(title: 'Pemeriksaan Eksterior'),

          ..._items.map((item) {
            final itemId =
            (itemIdMap[item] ?? fallbackMap[item])?.toString();

            return InspeksiItemCard(
              namaItem: item,
              fieldKey: itemId ?? "temp_$item",
              section: "eksterior",
              formData: eksteriorData,
              onChanged: (val) => updateItem(item, val),
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}