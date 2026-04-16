import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../widgets/inspeksi_item_card.dart';
import '../../../widgets/section_header.dart';

class KakiKakiPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onChanged;

  const KakiKakiPage({
    super.key,
    required this.formData,
    required this.onChanged,
  });

  @override
  State<KakiKakiPage> createState() => _KakiKakiPageState();
}

class _KakiKakiPageState extends State<KakiKakiPage> {

  /// 🔥 STATIC UI (TETAP)
  static const List<String> _items = [
    'Rack Stir',
    'Power Steering',
    'Rem',
    'Suspensi',
    'Tahun Ban dan Ketebalan',
    'Ban Serap',
    'Velg',
  ];

  /// 🔥 FALLBACK ID (kalau API gagal)
  static const Map<String, int> fallbackMap = {
    "Rack Stir": 51,
    "Power Steering": 52,
    "Rem": 53,
    "Suspensi": 54,
    "Tahun Ban dan Ketebalan": 55,
    "Ban Serap": 56,
    "Velg": 57,
  };

  /// 🔥 MAP DINAMIS DARI API
  Map<String, int> itemIdMap = {};

  @override
  void initState() {
    super.initState();
    widget.formData['kaki_kaki'] ??= <String, dynamic>{};
    loadItemIds();
  }

  /// 🔥 LOAD DARI API (OPSIONAL, FALLBACK ADA)
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
            (k) => k["nama_kategori"].toString().toLowerCase().contains("kaki"),
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

  /// 🔥 DATA AMAN
  Map<String, dynamic> get kakiKakiData {
    final raw = widget.formData['kaki_kaki'];

    if (raw is Map<String, dynamic>) return raw;

    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }

    return {};
  }

  /// 🔥 UPDATE ITEM (ANTI ERROR + ANTI 500)
  void updateItem(String itemName, dynamic value) {
    final updated = Map<String, dynamic>.from(kakiKakiData);

    final itemId = itemIdMap[itemName] ?? fallbackMap[itemName];

    if (itemId != null) {
      Map<String, dynamic> safeValue;

      if (value is Map) {
        safeValue = Map<String, dynamic>.from(value);
      } else {
        safeValue = {
          "kondisi": "normal",
          "catatan": "",
        };
      }

      updated[itemId.toString()] = safeValue;
    }

    /// 🔥 simpan juga untuk UI preview
    updated[itemName] = value;

    widget.formData['kaki_kaki'] = updated;
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
          const SectionHeader(title: 'Pemeriksaan Kaki-Kaki'),

          ..._items.map((item) {
            final itemId =
            (itemIdMap[item] ?? fallbackMap[item])?.toString();

            final currentData = kakiKakiData;

            final value = (itemId != null && currentData.containsKey(itemId))
                ? currentData[itemId]
                : currentData[item];

            return InspeksiItemCard(
              namaItem: item,
              fieldKey: itemId ?? item,

              section: "kaki_kaki",

              /// 🔥 PENTING: jangan from() tiap render
              formData: kakiKakiData,

              onChanged: (val) => updateItem(item, val),
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}