import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/theme/category_palette.dart';
import 'package:fluxo_plus/features/accounts/data/account_repository.dart';
import 'package:fluxo_plus/features/dashboard/data/dashboard_repository.dart';
import 'package:fluxo_plus/features/goals/data/goal_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/test_database.dart';

/// Schema exatamente como a 0.5.0 (versão 2) o criava.
Future<void> _createV2(Database db) async {
  await db.execute('''
    CREATE TABLE accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      initial_balance REAL NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL
    )''');
  await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
      icon TEXT NOT NULL,
      color INTEGER NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0
    )''');
  await db.execute('''
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
    )''');
  await db.execute('''
    CREATE TABLE goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      target_amount REAL NOT NULL,
      current_amount REAL NOT NULL DEFAULT 0,
      deadline TEXT,
      created_at TEXT NOT NULL
    )''');
  await db.execute(
    'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
  );
  await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
  await db.execute(
    'CREATE INDEX idx_transactions_due_status ON transactions(is_paid, date)',
  );
}

void main() {
  late Directory directory;
  late TestDatabase opened;

  setUp(() async {
    sqfliteFfiInit();
    directory = await Directory.systemTemp.createTemp('fluxo_v2_');
    final legacy = await databaseFactoryFfi.openDatabase(
      p.join(directory.path, 'fluxo_plus.db'),
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) => _createV2(db),
      ),
    );
    final now = DateTime(2026, 9, 1).toIso8601String();
    await legacy.insert('accounts', {
      'name': 'Conta principal',
      'initial_balance': 1000.10,
      'created_at': now,
    });
    await legacy.insert('categories', {
      'name': 'Alimentação',
      'type': 'expense',
      'icon': 'restaurant',
      'color': CategoryPalette.legacyDefaults['Alimentação'],
      'is_default': 1,
    });
    await legacy.insert('categories', {
      'name': 'Moradia',
      'type': 'expense',
      'icon': 'home',
      'color': 0xFF123456, // personalizada pelo usuário
      'is_default': 1,
    });
    await legacy.insert('categories', {
      'name': 'Salário',
      'type': 'income',
      'icon': 'payments',
      'color': CategoryPalette.legacyDefaults['Salário'],
      'is_default': 1,
    });
    // Valores que somados em ponto flutuante não fecham (0,1 + 0,2).
    for (final (type, amount, category, paid) in [
      ('expense', 0.1, 1, 1),
      ('expense', 0.2, 1, 1),
      ('expense', 19.99, 2, 0),
      ('income', 2500.55, 3, 1),
    ]) {
      await legacy.insert('transactions', {
        'type': type,
        'amount': amount,
        'category_id': category,
        'account_id': 1,
        'date': DateTime(2026, 9, 10).toIso8601String(),
        'description': 'item',
        'is_paid': paid,
        'created_at': now,
      });
    }
    await legacy.insert('goals', {
      'name': 'Reserva',
      'target_amount': 5000.0,
      'current_amount': 1234.56,
      'created_at': now,
    });
    await legacy.close();

    opened = await TestDatabase.open(directory: directory);
  });

  tearDown(() => opened.dispose());

  test('converte valores para centavos inteiros sem perder dados', () async {
    final db = opened.database.db;
    final amounts = await db.rawQuery(
      'SELECT amount_cents, typeof(amount_cents) AS kind '
      'FROM transactions ORDER BY id',
    );
    expect(amounts.map((row) => row['amount_cents']), [10, 20, 1999, 250055]);
    expect(amounts.every((row) => row['kind'] == 'integer'), isTrue);

    final summary = await DashboardRepository(opened.database).load(
      DateTime(2026, 9),
    );
    expect(summary.monthExpense, 20.29);
    expect(summary.monthIncome, 2500.55);
    // Saldo: inicial + pagos (receita − despesas pagas).
    expect(summary.balance, closeTo(1000.10 + 2500.55 - 0.30, 1e-9));

    final accounts = await AccountRepository(opened.database).list();
    expect(accounts.single.account.initialBalance, 1000.10);

    final goal = (await GoalRepository(opened.database).list()).single;
    expect(goal.targetAmount, 5000);
    expect(goal.currentAmount, 1234.56);
  });

  test('aplica cores Grafite só nas categorias padrão não personalizadas',
      () async {
    final rows = await opened.database.db.query(
      'categories',
      columns: ['name', 'color'],
    );
    final colors = {for (final row in rows) row['name']: row['color']};
    expect(colors['Alimentação'], CategoryPalette.defaults['Alimentação']);
    expect(colors['Salário'], CategoryPalette.defaults['Salário']);
    expect(colors['Moradia'], 0xFF123456);
  });

  test('mantém índices e chaves estrangeiras após recriar a tabela', () async {
    final db = opened.database.db;
    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' "
      "AND tbl_name = 'transactions' AND name LIKE 'idx_%'",
    );
    expect(
      indexes.map((row) => row['name']),
      containsAll(['idx_transactions_date', 'idx_transactions_due_status']),
    );
    await expectLater(
      db.insert('transactions', {
        'type': 'expense',
        'amount_cents': 100,
        'category_id': 999,
        'account_id': 1,
        'date': DateTime(2026, 9, 1).toIso8601String(),
        'created_at': DateTime(2026, 9, 1).toIso8601String(),
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
