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

  static const List<String> _items = [
    'Rack Stir',
    'Power Steering',
    'Rem',
    'Suspensi',
    'Tahun Ban dan Ketebalan',
    'Ban Serap',
    'Velg',
  ];

  // ✅ Fallback ID — semua 7 item (51–57)
  static const Map<String, int> fallbackMap = {
    "Rack Stir": 51,
    "Power Steering": 52,
    "Rem": 53,
    "Suspensi": 54,
    "Tahun Ban dan Ketebalan": 55,
    "Ban Serap": 56,
    "Velg": 57,
  };

  Map<String, int> itemIdMap = {};

  @override
  void initState() {
    super.initState();
    widget.formData['kaki_kaki'] ??= <String, dynamic>{};
    loadItemIds();
  }

  Future<void> loadItemIds() async {
    try {
      final kategori = await ApiService.getKategoriItems();

      if (kategori.isEmpty) {
        print("KATEGORI KOSONG, pakai fallback kaki-kaki");
        return;
      }

      // ✅ FIX Bug 3: Gunakan for-loop biasa, BUKAN firstWhere dengan orElse: () => null
      // firstWhere di Dart tidak bisa return null untuk tipe non-nullable,
      // menyebabkan exception yang membuat itemIdMap tetap kosong,
      // sehingga hanya item yang ID-nya kebetulan sudah ada yang tersimpan.
      Map<String, dynamic>? targetKategori;
      for (final k in kategori) {
        if (k is Map && k["nama_kategori"].toString().toLowerCase().contains("kaki")) {
          targetKategori = Map<String, dynamic>.from(k);
          break;
        }
      }

      if (targetKategori == null) {
        print("KATEGORI KAKI TIDAK DITEMUKAN, pakai fallback");
        return; // fallbackMap akan dipakai otomatis di updateItem
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

      print("KAKI-KAKI ITEM ID MAP: ${tempMap.length} items → $tempMap");
      setState(() => itemIdMap = tempMap);

    } catch (e) {
      print("ERROR LOAD KAKI-KAKI ITEM IDS: $e — menggunakan fallback");
      // fallbackMap otomatis dipakai di updateItem & build
    }
  }

  Map<String, dynamic> get kakiKakiData {
    final raw = widget.formData['kaki_kaki'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  void updateItem(String itemName, dynamic value) {
    final updated = Map<String, dynamic>.from(kakiKakiData);

    // ✅ Selalu pakai fallbackMap sebagai backup kalau itemIdMap belum loaded
    final itemId = itemIdMap[itemName] ?? fallbackMap[itemName];

    if (itemId != null) {
      Map<String, dynamic> safeValue;

      if (value is Map) {
        // ✅ FIX Bug 2: Eksplisit ambil setiap field dari Map
        // Bukan Map.from() yang kadang tidak preserve tipe dengan benar
        safeValue = {
          "kondisi": value["kondisi"]?.toString() ?? "normal",
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

      // Simpan dengan key numeric ID → yang dikirim ke backend
      updated[itemId.toString()] = safeValue;
      print("KAKI UPDATE: $itemName → ID $itemId → kondisi=${safeValue['kondisi']}");
    } else {
      print("WARNING: ID tidak ditemukan untuk item '$itemName'");
    }

    // Simpan juga dengan nama untuk UI preview
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
            // ✅ Selalu fallback ke fallbackMap — tidak akan pernah null untuk item yang terdaftar
            final itemId = (itemIdMap[item] ?? fallbackMap[item])?.toString();

            return InspeksiItemCard(
              namaItem: item,
              fieldKey: itemId ?? item,
              section: "kaki_kaki",
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