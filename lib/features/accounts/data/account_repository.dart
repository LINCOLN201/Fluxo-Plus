import '../../../core/database/app_database.dart';
import '../../../core/utils/money.dart';
import '../../../shared/models/account.dart';

class AccountRepository {
  AccountRepository(this._database);

  final AppDatabase _database;

  Future<List<AccountBalance>> list() async {
    final rows = await _database.db.rawQuery('''
      SELECT a.*,
        a.initial_balance_cents + COALESCE(SUM(
          CASE WHEN t.type = 'income' THEN t.amount_cents ELSE -t.amount_cents END
        ), 0) AS current_balance,
        COUNT(t.id) AS transaction_count
      FROM accounts a
      LEFT JOIN transactions t ON t.account_id = a.id
      GROUP BY a.id
      ORDER BY a.created_at, a.name
    ''');
    return rows
        .map(
          (row) => AccountBalance(
            account: Account.fromMap(row),
            balance: Money.fromCents(row['current_balance']),
            transactionCount: row['transaction_count'] as int,
          ),
        )
        .toList();
  }

  Future<int> save(Account account) {
    if (account.id == null) {
      return _database.db.insert('accounts', account.toMap());
    }
    return _database.db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<bool> delete(int id) async {
    final count = await _database.db.rawQuery(
      'SELECT COUNT(*) AS count FROM transactions WHERE account_id = ?',
      [id],
    );
    if ((count.first['count'] as int) > 0) return false;
    await _database.db.delete('accounts', where: 'id = ?', whereArgs: [id]);
    return true;
  }
}

class AccountBalance {
  const AccountBalance({
    required this.account,
    required this.balance,
    required this.transactionCount,
  });

  final Account account;
  final double balance;
  final int transactionCount;
}
