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

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<Map<String, dynamic>> exportSnapshot() async {
    const tables = [
      'accounts',
      'categories',
      'transactions',
      'goals',
      'settings',
    ];
    final snapshot = <String, dynamic>{};
    for (final table in tables) {
      snapshot[table] = await db.query(table);
    }
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
      'settings',
    ];
    for (final table in tables) {
      if (snapshot[table] is! List) {
        throw const FormatException('Backup inválido ou incompleto.');
      }
    }
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('goals');
      await txn.delete('categories');
      await txn.delete('accounts');
      await txn.delete('settings');
      for (final table in tables) {
        for (final raw in snapshot[table] as List<dynamic>) {
          await txn.insert(table, Map<String, Object?>.from(raw as Map));
        }
      }
    });
  }
}
