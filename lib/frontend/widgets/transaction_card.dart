import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'status_badge.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const TransactionCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kiri: info transaksi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama_pelanggan'] ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rp. ${item['nominal'] ?? '0'} (${item['metode_bayar'] ?? '-'})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['info_layanan'] ?? '-',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Kanan: Order ID + Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Order ID : #${item['order_id'] ?? '-'}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 6),
              StatusBadge(status: item['status'] ?? ''),
            ],
          ),
        ],
      ),
    );
  }
}