import '../../../core/database/app_database.dart';
import '../../../core/utils/money.dart';
import '../../../shared/models/category.dart';
import '../domain/dashboard_summary.dart';

class DashboardRepository {
  DashboardRepository(this._database);

  final AppDatabase _database;

  Future<DashboardSummary> load(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    final balanceRows = await _database.db.rawQuery('''
      SELECT
        COALESCE((SELECT SUM(initial_balance_cents) FROM accounts), 0) +
        COALESCE(SUM(
          CASE
            WHEN is_paid = 0 THEN 0
            WHEN type = 'income' THEN amount_cents
            ELSE -amount_cents
          END
        ), 0) AS balance
      FROM transactions
    ''');
    final monthRows = await _database.db.rawQuery(
      '''
      SELECT type, COALESCE(SUM(amount_cents), 0) AS total
      FROM transactions
      WHERE date >= ? AND date < ?
      GROUP BY type
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final recentRows = await _database.db.rawQuery('''
      SELECT t.id, t.type, t.amount_cents, t.description, t.date, t.is_paid,
             t.installment_number, t.installment_count,
             c.name AS category_name, c.icon AS category_icon
      FROM transactions t
      INNER JOIN categories c ON c.id = t.category_id
      ORDER BY
        CASE WHEN t.is_paid = 0 THEN 0 ELSE 1 END,
        CASE WHEN t.is_paid = 0 THEN t.date END ASC,
        CASE WHEN t.is_paid = 1 THEN t.date END DESC,
        t.id DESC
      LIMIT 5
    ''');
    final alertRows = await _database.db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM transactions
      WHERE type = 'expense' AND is_paid = 0
        AND date < ?
      ''',
      [
        DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day + 8,
        ).toIso8601String(),
      ],
    );
    final historyStart = DateTime(month.year, month.month - 4);
    final historyRows = await _database.db.rawQuery(
      '''
      SELECT strftime('%Y-%m', date) AS month, type, SUM(amount_cents) AS total
      FROM transactions
      WHERE date >= ? AND date < ?
      GROUP BY strftime('%Y-%m', date), type
      ''',
      [historyStart.toIso8601String(), end.toIso8601String()],
    );
    final categoryRows = await _database.db.rawQuery(
      '''
      SELECT c.name, c.color, SUM(t.amount_cents) AS total
      FROM transactions t
      INNER JOIN categories c ON c.id = t.category_id
      WHERE t.type = 'expense' AND t.date >= ? AND t.date < ?
      GROUP BY c.id, c.name, c.color
      ORDER BY total DESC
      LIMIT 5
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    var income = 0.0;
    var expense = 0.0;
    for (final row in monthRows) {
      final total = Money.fromCents(row['total']);
      if (row['type'] == TransactionType.income.name) {
        income = total;
      } else {
        expense = total;
      }
    }

    final monthlyFlow = List.generate(5, (index) {
      final date = DateTime(historyStart.year, historyStart.month + index);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      var itemIncome = 0.0;
      var itemExpense = 0.0;
      for (final row in historyRows.where((row) => row['month'] == key)) {
        if (row['type'] == TransactionType.income.name) {
          itemIncome = Money.fromCents(row['total']);
        } else {
          itemExpense = Money.fromCents(row['total']);
        }
      }
      return MonthlyFlow(
        month: date,
        income: itemIncome,
        expense: itemExpense,
      );
    });

    return DashboardSummary(
      balance: Money.fromCents(balanceRows.first['balance']),
      monthIncome: income,
      monthExpense: expense,
      recentTransactions: recentRows
          .map(
            (row) => TransactionListItem(
              id: row['id'] as int,
              type: TransactionType.values.byName(row['type'] as String),
              amount: Money.fromCents(row['amount_cents']),
              description: row['description'] as String,
              categoryName: row['category_name'] as String,
              date: DateTime.parse(row['date'] as String),
              isPaid: (row['is_paid'] as int) == 1,
              categoryIcon: row['category_icon'] as String,
              installmentNumber: row['installment_number'] as int,
              installmentCount: row['installment_count'] as int,
            ),
          )
          .toList(),
      monthlyFlow: monthlyFlow,
      categorySpending: categoryRows
          .map(
            (row) => CategorySpending(
              name: row['name'] as String,
              amount: Money.fromCents(row['total']),
              color: row['color'] as int,
            ),
          )
          .toList(),
      pendingAlerts: (alertRows.first['total'] as num).toInt(),
    );
  }
}
