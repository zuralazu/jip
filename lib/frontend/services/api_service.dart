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
}