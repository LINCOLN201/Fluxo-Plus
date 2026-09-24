import '../../../core/database/app_database.dart';
import '../../../core/utils/money.dart';

class ReportRepository {
  ReportRepository(this._database);

  final AppDatabase _database;

  Future<MonthlyReport> load(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final totals = await _database.db.rawQuery(
      '''
      SELECT type, SUM(amount_cents) AS total,
             SUM(CASE WHEN is_paid = 1 THEN amount_cents ELSE 0 END) AS completed,
             COUNT(*) AS quantity
      FROM transactions
      WHERE date >= ? AND date < ?
      GROUP BY type
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final categories = await _database.db.rawQuery(
      '''
      SELECT c.name, c.color, c.icon, SUM(t.amount_cents) AS total
      FROM transactions t
      JOIN categories c ON c.id = t.category_id
      WHERE t.type = 'expense' AND t.date >= ? AND t.date < ?
      GROUP BY c.id
      ORDER BY total DESC
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    var income = 0.0;
    var expense = 0.0;
    var receivedIncome = 0.0;
    var paidExpense = 0.0;
    var transactionCount = 0;
    for (final row in totals) {
      transactionCount += (row['quantity'] as num).toInt();
      if (row['type'] == 'income') {
        income = Money.fromCents(row['total']);
        receivedIncome = Money.fromCents(row['completed']);
      } else {
        expense = Money.fromCents(row['total']);
        paidExpense = Money.fromCents(row['completed']);
      }
    }
    return MonthlyReport(
      income: income,
      expense: expense,
      categories: categories
          .map(
            (row) => ReportCategory(
              name: row['name'] as String,
              color: row['color'] as int,
              amount: Money.fromCents(row['total']),
              icon: row['icon'] as String,
            ),
          )
          .toList(),
      receivedIncome: receivedIncome,
      paidExpense: paidExpense,
      transactionCount: transactionCount,
    );
  }
}

class MonthlyReport {
  const MonthlyReport({
    required this.income,
    required this.expense,
    required this.categories,
    required this.receivedIncome,
    required this.paidExpense,
    required this.transactionCount,
  });

  final double income;
  final double expense;
  final List<ReportCategory> categories;
  final double receivedIncome;
  final double paidExpense;
  final int transactionCount;

  double get result => income - expense;
  double get pendingExpense => expense - paidExpense;
  double get savingsRate => income == 0 ? 0 : result / income;
}

class ReportCategory {
  const ReportCategory({
    required this.name,
    required this.color,
    required this.amount,
    required this.icon,
  });

  final String name;
  final int color;
  final double amount;
  final String icon;
}
