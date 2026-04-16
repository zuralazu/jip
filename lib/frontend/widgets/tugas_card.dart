import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pages/tugas/detail_inspeksi_page.dart';
import '../utils/colors.dart';

class TugasCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onNavigateBack;

  const TugasCard({super.key, required this.item, this.onNavigateBack,});

  void _launchWhatsApp(String noHp) async {
    final phone = noHp.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = phone.startsWith('0') ? '62${phone.substring(1)}' : phone;
    final uri = Uri.parse('https://wa.me/$formatted');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _launchWeb(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String namaMobil     = item['nama_mobil']       ?? '-';
    final String tanggal       = item['tanggal_waktu']          ?? '-';
    final String jam           = item['jam']                    ?? '';
    final String status        = item['status']           ?? 'Proses Inspeksi';
    final String namaPelanggan = item['nama_pelanggan']   ?? '-';
    final String noHp          = item['no_hp_pelanggan']  ?? '';
    final String lokasi        = item['lokasi_inspeksi']  ?? '-';
    final String paket         = item['paket_layanan']            ?? '-';
    final String urlLaporan    = item['url_laporan']      ?? '';
    final String urlWeb        = item['url_web']          ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── NAMA MOBIL + BADGE STATUS ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    namaMobil,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: status),
              ],
            ),
          ),

          // ── TANGGAL & JAM ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppColors.textGrey,
                ),
                const SizedBox(width: 5),
                Text(
                  jam.isNotEmpty ? '$tanggal' : tanggal,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),

          // ── INFO PELANGGAN ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Pelanggan :',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: AppColors.textGrey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            namaPelanggan,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tombol WhatsApp
                if (noHp.isNotEmpty)
                  GestureDetector(
                    onTap: () => _launchWhatsApp(noHp),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Hubungi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),

          // ── LOKASI & PAKET ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lokasi Inspeksi :',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lokasi,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paket :',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      paket,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── TOMBOL ISI LAPORAN ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailInspeksiPage(dataTugas: item, orderId: item['order_id'],),
                    ),
                  ).then((_) {
                    onNavigateBack?.call(); // 🔥 panggil callback setelah balik
                  });
                },
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                label: const Text(
                  'Isi Laporan Inspeksi',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          // ── TOMBOL WEB ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDDDDDD)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: urlWeb.isNotEmpty
                    ? () => _launchWeb(urlWeb)
                    : null,
                icon: const Icon(
                  Icons.language_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                label: const Text(
                  'Web',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge status ───────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case 'proses inspeksi':
        bg = AppColors.yellow;
        fg = AppColors.primary;
        break;
      case 'selesai':
        bg = const Color(0xFFE6F9F0);
        fg = const Color(0xFF1A9E5C);
        break;
      case 'batal':
        bg = const Color(0xFFFFEEEE);
        fg = Colors.red;
        break;
      default:
        bg = const Color(0xFFF0F0F0);
        fg = AppColors.textGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}