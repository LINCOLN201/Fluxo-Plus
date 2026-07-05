import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/shared/models/category.dart';
import 'package:fluxo_plus/shared/models/finance_transaction.dart';

void main() {
  test('mantém status e informações do parcelamento no SQLite', () {
    final transaction = FinanceTransaction(
      id: 7,
      type: TransactionType.expense,
      amount: 125,
      categoryId: 2,
      accountId: 1,
      date: DateTime(2026, 7, 7),
      description: 'Notebook',
      createdAt: DateTime(2026, 7, 5),
      isPaid: false,
      installmentGroup: 'compra-1',
      installmentNumber: 2,
      installmentCount: 10,
    );

    final restored = FinanceTransaction.fromMap(transaction.toMap());

    expect(restored.name, 'Notebook');
    expect(restored.isPaid, isFalse);
    expect(restored.installmentNumber, 2);
    expect(restored.installmentCount, 10);
    expect(restored.installmentTotal, 1250);
  });
}
