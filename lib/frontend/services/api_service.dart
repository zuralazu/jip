import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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
      await AuthService.logout();
      throw Exception("UNAUTHORIZED");
    }

    if (statusCode == 422) {
      // 🔥 Tampilkan field mana yang gagal validasi
      final errors = data["errors"];
      print("VALIDATION ERRORS: $errors");
      throw Exception("VALIDATION_ERROR: $errors");
    }

    if (statusCode >= 500) {
      throw Exception("SERVER_ERROR");
    }

    if (statusCode != 200) {
      throw Exception(data["message"] ?? "UNKNOWN_ERROR");
    }

    return {"statusCode": statusCode, "data": data};
  }

  static Future<List<dynamic>> getKategoriItems() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/master/kategori-items"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json", // 🔥 TAMBAH INI
      },
    );

    print("=== KATEGORI ITEMS ===");
    print("STATUS: ${response.statusCode}");
    print("URL: $baseUrl/master/kategori-items");

    if (response.statusCode != 200) {
      throw Exception("Gagal load kategori: ${response.statusCode}");
    }

    final result = await _handleResponse(response);
    return result["data"]["data"];
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
        "jarak_tempuh":    int.tryParse(data["jarak_tempuh"]?.toString() ?? "0") ?? 0,
        "kondisi_tabrak":  data["kondisi_tabrak"]?.toString() ?? "",
        "kondisi_banjir":  data["kondisi_banjir"]?.toString() ?? "",
        "catatan_tambahan": data["catatan_tambahan"]?.toString() ?? "",
      }),
    );

    // 🔥 DEBUG: lihat full response
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
      Uri.parse("$baseUrl/tugas/$orderId/dokumen"),
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
      Uri.parse('$baseUrl/tugas/$orderId/dokumen'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  static Future<void> saveInterior(
      int orderId,
      Map<String, dynamic> data, {bool isFinal = false,}
      ) async {

    final token = await AuthService.getToken();

    final interior = data["interior"] ?? {};

    for (var entry in interior.entries) {
      final itemId = entry.key;

      // 🔥 skip kalau bukan angka
      if (int.tryParse(itemId) == null) continue;

      final itemData = entry.value;

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/tugas/$orderId/interior/$itemId"),
      );

      request.headers["Authorization"] = "Bearer $token";

      request.fields["kondisi"] = itemData["kondisi"] ?? "normal";
      request.fields["catatan"] = itemData["catatan"] ?? "";
      request.fields["is_draft"] = isFinal ? "0" : "1";

      if (itemData["foto"] != null && itemData["foto"].toString().isNotEmpty){
        request.files.add(await http.MultipartFile.fromPath(
          "foto_utama",
          itemData["foto"],
        ));
      }

      if (itemData["foto_kerusakan"] != null) {
        for (var path in itemData["foto_kerusakan"]) {
          request.files.add(await http.MultipartFile.fromPath(
            "foto_tambahan[]",
            path,
          ));
        }
      }

      final res = await http.Response.fromStream(await request.send());

      print("INTERIOR ITEM ID: $itemId");
      print("STATUS: ${res.statusCode}");

      if (res.statusCode != 200) {
        throw Exception("Gagal simpan interior item $itemId");
      }
    }
  }

  static Future<void> saveEksterior(
      int orderId,
      Map<String, dynamic> data,{bool isFinal = false,}
      ) async {
    final token = await AuthService.getToken();

    final eksterior = data["eksterior"] ?? {};

    for (var entry in eksterior.entries) {
      final itemId = entry.key;

      // ❗ WAJIB: skip kalau masih temp
      if (int.tryParse(itemId) == null) continue;

      final itemData = entry.value;

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/tugas/$orderId/eksterior/$itemId"),
      );

      request.headers["Authorization"] = "Bearer $token";

      request.fields["kondisi"] = itemData["kondisi"] ?? "normal";
      request.fields["catatan"] = itemData["catatan"] ?? "";
      request.fields["is_draft"] = isFinal ? "0" : "1";

      if (itemData["foto"] != null && itemData["foto"].toString().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          "foto_utama",
          itemData["foto"],
        ));
      }

      if (itemData["foto_kerusakan"] != null) {
        for (var path in itemData["foto_kerusakan"]) {
          request.files.add(await http.MultipartFile.fromPath(
            "foto_tambahan[]",
            path,
          ));
        }
      }

      final res = await http.Response.fromStream(await request.send());

      print("EKSTERIOR ITEM ID: $itemId");
      print("STATUS: ${res.statusCode}");

      if (res.statusCode != 200) {
        throw Exception("Gagal simpan eksterior item $itemId");
      }
    }
  }

  static Future<void> saveMesin(
      int orderId,
      Map<String, dynamic> data, {bool isFinal = false,}
      ) async {
    final token = await AuthService.getToken();

    final mesin = data["mesin"] ?? {};

    for (var entry in mesin.entries) {
      final itemId = entry.key;

      // ❗ skip kalau bukan angka (biar gak kirim "Bullhead Depan")
      if (int.tryParse(itemId) == null) continue;

      final itemData = entry.value;

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/tugas/$orderId/mesin/$itemId"),
      );

      request.headers["Authorization"] = "Bearer $token";

      request.fields["kondisi"] = itemData["kondisi"] ?? "normal";
      request.fields["catatan"] = itemData["catatan"] ?? "";
      request.fields["is_draft"] = isFinal ? "0" : "1";

      if (itemData["foto"] != null && itemData["foto"].toString().isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          "foto_utama",
          itemData["foto"],
        ));
      }

      if (itemData["foto_kerusakan"] != null) {
        for (var path in itemData["foto_kerusakan"]) {
          request.files.add(await http.MultipartFile.fromPath(
            "foto_tambahan[]",
            path,
          ));
        }
      }

      final res = await http.Response.fromStream(await request.send());

      print("MESIN ITEM ID: $itemId");
      print("STATUS: ${res.statusCode}");

      if (res.statusCode != 200) {
        throw Exception("Gagal simpan mesin item $itemId");
      }
    }
  }

  static Future<void> saveKakiKaki(
      int orderId,
      Map<String, dynamic> data, {bool isFinal = false,}
      ) async {
    final token = await AuthService.getToken();

    final kaki = data["kaki_kaki"] ?? {};

    for (var entry in kaki.entries) {
      final itemId = entry.key;

      if (int.tryParse(itemId) == null) continue;

      final itemData = entry.value;

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/tugas/$orderId/kaki-kaki/$itemId"),
      );

      request.headers["Authorization"] = "Bearer $token";

      request.fields["kondisi"] = itemData["kondisi"] ?? "normal";
      request.fields["catatan"] = itemData["catatan"] ?? "";
      request.fields["is_draft"] = isFinal ? "0" : "1";

      if (itemData["foto"] != null && itemData["foto"].toString().isNotEmpty){
        request.files.add(await http.MultipartFile.fromPath(
          "foto_utama",
          itemData["foto"],
        ));
      }

      if (itemData["foto_kerusakan"] != null) {
        for (var path in itemData["foto_kerusakan"]) {
          request.files.add(await http.MultipartFile.fromPath(
            "foto_tambahan[]",
            path,
          ));
        }
      }

      final res = await http.Response.fromStream(await request.send());

      print("KAKI KAKI ITEM ID: $itemId");
      print("STATUS: ${res.statusCode}");

      if (res.statusCode != 200) {
        throw Exception("Gagal simpan kaki-kaki item $itemId");
      }
    }
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
}