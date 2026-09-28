import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/features/dashboard/data/dashboard_repository.dart';
import 'package:fluxo_plus/features/transactions/data/transaction_repository.dart';
import 'package:fluxo_plus/shared/models/category.dart';
import 'package:fluxo_plus/shared/models/finance_transaction.dart';

import '../support/test_database.dart';

/// O Dashboard tinha um seletor de mês que só mostrava o mês atual e não
/// fazia nada ao tocar — quem lançava uma conta com vencimento num mês
/// diferente via o resumo sempre zerado, sem nenhum jeito de conferir
/// aquele outro mês. Estes testes cobrem a camada de dados por trás do
/// seletor de mês agora funcional.
void main() {
  late TestDatabase opened;
  late TransactionRepository transactions;
  late DashboardRepository dashboard;

  setUp(() async {
    opened = await TestDatabase.open();
    transactions = TransactionRepository(opened.database);
    dashboard = DashboardRepository(opened.database);
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

  test('resumo do mês só soma lançamentos daquele mês', () async {
    final food = await categoryId('Alimentação');
    await transactions.create(FinanceTransaction(
      type: TransactionType.expense,
      amount: 50,
      categoryId: food,
      accountId: 1,
      date: DateTime(2026, 9, 15),
      description: 'Setembro',
      createdAt: DateTime(2026, 9, 15),
    ));
    await transactions.create(FinanceTransaction(
      type: TransactionType.expense,
      amount: 120,
      categoryId: food,
      accountId: 1,
      date: DateTime(2026, 10, 7),
      description: 'Outubro',
      createdAt: DateTime(2026, 10, 7),
    ));

    final september = await dashboard.load(DateTime(2026, 9));
    expect(september.monthExpense, 50);

    final october = await dashboard.load(DateTime(2026, 10));
    expect(october.monthExpense, 120);
  });
}
