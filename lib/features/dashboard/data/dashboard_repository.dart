import '../../../core/database/app_database.dart';
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
        COALESCE((SELECT SUM(initial_balance) FROM accounts), 0) +
        COALESCE(SUM(
          CASE WHEN type = 'income' THEN amount ELSE -amount END
        ), 0) AS balance
      FROM transactions
    ''');
    final monthRows = await _database.db.rawQuery(
      '''
      SELECT type, COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE date >= ? AND date < ?
      GROUP BY type
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final recentRows = await _database.db.rawQuery('''
      SELECT t.id, t.type, t.amount, t.description, t.date,
             c.name AS category_name
      FROM transactions t
      INNER JOIN categories c ON c.id = t.category_id
      ORDER BY t.date DESC, t.id DESC
      LIMIT 5
    ''');
    final historyStart = DateTime(month.year, month.month - 4);
    final historyRows = await _database.db.rawQuery(
      '''
      SELECT strftime('%Y-%m', date) AS month, type, SUM(amount) AS total
      FROM transactions
      WHERE date >= ? AND date < ?
      GROUP BY strftime('%Y-%m', date), type
      ''',
      [historyStart.toIso8601String(), end.toIso8601String()],
    );
    final categoryRows = await _database.db.rawQuery(
      '''
      SELECT c.name, c.color, SUM(t.amount) AS total
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
      final total = (row['total'] as num).toDouble();
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
          itemIncome = (row['total'] as num).toDouble();
        } else {
          itemExpense = (row['total'] as num).toDouble();
        }
      }
      return MonthlyFlow(
        month: date,
        income: itemIncome,
        expense: itemExpense,
      );
    });

    return DashboardSummary(
      balance: (balanceRows.first['balance'] as num).toDouble(),
      monthIncome: income,
      monthExpense: expense,
      recentTransactions: recentRows
          .map(
            (row) => TransactionListItem(
              id: row['id'] as int,
              type: TransactionType.values.byName(row['type'] as String),
              amount: (row['amount'] as num).toDouble(),
              description: row['description'] as String,
              categoryName: row['category_name'] as String,
              date: DateTime.parse(row['date'] as String),
            ),
          )
          .toList(),
      monthlyFlow: monthlyFlow,
      categorySpending: categoryRows
          .map(
            (row) => CategorySpending(
              name: row['name'] as String,
              amount: (row['total'] as num).toDouble(),
              color: row['color'] as int,
            ),
          )
          .toList(),
    );
  }
}
