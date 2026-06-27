import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/utils/formatters.dart';

void main() {
  group('AppFormatters', () {
    test('interpreta valor brasileiro', () {
      expect(AppFormatters.parseCurrency('R\$ 1.234,56'), 1234.56);
    });

    test('rejeita valor vazio', () {
      expect(AppFormatters.parseCurrency(''), isNull);
    });

    test('formata data brasileira', () {
      expect(AppFormatters.date(DateTime(2026, 6, 26)), '26/06/2026');
    });
  });
}
