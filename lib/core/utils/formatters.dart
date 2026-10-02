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
    final cleaned = input.replaceAll(RegExp(r'[^\d,.]'), '');
    if (cleaned.isEmpty) return null;
    final hasComma = cleaned.contains(',');
    final hasDot = cleaned.contains('.');
    if (hasComma && hasDot) {
      // BR format "1.234,56": dots are thousands, comma is decimal.
      return double.tryParse(cleaned.replaceAll('.', '').replaceAll(',', '.'));
    }
    if (hasComma) {
      // Comma-only decimal "29,90".
      return double.tryParse(cleaned.replaceAll(',', '.'));
    }
    // No comma: dot could be decimal ("1.50" from non-BR keyboard) or
    // thousands ("1.234"). Use position heuristic: <= 2 digits after the
    // last dot → decimal; >= 3 → thousands separator.
    final dotIndex = cleaned.lastIndexOf('.');
    if (dotIndex == -1) return double.tryParse(cleaned);
    final afterDot = cleaned.length - dotIndex - 1;
    if (afterDot > 2) {
      return double.tryParse(cleaned.replaceAll('.', ''));
    }
    return double.tryParse(cleaned);
  }
}
