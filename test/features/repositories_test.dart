import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/features/accounts/data/account_repository.dart';
import 'package:fluxo_plus/features/categories/data/category_repository.dart';
import 'package:fluxo_plus/features/goals/data/goal_repository.dart';
import 'package:fluxo_plus/features/reports/data/report_repository.dart';
import 'package:fluxo_plus/features/transactions/data/transaction_repository.dart';
import 'package:fluxo_plus/shared/models/category.dart';
import 'package:fluxo_plus/shared/models/finance_transaction.dart';
import 'package:fluxo_plus/shared/models/goal.dart';

import '../support/test_database.dart';

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

  FinanceTransaction expense(double amount, DateTime date, int category) =>
      FinanceTransaction(
        type: TransactionType.expense,
        amount: amount,
        categoryId: category,
        accountId: 1,
        date: date,
        description: 'Despesa',
        createdAt: date,
      );

  test('primeiro uso cria conta principal e 11 categorias padrão', () async {
    expect(await transactions.getAccounts(), hasLength(1));
    expect(await transactions.getAllCategories(), hasLength(11));
  });

  test('parcelas geram vencimentos mensais e só a primeira pode estar paga',
      () async {
    final food = await categoryId('Alimentação');
    await transactions.createInstallments(
      expense(100.1, DateTime(2026, 1, 31), food),
      3,
    );
    final all = await transactions.list();
    expect(all, hasLength(3));
    final paid = all.where((item) => item.transaction.isPaid);
    expect(paid, hasLength(1));
    expect(paid.single.transaction.installmentNumber, 1);
    expect(
      all.map((item) => item.transaction.date.month).toSet(),
      {1, 2, 3},
    );
  });

  test('relatório soma centavos exatamente', () async {
    final food = await categoryId('Alimentação');
    for (var i = 0; i < 10; i++) {
      await transactions.create(expense(0.1, DateTime(2026, 9, 3), food));
    }
    final report =
        await ReportRepository(opened.database).load(DateTime(2026, 9));
    expect(report.expense, 1.0);
    expect(report.categories.single.amount, 1.0);
    expect(report.transactionCount, 10);
  });

  test('filtros por mês e status', () async {
    final food = await categoryId('Alimentação');
    await transactions.create(expense(10, DateTime(2026, 8, 30), food));
    final pending = expense(20, DateTime(2026, 9, 2), food);
    await transactions.create(
      FinanceTransaction(
        type: pending.type,
        amount: pending.amount,
        categoryId: pending.categoryId,
        accountId: pending.accountId,
        date: pending.date,
        description: pending.description,
        createdAt: pending.createdAt,
        isPaid: false,
      ),
    );
    expect(await transactions.list(month: DateTime(2026, 9)), hasLength(1));
    expect(
      await transactions.list(payment: PaymentFilter.pending),
      hasLength(1),
    );
  });

  test('contas e categorias em uso não podem ser excluídas', () async {
    final food = await categoryId('Alimentação');
    await transactions.create(expense(5, DateTime(2026, 9, 1), food));
    expect(await AccountRepository(opened.database).delete(1), isFalse);
    expect(await CategoryRepository(opened.database).delete(food), isFalse);
  });

  test('metas guardam valores com centavos', () async {
    final goals = GoalRepository(opened.database);
    await goals.save(
      Goal(
        name: 'Viagem',
        targetAmount: 7500.75,
        currentAmount: 0.05,
        createdAt: DateTime(2026, 9, 1),
      ),
    );
    final goal = (await goals.list()).single;
    expect(goal.targetAmount, 7500.75);
    expect(goal.currentAmount, 0.05);
  });
}
