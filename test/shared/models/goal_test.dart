import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/shared/models/goal.dart';

void main() {
  test('calcula e limita o progresso da meta', () {
    final goal = Goal(
      name: 'Reserva',
      targetAmount: 1000,
      currentAmount: 1250,
      createdAt: DateTime(2026),
    );

    expect(goal.progress, 1);
  });

  test('meta sem valor alvo não divide por zero', () {
    final goal = Goal(
      name: 'Rascunho',
      targetAmount: 0,
      currentAmount: 100,
      createdAt: DateTime(2026),
    );

    expect(goal.progress, 0);
  });
}
