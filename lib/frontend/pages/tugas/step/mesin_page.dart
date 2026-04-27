import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../widgets/inspeksi_item_card.dart';
import '../../../widgets/section_header.dart';

class MesinPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onChanged;

  const MesinPage({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  @override
  State<MesinPage> createState() => _MesinPageState();
}

class _MesinPageState extends State<MesinPage> {

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
    'Aki/Baterai',
    'Perangkat Air Condisioner',
    'Hasil Scanner',
    'Knalpot',
  ];

  // 🔥 FALLBACK ID sesuai JSON backend (perhatikan typo di backend: "Condisioner", "Aki/Baterai")
  static const Map<String, int> fallbackMap = {
    "Bullhead Depan": 36,
    "Bullhead Kiri": 37,
    "Bullhead Kanan": 38,
    "Support Depan Kiri": 39,
    "Support Depan Kanan": 40,
    "Crossbeam Depan": 41,
    "Tiang Vertikal": 42,
    "Kondisi Tampak Mesin": 43,
    "Tutup Pengisian Oli dan Dipstick": 44,
    "Kopling dan Transmisi": 45,
    "Starter": 46,
    "Aki/Baterai": 47,
    "Perangkat Air Condisioner": 48,
    "Hasil Scanner": 49,
    "Knalpot": 50,
  };

  Map<String, int> itemIdMap = {};

  @override
  void initState() {
    super.initState();
    widget.formData['mesin'] ??= <String, dynamic>{};
    loadItemIds();
  }

  Future<void> loadItemIds() async {
    try {
      final kategori = await ApiService.getKategoriItems();

      if (kategori.isEmpty) return;

      // 🔥 FIX: pakai for loop biasa, hindari firstWhere dengan orElse null
      Map<String, dynamic>? targetKategori;
      for (final k in kategori) {
        if (k is Map && k["nama_kategori"].toString().toLowerCase().contains("mesin")) {
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

  Map<String, dynamic> get mesinData {
    final raw = widget.formData['mesin'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  void updateItem(String itemName, dynamic value) {
    final updated = Map<String, dynamic>.from(mesinData); // ganti sesuai section

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

    widget.formData['mesin'] = updated; // ganti sesuai section: 'eksterior', 'mesin', 'kaki_kaki'
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
          const SectionHeader(title: 'Pemeriksaan Mesin & Transmisi'),

          ..._items.map((item) {
            final itemId =
            (itemIdMap[item] ?? fallbackMap[item])?.toString();

            return InspeksiItemCard(
              namaItem: item,
              fieldKey: itemId ?? "temp_$item",
              section: "mesin",
              formData: mesinData,
              onChanged: (val) => updateItem(item, val),
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}