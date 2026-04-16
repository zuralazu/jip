import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jip/frontend/pages/profile/profile.dart';
import 'frontend/pages/dashboard/dashboard_page.dart';
import 'frontend/pages/splash/splash_page.dart';
import 'frontend/pages/login/login_page.dart';
import 'frontend/pages/tugas/pesanan/tambah_pesanan_page.dart';
import 'frontend/pages/tugas/tugas_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // 🔥 LOAD ENV

  print("ENV BASE_URL: ${dotenv.env['BASE_URL_DEV']}");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JIM Pekanbaru',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/dashboard':    (context) => const DashboardPage(),
        '/tugas':        (context) => const TugasPage(),
        '/profile':      (context) => const ProfilePage(),
        '/tambah-pesanan': (context) => const TambahPesananPage(),
      },
    );
  }
}