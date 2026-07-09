import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String noHp,
    required String namaInstansi,
    required String alamat,
    File? logoInstansi,
  }) async {
    var uri = Uri.parse('$baseUrl/register');
    var request = http.MultipartRequest('POST', uri);

    request.headers['Accept'] = 'application/json';

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['no_hp'] = noHp;
    request.fields['nama_instansi'] = namaInstansi;
    request.fields['alamat'] = alamat;
    request.fields['role'] = 'inspektor';

    if (logoInstansi != null) {
      var multipartFile = await http.MultipartFile.fromPath(
        'logo_instansi',
        logoInstansi.path,
      );
      request.files.add(multipartFile);
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> lupaPassword({
    required String email,
    required String password,
    required String confirm_password,
  }) async{
    final url = Uri.parse("$baseUrl/lupa-password");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
        "confirm_password": confirm_password,
      }),
    );
    try {
      final data = jsonDecode(response.body);
      return {
        "statusCode": response.statusCode,
        "data": data,
      };
    } catch (e) {
      return {
        "statusCode": response.statusCode,
        "data": response.body,
      };
    }
  }


  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    print("URL: $url");
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");
    print("BASE_URL: $baseUrl");

    try {
      final data = jsonDecode(response.body);
      return {
        "statusCode": response.statusCode,
        "data": data,
      };
    } catch (e) {
      return {
        "statusCode": response.statusCode,
        "data": response.body,
      };
    }
  }

  static Future<Map<String, dynamic>> logout() async {
    final token = await AuthService.getToken();

    final url = Uri.parse("$baseUrl/logout");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("=== LOGOUT ===");
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    try {
      final data = jsonDecode(response.body);
      return {
        "statusCode": response.statusCode,
        "data": data,
      };
    } catch (e) {
      return {
        "statusCode": response.statusCode,
        "data": response.body,
      };
    }
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final token = await AuthService.getToken();

    final url = Uri.parse("$baseUrl/dashboard");

    print("=== DEBUG DASHBOARD ===");
    print("TOKEN: $token");
    print("URL: $url");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 401) {
        await AuthService.logout();
      }

      return {
        "statusCode": response.statusCode,
        "data": data,
      };
    } catch (e) {
      print("ERROR RESPONSE (NOT JSON): ${response.body}");
      return {
        "statusCode": response.statusCode,
        "data": response.body,
      };
    }
  }

  static Future<Map<String, dynamic>> getTugas() async {
    final token = await AuthService.getToken();

    final url = Uri.parse("$baseUrl/tugas");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("=== TUGAS ===");
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    try {
      final data = jsonDecode(response.body);

      return {
        "statusCode": response.statusCode,
        "data": data,
      };
    } catch (e) {
      return {
        "statusCode": response.statusCode,
        "data": response.body,
      };
    }
  }

  static Future<Map<String, dynamic>> getData() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/dashboard"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse("$baseUrl/profile");

    final token = await AuthService.getToken();

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    try {
      final data = jsonDecode(response.body);
      return {
        "statusCode": response.statusCode,
        "data": data,
      };
    } catch (e) {
      return {
        "statusCode": response.statusCode,
        "data": response.body,
      };
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String noHp,
    required String namaInstansi,
    required String alamat,
    File? logoInstansi,
  }) async {
    final token = await AuthService.getToken();
    var uri = Uri.parse('$baseUrl/profile/update');

    var request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['no_hp'] = noHp;
    request.fields['nama_instansi'] = namaInstansi;
    request.fields['alamat'] = alamat;

    if (logoInstansi != null) {
      var multipartFile = await http.MultipartFile.fromPath(
        'logo_instansi',
        logoInstansi.path,
      );
      request.files.add(multipartFile);
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    return {
      "statusCode": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final statusCode = response.statusCode;

    print("=== API DEBUG ===");
    print("STATUS: $statusCode");
    print("BODY: ${response.body}");

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (e) {
      return {"statusCode": statusCode, "data": response.body};
    }

    if (statusCode == 401) {
      await AuthService.logout(); // hapus token lokal
      throw Exception("UNAUTHORIZED");
    }

    if (statusCode == 422) {
      final errors = data["errors"];
      print("VALIDATION ERRORS: $errors");
      throw Exception("VALIDATION_ERROR: $errors");
    }

    if (statusCode >= 500) {
      // Ambil pesan dari backend kalau ada, fallback ke pesan generik
      final message = (data is Map && data["message"] != null)
          ? data["message"].toString()
          : "Terjadi kesalahan pada server (500).";
      throw Exception(message);
    }

    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(data["message"] ?? "UNKNOWN_ERROR");
    }

    return {"statusCode": statusCode, "data": data};
  }

  static Future<void> _saveOneItem({
    required int orderId,
    required int itemId,
    required String section,
    required String kondisi,
    required String catatan,
    required List<String> fotoUtama,
    required List<String> fotoKerusakan,
  }) async {
    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('$baseUrl/tugas/$orderId/$section-photo/$itemId');

      final localUtama = fotoUtama.where(
            (p) => !p.startsWith('http') && !p.startsWith('data:') && File(p).existsSync(),
      ).toList();
      final localKerusakan = fotoKerusakan.where(
            (p) => !p.startsWith('http') && !p.startsWith('data:') && File(p).existsSync(),
      ).toList();

      debugPrint('▶ ITEM $itemId | kondisi=$kondisi | fotoUtama=${fotoUtama.length} (local=${localUtama.length}) | foto_tambahan=${fotoKerusakan.length} (local=${localKerusakan.length})');

      // Selalu pakai multipart supaya field konsisten
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..fields['status_kondisi'] = kondisi.toLowerCase()
        ..fields['catatan'] = catatan;

      for (final path in localUtama) {
        request.files.add(await http.MultipartFile.fromPath('foto_utama[]', path));
        debugPrint('  ↑ foto_utama[]: $path');
      }
      for (final path in localKerusakan) {
        request.files.add(await http.MultipartFile.fromPath('foto_tambahan[]', path));
        debugPrint('  ↑ foto_tambahan[]: $path');
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed); // ← WAJIB baca body
      debugPrint('✔ ITEM $itemId STATUS: ${response.statusCode}');
      debugPrint('✔ ITEM $itemId BODY: ${response.body}');

      if (response.statusCode >= 500) {
        throw Exception('Server error ${response.statusCode} pada item $itemId: ${response.body}');
      }
      if (response.statusCode == 422) {
        throw Exception('Validasi gagal item $itemId: ${response.body}');
      }

    } catch (e, st) {
      debugPrint('✘ ERROR item $itemId: $e\n$st');
    }
  }

  static Future<Map<String, dynamic>> getInterior(int orderId) async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/tugas/$orderId/interior"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );
    print("=== GET INTERIOR ===");
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getEksterior(int orderId) async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/tugas/$orderId/eksterior"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );
    print("=== GET EKSTERIOR ===");
    print("STATUS: ${response.statusCode}");
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMesin(int orderId) async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/tugas/$orderId/mesin"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );
    print("=== GET MESIN ===");
    print("STATUS: ${response.statusCode}");
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getKakiKaki(int orderId) async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/tugas/$orderId/kaki-kaki"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );
    print("=== GET KAKI-KAKI ===");
    print("STATUS: ${response.statusCode}");
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getKategoriItems() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/master/kategori-item"), // ✅ tanpa 's'
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    print("=== KATEGORI ITEMS ===");
    print("STATUS: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception("Gagal load kategori: ${response.statusCode}");
    }

    final decoded = jsonDecode(response.body);

    // 🔥 FIX: langsung decode, jangan lewat _handleResponse
    final list = decoded["data"];
    if (list is List) return list;
    return [];
  }

  static Future<Map<String, dynamic>> getInformasi(int orderId) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/tugas/$orderId/informasi"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    final result = await _handleResponse(response);

    return result;
  }

  static Future saveInformasi(int orderId, Map data) async {
    final token = await AuthService.getToken();

    // 🔥 DEBUG: lihat data yang dikirim
    print("=== SAVE INFORMASI ===");
    print("ORDER ID: $orderId");
    print("DATA: $data");

    final response = await http.post(
      Uri.parse("$baseUrl/tugas/$orderId/informasi"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",  // 🔥 TAMBAH INI
      },
      body: jsonEncode({
        "nomor_polisi":    data["nomor_polisi"]?.toString() ?? "",
        "tipe_mobil":      data["tipe_mobil"]?.toString() ?? "",
        "transmisi":       data["transmisi"]?.toString() ?? "",
        "kapasitas_mesin": int.tryParse(data["kapasitas_mesin"]?.toString() ?? "0") ?? 0,
        "bahan_bakar":     data["bahan_bakar"]?.toString() ?? "",
        "warna_mobil":     data["warna_mobil"]?.toString() ?? "",
        "jarak_tempuh": int.tryParse(
            (data["jarak_tempuh"]?.toString() ?? "0").replaceAll(',', '')
        ) ?? 0,
      }),
    );

    // 🔥 DEBUG: lihat full response
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return _handleResponse(response);
  }

  static Future saveKesimpulan(int orderId, Map data) async {
    final token = await AuthService.getToken();

    print("=== SAVE KESIMPULAN ===");
    print("ORDER ID: $orderId");
    print("DATA: $data");

    final response = await http.post(
      Uri.parse("$baseUrl/tugas/$orderId/kesimpulan"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "kondisi_tabrak":   data["kondisi_tabrak"]?.toString() ?? "",
        "kondisi_banjir":   data["kondisi_banjir"]?.toString() ?? "",
        "catatan_tambahan": data["catatan_tambahan"]?.toString() ?? "",
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return _handleResponse(response);
  }

  static Future saveDokumen(int orderId, Map data) async {
    final token = await AuthService.getToken();

    print("=== SAVE DOKUMEN ===");
    print("DATA KEYS: ${data.keys.toList()}");
    print("foto_stnk: ${data['foto_stnk']}");
    print("nomor_rangka: ${data['nomor_rangka']}");

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/tugas/$orderId/dokumen-photo"),
    );

    request.headers["Authorization"] = "Bearer $token";
    request.headers["Accept"] = "application/json";

    // Kirim SEMUA text field (termasuk yang kosong sekalipun)
    final textKeys = [
      'pajak_1_tahun', 'pajak_5_tahun', 'pkb', 'nomor_rangka', 'nomor_mesin',
      'nama_pemilik', 'nomor_bpkb', 'kepemilikan_mobil',
      'sph', 'benang_pembatas', 'hologram_polri', 'faktur', 'nik', 'form_a',
      'buku_service', 'buku_manual', 'cek_logo_scanner', 'kir', 'samsat_online',
    ];

    for (var key in textKeys) {
      // Paksa kirim semua field, isi "" kalau null
      request.fields[key] = data[key]?.toString() ?? "";
    }

    Future<void> addFile(String key) async {
      final path = data[key];
      if (path != null && path.toString().isNotEmpty) {
        final file = File(path.toString());
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(key, path));
          print("FILE ADDED: $key → $path");
        } else {
          print("FILE NOT FOUND: $key → $path");
        }
      }
    }

    await addFile("foto_stnk");
    await addFile("foto_bpkb_1");
    await addFile("foto_bpkb_2");
    await addFile("foto_bpkb_3");
    await addFile("foto_bpkb_4");

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getDokumen(int orderId) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/tugas/$orderId/dokumen-photo'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> saveInterior(
      int orderId,
      Map<String, dynamic> formData, {
        bool isFinal = false,
      }) async {
    final sectionData = formData['interior'];
    if (sectionData == null || sectionData is! Map) return {"statusCode": 200};

    // Kumpulkan semua request, jalankan BERSAMAAN
    final futures = <Future>[];

    sectionData.forEach((key, value) {
      final itemId = int.tryParse(key.toString());
      if (itemId == null || value is! Map) return;

      debugPrint('INTERIOR KEY=$key foto_tambahan=${value['foto_tambahan']}');

      futures.add(
        _saveOneItem(
          orderId: orderId,
          itemId: itemId,
          section: 'interior',
          kondisi: value['status_kondisi']?.toString() ?? 'Normal',
          catatan: value['catatan']?.toString() ?? '',
          fotoUtama: value['foto_utama'] is List ? List<String>.from(value['foto_utama']) : [],
          fotoKerusakan: value['foto_tambahan'] is List ? List<String>.from(value['foto_tambahan']) : [],
        ),
      );
    });

    // Semua request jalan bersamaan — total waktu = request TERLAMA, bukan jumlah semua
    await Future.wait(futures, eagerError: false);
    return {"statusCode": 200};
  }

  static Future<Map<String, dynamic>> saveEksterior(
      int orderId,
      Map<String, dynamic> formData, {
        bool isFinal = false,
      }) async {
    final sectionData = formData['eksterior'];
    if (sectionData == null || sectionData is! Map) return {"statusCode": 200};

    // Kumpulkan semua request, jalankan BERSAMAAN
    final futures = <Future>[];

    sectionData.forEach((key, value) {
      final itemId = int.tryParse(key.toString());
      if (itemId == null || value is! Map) return;

      futures.add(
        _saveOneItem(
          orderId: orderId,
          itemId: itemId,
          section: 'eksterior',
          kondisi: value['status_kondisi']?.toString() ?? 'Normal',
          catatan: value['catatan']?.toString() ?? '',
          fotoUtama: value['foto_utama'] is List ? List<String>.from(value['foto_utama']) : [],
          fotoKerusakan: value['foto_tambahan'] is List ? List<String>.from(value['foto_tambahan']) : [],
        ),
      );
    });

    // Semua request jalan bersamaan — total waktu = request TERLAMA, bukan jumlah semua
    await Future.wait(futures, eagerError: false);
    return {"statusCode": 200};
  }

  static Future<Map<String, dynamic>> saveMesin(
      int orderId,
      Map<String, dynamic> formData, {
        bool isFinal = false,
      }) async {
    final sectionData = formData['mesin'];
    if (sectionData == null || sectionData is! Map) return {"statusCode": 200};

    // Kumpulkan semua request, jalankan BERSAMAAN
    final futures = <Future>[];

    sectionData.forEach((key, value) {
      final itemId = int.tryParse(key.toString());
      if (itemId == null || value is! Map) return;

      futures.add(
        _saveOneItem(
          orderId: orderId,
          itemId: itemId,
          section: 'mesin',
          kondisi: value['status_kondisi']?.toString() ?? 'Normal',
          catatan: value['catatan']?.toString() ?? '',
          fotoUtama: value['foto_utama'] is List ? List<String>.from(value['foto_utama']) : [],
          fotoKerusakan: value['foto_tambahan'] is List ? List<String>.from(value['foto_tambahan']) : [],
        ),
      );
    });

    // Semua request jalan bersamaan — total waktu = request TERLAMA, bukan jumlah semua
    await Future.wait(futures, eagerError: false);
    return {"statusCode": 200};
  }

  static Future<Map<String, dynamic>> saveKakiKaki(
      int orderId,
      Map<String, dynamic> formData, {
        bool isFinal = false,
      }) async {
    final sectionData = formData['kaki_kaki'];
    if (sectionData == null || sectionData is! Map) return {"statusCode": 200};

    // Kumpulkan semua request, jalankan BERSAMAAN
    final futures = <Future>[];

    sectionData.forEach((key, value) {
      final itemId = int.tryParse(key.toString());
      if (itemId == null || value is! Map) return;

      futures.add(
        _saveOneItem(
          orderId: orderId,
          itemId: itemId,
          section: 'kaki-kaki',
          kondisi: value['status_kondisi']?.toString() ?? 'Normal',
          catatan: value['catatan']?.toString() ?? '',
          fotoUtama: value['foto_utama'] is List ? List<String>.from(value['foto_utama']) : [],
          fotoKerusakan: value['foto_tambahan'] is List ? List<String>.from(value['foto_tambahan']) : [],
        ),
      );
    });

    // Semua request jalan bersamaan — total waktu = request TERLAMA, bukan jumlah semua
    await Future.wait(futures, eagerError: false);
    return {"statusCode": 200};
  }

  static Future<Map<String, dynamic>> tambahPesanan(Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();

    final url = Uri.parse("$baseUrl/tambah-inspeksi");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
      body: jsonEncode(payload),
    );

    print("=== TAMBAH PESANAN ===");
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> saveDraftInspeksi(
      Map<String, dynamic> data) async {

    final token = await AuthService.getToken();

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/tugas/${data['order_id']}/dokumen"),
    );

    request.headers["Authorization"] = "Bearer $token";

    // 🔥 TEXT FIELD
    data.forEach((key, value) {
      if (value != null && value is! String) {
        request.fields[key] = value.toString();
      } else if (value != null && !key.contains("foto")) {
        request.fields[key] = value;
      }
    });

    // 🔥 FILE FIELD
    Future<void> addFile(String key) async {
      if (data[key] != null && data[key].toString().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          key,
          data[key],
        ));
      }
    }

    await addFile("foto_stnk");
    await addFile("foto_bpkb_1");
    await addFile("foto_bpkb_2");
    await addFile("foto_bpkb_3");
    await addFile("foto_bpkb_4");

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  static Future submitFinal(int orderId) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/tugas/$orderId/selesai"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> submitInspeksi(
      Map<String, dynamic> data) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/inspeksi/submit"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getSlipKomisi() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/komisi'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('=== SLIP KOMISI ===');
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    try {
      final data = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'data': data,
      };
    } catch (e) {
      return {
        'statusCode': response.statusCode,
        'data': response.body,
      };
    }
  }

  static Future<Map<String, dynamic>> getDetailKomisi(int komisiId) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/komisi/$komisiId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('=== DETAIL KOMISI ===');
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    try {
      final data = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'data': data,
      };
    } catch (e) {
      return {
        'statusCode': response.statusCode,
        'data': response.body,
      };
    }
  }

  static Future<Map<String, dynamic>> selesaikanKomisi({
    required int slipId,
    required String metodeBayar,
    File? buktiImage, // ✅ tambahan opsional
  }) async {
    final token = await AuthService.getToken();

    // Pakai multipart supaya bisa kirim file
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/komisi/$slipId/selesai'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['metode_pembayaran'] = metodeBayar;

    // Kirim gambar hanya kalau ada
    if (buktiImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'bukti_pembayaran', // sesuaikan dengan key yang diminta backend
        buktiImage.path,
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    print('=== SELESAIKAN KOMISI ===');
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getDetailTugas(int orderId) async {
    final token = await AuthService.getToken();

    final url = Uri.parse('$baseUrl/tugas/detail/$orderId');

    print("=== DETAIL TUGAS ===");
    print("URL: $url");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    return _handleResponse(response);
  }

  static Future<String> downloadLaporanPdf(int orderId, String namaFile) async {
    final token = await AuthService.getToken();
    final url = '$baseUrl/laporan/$orderId/pdf?token=$token';

    // 1. Download PDF
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Gagal mengunduh PDF (status ${response.statusCode})');
    }

    // 2. Bersihkan nama file
    final cleanName = namaFile
        .replaceAll(RegExp(r'[^\w\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    // 3. Simpan ke folder Downloads publik
    Directory? saveDir;

    if (Platform.isAndroid) {
      // Folder Downloads yang terlihat di Files app
      saveDir = Directory('/storage/emulated/0/Download');
      if (!await saveDir.exists()) {
        saveDir = await getExternalStorageDirectory();
      }
    } else {
      // iOS: simpan ke Documents
      saveDir = await getApplicationDocumentsDirectory();
    }

    final filePath = '${saveDir!.path}/$cleanName.pdf';

    // 4. Tulis file
    await File(filePath).writeAsBytes(response.bodyBytes);

    return filePath;
  }

  static Future<Map<String, dynamic>> getKerusakanLainnya(int orderId) async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/tugas/$orderId/kerusakan-lainnya'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    debugPrint('=== GET KERUSAKAN LAINNYA ===');
    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> storeKerusakanLainnya({
    required int orderId,
    required String namaKerusakan,
    String? deskripsi,
    String tingkatKerusakan = 'ringan',
    List<File> fotos = const [],
  }) async {
    final token = await AuthService.getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/tugas/$orderId/kerusakan-lainnya'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['nama_kerusakan']    = namaKerusakan;
    request.fields['deskripsi']         = deskripsi ?? '';
    request.fields['tingkat_kerusakan'] = tingkatKerusakan;

    for (int i = 0; i < fotos.length; i++) {
      if (await fotos[i].exists()) {
        request.files.add(await http.MultipartFile.fromPath('foto[]', fotos[i].path));
        debugPrint('  ↑ foto[$i]: ${fotos[i].path}');
      }
    }

    debugPrint('=== STORE KERUSAKAN LAINNYA ===');
    debugPrint('order_id: $orderId | nama: $namaKerusakan | tingkat: $tingkatKerusakan | fotos: ${fotos.length}');

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateKerusakanLainnya({
    required int orderId,
    required int id,
    required String namaKerusakan,
    String? deskripsi,
    String tingkatKerusakan = 'ringan',
    List<File> fotos = const [],
  }) async {
    final token = await AuthService.getToken();

    // Backend pakai POST + /update karena tidak ada method PATCH di route
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/tugas/$orderId/kerusakan-lainnya/$id/update'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['nama_kerusakan']    = namaKerusakan;
    request.fields['deskripsi']         = deskripsi ?? '';
    request.fields['tingkat_kerusakan'] = tingkatKerusakan;

    for (int i = 0; i < fotos.length; i++) {
      if (await fotos[i].exists()) {
        request.files.add(await http.MultipartFile.fromPath('foto[]', fotos[i].path));
        debugPrint('  ↑ foto[$i]: ${fotos[i].path}');
      }
    }

    debugPrint('=== UPDATE KERUSAKAN LAINNYA ===');
    debugPrint('order_id: $orderId | id: $id | nama: $namaKerusakan | fotos: ${fotos.length}');

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteKerusakanLainnya(
      int orderId, int id) async {
    final token = await AuthService.getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/tugas/$orderId/kerusakan-lainnya/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    return _handleResponse(response);
  }
}