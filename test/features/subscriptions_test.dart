import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/features/transactions/data/transaction_repository.dart';
import 'package:fluxo_plus/shared/models/category.dart';
import 'package:fluxo_plus/shared/models/finance_transaction.dart';

import '../support/test_database.dart';

/// Assinaturas usam a mesma engrenagem de lançamentos recorrentes
/// ([TransactionRepository.createRecurring]/[TransactionRepository
/// .stopRecurring]) — [TransactionRepository.listActiveSubscriptions] só
/// filtra pela categoria "Assinaturas" (criada por padrão desde o schema v5)
/// e resume cada grupo pela próxima cobrança pendente.
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

  FinanceTransaction subscription(
    String name,
    double amount,
    DateTime date,
    int category,
  ) =>
      FinanceTransaction(
        type: TransactionType.expense,
        amount: amount,
        categoryId: category,
        accountId: 1,
        date: date,
        description: name,
        createdAt: date,
        isPaid: false,
      );

  test('lista só assinaturas da categoria "Assinaturas"', () async {
    final subscriptions = await categoryId('Assinaturas');
    final other = await categoryId('Lazer');
    final today = DateTime.now();

    await transactions.createRecurring(
      subscription('Netflix', 39.9, today, subscriptions),
    );
    await transactions.createRecurring(
      subscription('Academia', 99.9, today, other),
    );

    final active = await transactions.listActiveSubscriptions();
    expect(active, hasLength(1));
    expect(active.single.description, 'Netflix');
    expect(active.single.amount, 39.9);
  });

  test('soma o valor de várias assinaturas ativas', () async {
    final category = await categoryId('Assinaturas');
    final today = DateTime.now();

    await transactions.createRecurring(
      subscription('Netflix', 39.9, today, category),
    );
    await transactions.createRecurring(
      subscription('Spotify', 21.9, today, category),
    );

    final active = await transactions.listActiveSubscriptions();
    final total = active.fold<double>(0, (sum, item) => sum + item.amount);
    expect(active, hasLength(2));
    expect(total, closeTo(61.8, 0.001));
  });

  test('cancelar assinatura remove da lista de ativas', () async {
    final category = await categoryId('Assinaturas');
    final today = DateTime.now();

    await transactions.createRecurring(
      subscription('Netflix', 39.9, today, category),
    );
    final group =
        (await transactions.listActiveSubscriptions()).single.recurringGroup;

    await transactions.stopRecurring(group);

    expect(await transactions.listActiveSubscriptions(), isEmpty);
  });
}
