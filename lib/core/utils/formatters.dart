import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 2,
  );
  static final _date = DateFormat('dd/MM/yyyy');

  static String currency(double value) => _currency.format(value);
  static String date(DateTime value) => _date.format(value);

  static double? parseCurrency(String input) {
    final normalized = input
        .replaceAll(RegExp(r'[^\d,.-]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(normalized);
  }
}
