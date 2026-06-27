import '../../../core/database/app_database.dart';
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
    final rows = await _database.db.rawQuery(
      '''
      SELECT t.*, c.name AS category_name, c.color AS category_color,
             a.name AS account_name
      FROM transactions t
      INNER JOIN categories c ON c.id = t.category_id
      INNER JOIN accounts a ON a.id = t.account_id
      ${conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}'}
      ORDER BY t.date DESC, t.id DESC
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
}

class TransactionRecord {
  const TransactionRecord({
    required this.transaction,
    required this.categoryName,
    required this.categoryColor,
    required this.accountName,
  });

  final FinanceTransaction transaction;
  final String categoryName;
  final int categoryColor;
  final String accountName;

  factory TransactionRecord.fromMap(Map<String, Object?> map) =>
      TransactionRecord(
        transaction: FinanceTransaction.fromMap(map),
        categoryName: map['category_name'] as String,
        categoryColor: map['category_color'] as int,
        accountName: map['account_name'] as String,
      );
}
