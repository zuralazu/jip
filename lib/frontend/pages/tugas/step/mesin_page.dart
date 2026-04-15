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
            (k) => k["nama_kategori"].toString().toLowerCase().contains("mesin"),
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

  Map<String, dynamic> get mesinData {
    final raw = widget.formData['mesin'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  void updateItem(String itemName, dynamic value) {
    final updated = Map<String, dynamic>.from(mesinData);

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

    widget.formData['mesin'] = updated;
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