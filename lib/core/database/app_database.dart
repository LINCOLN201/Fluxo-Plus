import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

class AppDatabase {
  AppDatabase(this._factory);

  final DatabaseFactory _factory;
  Database? _database;

  Database get db {
    final value = _database;
    if (value == null) {
      throw StateError('Banco de dados ainda não inicializado.');
    }
    return value;
  }

  Future<void> initialize() async {
    if (_database != null) return;
    final directory = await getApplicationSupportDirectory();
    final path = p.join(directory.path, AppConstants.databaseName);
    _database = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.databaseVersion,
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
        onCreate: _create,
        onUpgrade: _upgrade,
      ),
    );
  }

  Future<void> _create(Database database, int version) async {
    await database.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          initial_balance REAL NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
      await txn.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
          icon TEXT NOT NULL,
          color INTEGER NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await txn.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
          amount REAL NOT NULL CHECK(amount > 0),
          category_id INTEGER NOT NULL,
          account_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          is_paid INTEGER NOT NULL DEFAULT 1,
          installment_group TEXT,
          installment_number INTEGER NOT NULL DEFAULT 1,
          installment_count INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY(category_id) REFERENCES categories(id),
          FOREIGN KEY(account_id) REFERENCES accounts(id)
        )
      ''');
      await txn.execute('''
        CREATE TABLE goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          target_amount REAL NOT NULL,
          current_amount REAL NOT NULL DEFAULT 0,
          deadline TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await txn.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await txn.execute(
        'CREATE INDEX idx_transactions_date ON transactions(date)',
      );
      await txn.execute(
        'CREATE INDEX idx_transactions_due_status '
        'ON transactions(is_paid, date)',
      );

      final now = DateTime.now().toIso8601String();
      await txn.insert('accounts', {
        'name': 'Conta principal',
        'initial_balance': 0.0,
        'created_at': now,
      });

      const categories = [
        ('Salário', 'income', 'payments', 0xFF0F9D58),
        ('Freelance', 'income', 'work', 0xFF0B6B3A),
        ('Outras receitas', 'income', 'add_circle', 0xFF64748B),
        ('Alimentação', 'expense', 'restaurant', 0xFFE53935),
        ('Moradia', 'expense', 'home', 0xFF7C3AED),
        ('Transporte', 'expense', 'directions_car', 0xFF0284C7),
        ('Saúde', 'expense', 'medical_services', 0xFFDB2777),
        ('Lazer', 'expense', 'celebration', 0xFFF59E0B),
        ('Cartão de crédito', 'expense', 'credit_card', 0xFF7C3AED),
        ('Internet', 'expense', 'wifi', 0xFF0284C7),
        ('Outras despesas', 'expense', 'more_horiz', 0xFF64748B),
      ];
      for (final category in categories) {
        await txn.insert('categories', {
          'name': category.$1,
          'type': category.$2,
          'icon': category.$3,
          'color': category.$4,
          'is_default': 1,
        });
      }
      await txn.insert('settings', {'key': 'theme', 'value': 'dark'});
    });
  }

  Future<void> _upgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await database.transaction((txn) async {
        await txn.execute(
          'ALTER TABLE transactions '
          'ADD COLUMN is_paid INTEGER NOT NULL DEFAULT 1',
        );
        await txn.execute(
          'ALTER TABLE transactions ADD COLUMN installment_group TEXT',
        );
        await txn.execute(
          'ALTER TABLE transactions '
          'ADD COLUMN installment_number INTEGER NOT NULL DEFAULT 1',
        );
        await txn.execute(
          'ALTER TABLE transactions '
          'ADD COLUMN installment_count INTEGER NOT NULL DEFAULT 1',
        );
        await txn.execute(
          'CREATE INDEX idx_transactions_due_status '
          'ON transactions(is_paid, date)',
        );
        await _ensureCategory(
          txn,
          name: 'Cartão de crédito',
          icon: 'credit_card',
          color: 0xFF7C3AED,
        );
        await _ensureCategory(
          txn,
          name: 'Internet',
          icon: 'wifi',
          color: 0xFF0284C7,
        );
        const iconUpdates = {
          'Alimentação': 'restaurant',
          'Moradia': 'home',
          'Transporte': 'directions_car',
          'Saúde': 'medical_services',
          'Lazer': 'celebration',
          'Outras despesas': 'more_horiz',
          'Salário': 'payments',
          'Freelance': 'work',
          'Outras receitas': 'add_circle',
        };
        for (final entry in iconUpdates.entries) {
          await txn.update(
            'categories',
            {'icon': entry.value},
            where: 'name = ?',
            whereArgs: [entry.key],
          );
        }
      });
    }
  }

  Future<void> _ensureCategory(
    DatabaseExecutor database, {
    required String name,
    required String icon,
    required int color,
  }) async {
    final existing = await database.query(
      'categories',
      columns: ['id'],
      where: 'name = ? AND type = ?',
      whereArgs: [name, 'expense'],
      limit: 1,
    );
    if (existing.isNotEmpty) return;
    await database.insert('categories', {
      'name': name,
      'type': 'expense',
      'icon': icon,
      'color': color,
      'is_default': 1,
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<bool> hasLocalData() async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM transactions');
    return (rows.first['n'] as int? ?? 0) > 0;
  }

  Future<Map<String, dynamic>> exportSnapshot() async {
    const tables = [
      'accounts',
      'categories',
      'transactions',
      'goals',
    ];
    final snapshot = <String, dynamic>{};
    for (final table in tables) {
      snapshot[table] = await db.query(table);
    }
    // Preferências de tema, biometria e onboarding pertencem ao dispositivo.
    snapshot['settings'] = <Map<String, Object?>>[];
    snapshot['exported_at'] = DateTime.now().toUtc().toIso8601String();
    snapshot['schema_version'] = AppConstants.databaseVersion;
    return snapshot;
  }

  Future<void> restoreSnapshot(Map<String, dynamic> snapshot) async {
    const tables = [
      'accounts',
      'categories',
      'transactions',
      'goals',
    ];
    for (final table in [...tables, 'settings']) {
      if (snapshot[table] is! List) {
        throw const FormatException('Backup inválido ou incompleto.');
      }
    }
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('goals');
      await txn.delete('categories');
      await txn.delete('accounts');
      for (final table in tables) {
        for (final raw in snapshot[table] as List<dynamic>) {
          await txn.insert(table, Map<String, Object?>.from(raw as Map));
        }
      }
    });
  }
}
