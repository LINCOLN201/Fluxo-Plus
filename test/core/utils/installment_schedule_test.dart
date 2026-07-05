import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/utils/installment_schedule.dart';

void main() {
  test('gera vencimentos mensais preservando o dia quando possível', () {
    final dates = InstallmentSchedule.dueDates(DateTime(2026, 1, 31), 3);

    expect(dates, [
      DateTime(2026, 1, 31),
      DateTime(2026, 2, 28),
      DateTime(2026, 3, 31),
    ]);
  });

  test('gera a quantidade exata de parcelas', () {
    final dates = InstallmentSchedule.dueDates(DateTime(2026, 7, 6), 12);

    expect(dates, hasLength(12));
    expect(dates.first, DateTime(2026, 7, 6));
    expect(dates.last, DateTime(2027, 6, 6));
  });
}
