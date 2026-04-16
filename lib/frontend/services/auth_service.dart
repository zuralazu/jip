import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }

  static Future<String> getUserId() async {
    // sesuaikan dengan key yang kamu pakai saat login & simpan data
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id') ?? '';
  }
}