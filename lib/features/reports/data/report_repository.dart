import '../../../core/database/app_database.dart';

class ReportRepository {
  ReportRepository(this._database);

  final AppDatabase _database;

  Future<MonthlyReport> load(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final totals = await _database.db.rawQuery(
      '''
      SELECT type, SUM(amount) AS total
      FROM transactions
      WHERE date >= ? AND date < ?
      GROUP BY type
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final categories = await _database.db.rawQuery(
      '''
      SELECT c.name, c.color, SUM(t.amount) AS total
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
    for (final row in totals) {
      if (row['type'] == 'income') {
        income = (row['total'] as num).toDouble();
      } else {
        expense = (row['total'] as num).toDouble();
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
              amount: (row['total'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}

class MonthlyReport {
  const MonthlyReport({
    required this.income,
    required this.expense,
    required this.categories,
  });

  final double income;
  final double expense;
  final List<ReportCategory> categories;

  double get result => income - expense;
}

class ReportCategory {
  const ReportCategory({
    required this.name,
    required this.color,
    required this.amount,
  });

  final String name;
  final int color;
  final double amount;
}
