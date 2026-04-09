import 'package:flutter/material.dart';
import '../utils/colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'proses':
        bgColor   = AppColors.yellow;
        textColor = AppColors.primary;
        icon      = Icons.access_time_rounded;
        label     = 'Proses';
        break;
      case 'cair':
        bgColor   = AppColors.primary;
        textColor = Colors.white;
        icon      = Icons.check_circle_outline_rounded;
        label     = 'Cair';
        break;
      case 'hasil inspeksi':
        bgColor   = AppColors.green;
        textColor = Colors.white;
        icon      = Icons.assignment_turned_in_outlined;
        label     = 'Hasil Inspeksi';
        break;
      default:
        bgColor   = Colors.grey.shade300;
        textColor = Colors.black54;
        icon      = Icons.help_outline;
        label     = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}