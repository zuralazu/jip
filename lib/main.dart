import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:jip/frontend/pages/profile/profile.dart';
import 'package:jip/frontend/pages/slip-komisi/slip_komisi_page.dart';

import 'frontend/pages/dashboard/dashboard_page.dart';
import 'frontend/pages/splash/splash_page.dart';
import 'frontend/pages/login/login_page.dart';
import 'frontend/pages/tugas/pesanan/tambah_pesanan_page.dart';
import 'frontend/pages/tugas/tugas_page.dart';
import 'frontend/pages/main/main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await FlutterDownloader.initialize(debug: true);
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JIM APP',
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        // '/dashboard':    (context) => const DashboardPage(),
        // '/tugas':        (context) => const TugasPage(),
        // '/profile':      (context) => const ProfilePage(),
        '/main': (context) => const MainPage(),
        '/tambah-pesanan': (context) => const TambahPesananPage(),
        '/slip-komisi': (context) => const SlipKomisiPage(),
      },
    );
  }
}