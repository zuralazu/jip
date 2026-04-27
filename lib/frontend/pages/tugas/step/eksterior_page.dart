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
    'Foto Depan Kendaraan',
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

  Future<void> loadItemIds() async {
    try {
      final kategori = await ApiService.getKategoriItems();

      if (kategori.isEmpty) return;

      // 🔥 FIX: pakai for loop biasa, hindari firstWhere dengan orElse null
      Map<String, dynamic>? targetKategori;
      for (final k in kategori) {
        if (k is Map && k["nama_kategori"].toString().toLowerCase().contains("eksterior")) {
          // ganti "interior" sesuai page: "eksterior", "mesin", "kaki"
          targetKategori = Map<String, dynamic>.from(k);
          break;
        }
      }

      if (targetKategori == null) {
        print("KATEGORI TIDAK DITEMUKAN, pakai fallback");
        return;
      }

      final Map<String, int> tempMap = {};
      final daftarItem = targetKategori["daftar_item"];

      if (daftarItem is List) {
        for (final item in daftarItem) {
          if (item is Map) {
            tempMap[item["nama_item"].toString()] = item["item_id"] as int;
          }
        }
      }

      print("ITEM ID MAP LOADED: ${tempMap.length} items");
      setState(() => itemIdMap = tempMap);

    } catch (e) {
      print("ERROR LOAD ITEM IDS: $e");
      // fallbackMap otomatis dipakai
    }
  }

  Map<String, dynamic> get eksteriorData {
    final raw = widget.formData['eksterior'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  void updateItem(String itemName, dynamic value) {
    final updated = Map<String, dynamic>.from(eksteriorData); // ganti sesuai section

    final itemId = itemIdMap[itemName] ?? fallbackMap[itemName];

    if (itemId != null) {
      Map<String, dynamic> safeValue;

      if (value is Map) {
        // ✅ FIX: salin SEMUA field dari value termasuk foto_utama
        safeValue = {
          "status_kondisi": value["status_kondisi"]?.toString() ?? "Normal",
          "catatan": value["catatan"]?.toString() ?? "",
          "foto_utama": value["foto_utama"] ?? [],        // ← list multi foto
          "foto": value["foto"],                          // ← backward compat
          "foto_kerusakan": value["foto_kerusakan"] ?? [],
        };
      } else {
        safeValue = {
          "status_kondisi": "Normal",
          "catatan": "",
          "foto_utama": [],
          "foto": null,
          "foto_kerusakan": [],
        };
      }

      updated[itemId.toString()] = safeValue;
    }

    updated[itemName] = value; // untuk UI preview

    widget.formData['eksterior'] = updated; // ganti sesuai section: 'eksterior', 'mesin', 'kaki_kaki'
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