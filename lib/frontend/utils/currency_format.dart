import 'package:intl/intl.dart';

class CurrencyFormat {
  static String toRupiah(dynamic value) {
    if (value == null) return 'Rp 0';
    final number = int.tryParse(value.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }
}