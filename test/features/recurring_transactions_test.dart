import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/features/transactions/data/transaction_repository.dart';
import 'package:fluxo_plus/shared/models/finance_transaction.dart';

import '../support/test_database.dart';

/// Lançamentos recorrentes (aluguel, assinaturas, salário) — diferente de
/// parcelas (quantidade fixa e conhecida), uma recorrência não tem fim: o
/// grupo é completado aos poucos por [TransactionRepository
/// .extendRecurringOccurrences] conforme o tempo passa, em vez de gerar
/// anos de lançamentos de uma vez só.
void main() {
  late TestDatabase opened;
  late TransactionRepository transactions;

  setUp(() async {
    opened = await TestDatabase.open();
    transactions = TransactionRepository(opened.database);
  });
  tearDown(() => opened.dispose());

  Future<int> categoryId(String name) async {
    final rows = await opened.database.db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
    );
    return rows.single['id'] as int;
  }

  FinanceTransaction rent(DateTime date, int category, {bool isPaid = true}) =>
      FinanceTransaction(
        type: TransactionType.expense,
        amount: 1500,
        categoryId: category,
        accountId: 1,
        date: date,
        description: 'Aluguel',
        createdAt: date,
        isPaid: isPaid,
      );

  test('cria as próximas ocorrências mensais vinculadas ao mesmo grupo',
      () async {
    final housing = await categoryId('Moradia');
    final today = DateTime.now();
    final ids = await transactions.createRecurring(
      rent(today, housing),
      monthsAhead: 12,
    );
    expect(ids, hasLength(12));

    final all = await transactions.list();
    expect(all, hasLength(12));
    final groups = all.map((item) => item.transaction.recurringGroup).toSet();
    expect(groups, hasLength(1));
    expect(groups.single, isNotNull);

    final months = all.map((item) => item.transaction.date.month).toSet();
    expect(months, hasLength(12));
  });

  test(
      'só a primeira ocorrência nasce com o status pago informado, '
      'as demais ficam pendentes', () async {
    final housing = await categoryId('Moradia');
    await transactions.createRecurring(
      rent(DateTime.now(), housing, isPaid: true),
      monthsAhead: 3,
    );
    final all = await transactions.list();
    final paid = all.where((item) => item.transaction.isPaid);
    expect(paid, hasLength(1));
    final earliest = all
        .map((item) => item.transaction.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    expect(paid.single.transaction.date, earliest);
  });

  test('completa o horizonte quando está perto de acabar', () async {
    final housing = await categoryId('Moradia');
    await transactions.createRecurring(
      rent(DateTime.now(), housing),
      monthsAhead: 2,
    );
    expect(await transactions.list(), hasLength(2));

    await transactions.extendRecurringOccurrences(
      monthsAhead: 12,
      refillThreshold: 3,
    );

    final all = await transactions.list();
    expect(all.length, greaterThan(2));
    final lastDate = all
        .map((item) => item.transaction.date)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final elevenMonthsFromNow = DateTime(
      DateTime.now().year,
      DateTime.now().month + 11,
    );
    expect(lastDate.isAfter(elevenMonthsFromNow), isTrue);
  });

  test('não completa quando o horizonte ainda está longe de acabar', () async {
    final housing = await categoryId('Moradia');
    await transactions.createRecurring(
      rent(DateTime.now(), housing),
      monthsAhead: 12,
    );
    await transactions.extendRecurringOccurrences(
      monthsAhead: 12,
      refillThreshold: 3,
    );
    expect(await transactions.list(), hasLength(12));
  });

  test(
      'parar de repetir apaga só as ocorrências futuras pendentes, '
      'mantém o histórico', () async {
    final housing = await categoryId('Moradia');
    await transactions.createRecurring(
      rent(DateTime.now(), housing, isPaid: true),
      monthsAhead: 6,
    );
    final all = await transactions.list();
    final group = all.first.transaction.recurringGroup!;

    await transactions.stopRecurring(group);

    final remaining = await transactions.list();
    expect(remaining, hasLength(1));
    expect(remaining.single.transaction.isPaid, isTrue);
  });
}
