import '../../../core/database/app_database.dart';
import '../../../core/utils/installment_schedule.dart';
import '../../../shared/models/account.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/finance_transaction.dart';

class TransactionRepository {
  TransactionRepository(this._database);

  final AppDatabase _database;

  Future<List<Account>> getAccounts() async {
    final rows = await _database.db.query('accounts', orderBy: 'name');
    return rows.map(Account.fromMap).toList();
  }

  Future<List<Category>> getCategories(TransactionType type) async {
    final rows = await _database.db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'name',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<List<TransactionRecord>> list({
    DateTime? month,
    TransactionType? type,
    int? categoryId,
    PaymentFilter payment = PaymentFilter.all,
  }) async {
    final conditions = <String>[];
    final arguments = <Object?>[];
    if (month != null) {
      conditions.add('t.date >= ? AND t.date < ?');
      arguments
        ..add(DateTime(month.year, month.month).toIso8601String())
        ..add(DateTime(month.year, month.month + 1).toIso8601String());
    }
    if (type != null) {
      conditions.add('t.type = ?');
      arguments.add(type.name);
    }
    if (categoryId != null) {
      conditions.add('t.category_id = ?');
      arguments.add(categoryId);
    }
    if (payment == PaymentFilter.pending) {
      conditions.add('t.is_paid = 0');
    } else if (payment == PaymentFilter.paid) {
      conditions.add('t.is_paid = 1');
    }
    final rows = await _database.db.rawQuery(
      '''
      SELECT t.*, c.name AS category_name, c.color AS category_color,
             c.icon AS category_icon,
             a.name AS account_name
      FROM transactions t
      INNER JOIN categories c ON c.id = t.category_id
      INNER JOIN accounts a ON a.id = t.account_id
      ${conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}'}
      ORDER BY
        CASE WHEN t.is_paid = 0 THEN 0 ELSE 1 END,
        CASE WHEN t.is_paid = 0 THEN t.date END ASC,
        CASE WHEN t.is_paid = 1 THEN t.date END DESC,
        t.id DESC
      ''',
      arguments,
    );
    return rows.map(TransactionRecord.fromMap).toList();
  }

  Future<FinanceTransaction?> find(int id) async {
    final rows = await _database.db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : FinanceTransaction.fromMap(rows.first);
  }

  Future<List<Category>> getAllCategories() async {
    final rows = await _database.db.query('categories', orderBy: 'name');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> create(FinanceTransaction transaction) =>
      _database.db.insert('transactions', transaction.toMap());

  Future<List<int>> createInstallments(
    FinanceTransaction transaction,
    int count,
  ) async {
    if (count < 1 || count > 120) {
      throw ArgumentError.value(count, 'count', 'Use entre 1 e 120 parcelas.');
    }
    final group =
        count == 1 ? null : 'parcelas-${DateTime.now().microsecondsSinceEpoch}';
    final dates = InstallmentSchedule.dueDates(transaction.date, count);
    return _database.db.transaction((txn) async {
      final ids = <int>[];
      for (var index = 0; index < count; index++) {
        ids.add(
          await txn.insert(
            'transactions',
            FinanceTransaction(
              type: transaction.type,
              amount: transaction.amount,
              categoryId: transaction.categoryId,
              accountId: transaction.accountId,
              date: dates[index],
              description: transaction.description,
              createdAt: transaction.createdAt,
              isPaid: index == 0 ? transaction.isPaid : false,
              installmentGroup: group,
              installmentNumber: index + 1,
              installmentCount: count,
            ).toMap(),
          ),
        );
      }
      return ids;
    });
  }

  Future<void> update(FinanceTransaction transaction) async {
    if (transaction.id == null) {
      throw ArgumentError('A transação precisa ter um id para ser editada.');
    }
    await _database.db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> delete(int id) async {
    await _database.db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setPaid(int id, bool paid) async {
    await _database.db.update(
      'transactions',
      {'is_paid': paid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TransactionRecord>> dueAlerts({
    int daysAhead = 7,
  }) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(Duration(days: daysAhead + 1));
    final rows = await _database.db.rawQuery(
      '''
      SELECT t.*, c.name AS category_name, c.color AS category_color,
             c.icon AS category_icon, a.name AS account_name
      FROM transactions t
      INNER JOIN categories c ON c.id = t.category_id
      INNER JOIN accounts a ON a.id = t.account_id
      WHERE t.type = 'expense' AND t.is_paid = 0 AND t.date < ?
      ORDER BY t.date ASC, t.id ASC
      ''',
      [end.toIso8601String()],
    );
    return rows.map(TransactionRecord.fromMap).toList();
  }
}

class TransactionRecord {
  const TransactionRecord({
    required this.transaction,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.accountName,
  });

  final FinanceTransaction transaction;
  final String categoryName;
  final int categoryColor;
  final String categoryIcon;
  final String accountName;

  factory TransactionRecord.fromMap(Map<String, Object?> map) =>
      TransactionRecord(
        transaction: FinanceTransaction.fromMap(map),
        categoryName: map['category_name'] as String,
        categoryColor: map['category_color'] as int,
        categoryIcon: map['category_icon'] as String,
        accountName: map['account_name'] as String,
      );
}

enum PaymentFilter { all, pending, paid }
