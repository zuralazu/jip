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

  Future<void> loadItemIds() async {
    try {
      final kategori = await ApiService.getKategoriItems();

      if (kategori.isEmpty) return;

      // 🔥 FIX: pakai for loop biasa, hindari firstWhere dengan orElse null
      Map<String, dynamic>? targetKategori;
      for (final k in kategori) {
        if (k is Map && k["nama_kategori"].toString().toLowerCase().contains("interior")) {
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
        // ✅ FIX: Eksplisit ambil tiap field, bukan Map.from() langsung
        safeValue = {
          "kondisi": value["status_kondisi"]?.toString() ?? "normal",
          "catatan": value["catatan"]?.toString() ?? "",
          "foto": value["foto"],
          "foto_kerusakan": value["foto_kerusakan"],
        };
      } else {
        safeValue = {
          "kondisi": "normal",
          "catatan": "",
          "foto": null,
          "foto_kerusakan": null,
        };
      }

      updated[itemId.toString()] = safeValue;
      print("INTERIOR UPDATE: $itemName → ID $itemId → kondisi=${safeValue['kondisi']}");
    }

    updated[itemName] = value;

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