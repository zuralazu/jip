import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/auth_service.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;

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

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final statusCode = response.statusCode;

    print("=== API DEBUG ===");
    print("STATUS: $statusCode");
    print("BODY LENGTH: ${response.body.length}");

    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (e) {
      print("JSON ERROR: $e");

      // 🔥 fallback: jangan langsung gagal
      return {
        "statusCode": statusCode,
        "data": response.body,
      };
    }

    if (statusCode == 401) {
      await AuthService.logout();
      throw Exception("UNAUTHORIZED");
    }

    if (statusCode >= 500) {
      throw Exception("SERVER_ERROR");
    }

    if (statusCode != 200) {
      throw Exception(data["message"] ?? "UNKNOWN_ERROR");
    }

    return {
      "statusCode": statusCode,
      "data": data,
    };
  }

  static Future saveInformasi(int orderId, Map data) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/tugas/$orderId/informasi"),
      headers: {
        "Authorization": "Bearer $token",
      },
      body: data,
    );

    return _handleResponse(response);
  }

  static Future saveDokumen(int orderId, Map data) async {
    final token = await AuthService.getToken();

    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/tugas/$orderId/dokumen"),
    );

    request.headers["Authorization"] = "Bearer $token";

    // 🔥 SEMUA TEXT FIELD
    data.forEach((key, value) {
      if (value != null && !key.contains("foto")) {
        request.fields[key] = value.toString();
      }
    });

    // 🔥 FILE
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

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    return _handleResponse(response);
  }

  static int getItemId(String name) {
    const map = {
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

    return map[name] ?? 0;
  }

  static Future<void> saveInterior(
      int orderId,
      Map<String, dynamic> data,
      ) async {
    final token = await AuthService.getToken();

    final interior = data["interior"] ?? {};

    for (var entry in interior.entries) {
      final itemName = entry.key;
      final itemData = entry.value;

      final itemId = getItemId(itemName); // 🔥 mapping nama ke ID

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/tugas/$orderId/interior/$itemId"),
      );

      request.headers["Authorization"] = "Bearer $token";

      // TEXT
      request.fields["kondisi"] = itemData["kondisi"] ?? "normal";
      request.fields["catatan"] = itemData["catatan"] ?? "";
      request.fields["is_draft"] = "1";

      // FOTO UTAMA
      if (itemData["foto"] != null) {
        request.files.add(await http.MultipartFile.fromPath(
          "foto_utama",
          itemData["foto"],
        ));
      }

      // FOTO TAMBAHAN
      if (itemData["foto_kerusakan"] != null) {
        for (var path in itemData["foto_kerusakan"]) {
          request.files.add(await http.MultipartFile.fromPath(
            "foto_tambahan[]",
            path,
          ));
        }
      }

      final response = await request.send();
      final res = await http.Response.fromStream(response);

      print("ITEM: $itemName");
      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode != 200) {
        throw Exception("Gagal simpan item $itemName");
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