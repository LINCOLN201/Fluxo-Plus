import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher
    show SqlCipherOpenDatabaseOptions, databaseFactory;

import '../constants/app_constants.dart';
import '../observability/error_reporter.dart';
import '../theme/category_palette.dart';
import 'database_key_service.dart';
import 'safety_copy_cipher.dart';
import 'snapshot_migrator.dart';

class AppDatabase {
  AppDatabase(this._factory, {DatabaseKeyService? keyService})
      : _keyService = keyService ?? DatabaseKeyService();

  // Extensão neutra: o conteúdo é binário cifrado, não é mais JSON.
  static const _safetyCopyName = 'antes-da-restauracao.enc';

  /// A cópia feita antes de restaurar guarda todos os dados em claro; ela só
  /// existe para desfazer um engano recente e é apagada depois desse prazo.
  static const safetyCopyLifetime = Duration(days: 7);

  final DatabaseFactory _factory;
  final DatabaseKeyService _keyService;
  final SafetyCopyCipher _safetyCopyCipher = SafetyCopyCipher();
  Database? _database;
  String? _directory;

  Database get db {
    final value = _database;
    if (value == null) {
      throw StateError('Banco de dados ainda não inicializado.');
    }
    return value;
  }

  /// [path] e [directory] existem para os testes; o app usa o diretório de
  /// suporte privado da plataforma.
  Future<void> initialize({String? path, String? directory}) async {
    if (_database != null) return;
    _directory = directory ?? (await getApplicationSupportDirectory()).path;
    path ??= p.join(_directory!, AppConstants.databaseName);
    // Só Android tem um sqlite3 com SQLCipher disponível hoje; ver
    // docs/ROADMAP.md para as demais plataformas.
    final password = Platform.isAndroid ? await _keyService.rawKey() : null;
    if (password != null) {
      await migrateToCipherIfNeeded(path, password);
    }
    _database = await _factory.openDatabase(
      path,
      options: password == null
          ? OpenDatabaseOptions(
              version: AppConstants.databaseVersion,
              onConfigure: (database) =>
                  database.execute('PRAGMA foreign_keys = ON'),
              onCreate: _create,
              onUpgrade: _upgrade,
            )
          : sqlcipher.SqlCipherOpenDatabaseOptions(
              version: AppConstants.databaseVersion,
              password: password,
              onConfigure: (database) =>
                  database.execute('PRAGMA foreign_keys = ON'),
              onCreate: _create,
              onUpgrade: _upgrade,
            ),
    );
    await safetyCopyDate(); // apaga a cópia de restauração vencida
  }

  /// Converte um banco antigo, sem cifra, para o formato SQLCipher — quem já
  /// tinha o app antes da 0.6.0 tinha esse arquivo em texto puro; sem isso, a
  /// abertura com senha falha e a pessoa perde os dados (já aconteceu antes).
  ///
  /// Segue a receita oficial do SQLCipher (ATTACH + `sqlcipher_export`) e só
  /// substitui o arquivo original depois de confirmar que a cópia cifrada
  /// abre de verdade com a senha nova; o original vira `.pre-cipher-backup`
  /// em vez de ser apagado, como rede de segurança.
  ///
  /// Não roda no `flutter test`: o SQLCipher nativo só existe numa build
  /// Android de verdade (mesma limitação já registrada em
  /// `docs/ROADMAP.md`), então isto não tem como ser validado fora de um
  /// aparelho real.
  Future<void> migrateToCipherIfNeeded(String path, String password) async {
    final file = File(path);
    if (!await file.exists()) return; // banco novo, nada a migrar
    if (!await _looksLikePlaintextSqlite(file)) return; // já cifrado

    final tmpFile = File('$path.cipher-tmp');
    if (await tmpFile.exists()) await tmpFile.delete();

    Database? plain;
    try {
      plain = await sqlcipher.databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final escapedTmpPath = tmpFile.path.replaceAll("'", "''");
      await plain.execute(
        "ATTACH DATABASE '$escapedTmpPath' AS encrypted KEY $password",
      );
      await plain.execute("SELECT sqlcipher_export('encrypted')");
      await plain.execute('DETACH DATABASE encrypted');
    } catch (e, st) {
      ErrorReporter.record(
        e,
        st,
        reason: 'AppDatabase.migrateToCipherIfNeeded.export',
      );
      if (await tmpFile.exists()) await tmpFile.delete();
      rethrow;
    } finally {
      await plain?.close();
    }

    Database? verify;
    try {
      verify = await sqlcipher.databaseFactory.openDatabase(
        tmpFile.path,
        options: sqlcipher.SqlCipherOpenDatabaseOptions(password: password),
      );
      await verify.rawQuery('SELECT COUNT(*) FROM sqlite_master');
    } catch (e, st) {
      ErrorReporter.record(
        e,
        st,
        reason: 'AppDatabase.migrateToCipherIfNeeded.verify',
      );
      await verify?.close();
      if (await tmpFile.exists()) await tmpFile.delete();
      rethrow;
    }
    await verify.close();

    // Copia (não move) o original para o backup antes do passo final, para
    // o `rename` abaixo ser a única operação que troca o arquivo em uso —
    // `rename` sobrescreve o destino de forma atômica no mesmo volume, sem
    // a janela em que nenhum arquivo existiria em `path` se o processo
    // fosse encerrado exatamente entre duas operações separadas.
    final backup = File('$path.pre-cipher-backup');
    if (await backup.exists()) await backup.delete();
    await file.copy(backup.path);
    await tmpFile.rename(path);
  }

  static const _sqliteMagic = 'SQLite format 3\u0000';

  Future<bool> _looksLikePlaintextSqlite(File file) async {
    if (await file.length() < _sqliteMagic.length) return false;
    final header = await file.openRead(0, _sqliteMagic.length).first;
    final magicBytes = _sqliteMagic.codeUnits;
    for (var i = 0; i < magicBytes.length; i++) {
      if (header[i] != magicBytes[i]) return false;
    }
    return true;
  }

  Future<void> _create(Database database, int version) async {
    await database.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          initial_balance_cents INTEGER NOT NULL DEFAULT 0,
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
          is_default INTEGER NOT NULL DEFAULT 0,
          is_subscription INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await _createTransactionsTable(txn, 'transactions');
      // Adicionada fora do CREATE TABLE porque _createTransactionsTable
      // também monta a tabela temporária da migração de centavos (v3), que
      // precisa continuar representando o esquema de antes desta coluna.
      await txn.execute(
        'ALTER TABLE transactions ADD COLUMN recurring_group TEXT',
      );
      await txn.execute(
        'CREATE INDEX idx_transactions_recurring_group '
        'ON transactions(recurring_group)',
      );
      await _createGoalsTable(txn, 'goals');
      await txn.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await _createTransactionIndexes(txn);

      final now = DateTime.now().toIso8601String();
      await txn.insert('accounts', {
        'name': 'Conta principal',
        'initial_balance_cents': 0,
        'created_at': now,
      });

      const categories = [
        ('Salário', 'income', 'payments'),
        ('Freelance', 'income', 'work'),
        ('Outras receitas', 'income', 'add_circle'),
        ('Alimentação', 'expense', 'restaurant'),
        ('Moradia', 'expense', 'home'),
        ('Transporte', 'expense', 'directions_car'),
        ('Saúde', 'expense', 'medical_services'),
        ('Lazer', 'expense', 'celebration'),
        ('Cartão de crédito', 'expense', 'credit_card'),
        ('Internet', 'expense', 'wifi'),
        ('Assinaturas', 'expense', 'subscriptions'),
        ('Outras despesas', 'expense', 'more_horiz'),
      ];
      for (final category in categories) {
        await txn.insert('categories', {
          'name': category.$1,
          'type': category.$2,
          'icon': category.$3,
          'color': CategoryPalette.defaults[category.$1],
          'is_default': 1,
          'is_subscription': category.$1 == 'Assinaturas' ? 1 : 0,
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
    if (oldVersion < 3) {
      await database.transaction(_upgradeToCents);
    }
    if (oldVersion < 4) {
      await database.transaction((txn) async {
        await txn.execute(
          'ALTER TABLE transactions ADD COLUMN recurring_group TEXT',
        );
        await txn.execute(
          'CREATE INDEX idx_transactions_recurring_group '
          'ON transactions(recurring_group)',
        );
      });
    }
    if (oldVersion < 5) {
      await database.transaction((txn) async {
        await _ensureCategory(
          txn,
          name: 'Assinaturas',
          icon: 'subscriptions',
          color: CategoryPalette.defaults['Assinaturas']!,
        );
      });
    }
    if (oldVersion < 6) {
      // Verifica se a coluna já existe antes de tentar adicioná-la: builds de
      // desenvolvimento de branches paralelas podem tê-la adicionado com
      // schema version 5 ou sem rodar o UPDATE abaixo, deixando o flag em 0.
      final cols = await database.rawQuery("PRAGMA table_info('categories')");
      if (!cols.any((c) => c['name'] == 'is_subscription')) {
        await database.execute(
          'ALTER TABLE categories '
          'ADD COLUMN is_subscription INTEGER NOT NULL DEFAULT 0',
        );
      }
      await database.execute(
        'UPDATE categories SET is_subscription = 1 '
        "WHERE name = 'Assinaturas' AND type = 'expense'",
      );
      final check = await database.query(
        'categories',
        columns: ['id'],
        where: "name = 'Assinaturas' AND type = 'expense'",
        limit: 1,
      );
      if (check.isEmpty) {
        await database.insert('categories', {
          'name': 'Assinaturas',
          'type': 'expense',
          'icon': 'subscriptions',
          'color': CategoryPalette.defaults['Assinaturas'],
          'is_default': 1,
          'is_subscription': 1,
        });
      }
    }
    if (oldVersion < 7) {
      // Repara bancos que vieram do schema 6 sem is_subscription = 1 na
      // categoria "Assinaturas" (ex: build v0.6.12 onde a migração v6 não
      // atualizou o flag). UPDATE idempotente — não faz nada em bancos saudáveis.
      await database.execute(
        'UPDATE categories SET is_subscription = 1 '
        "WHERE name = 'Assinaturas' AND type = 'expense'",
      );
      final check = await database.query(
        'categories',
        columns: ['id'],
        where: "name = 'Assinaturas' AND type = 'expense'",
        limit: 1,
      );
      if (check.isEmpty) {
        await database.insert('categories', {
          'name': 'Assinaturas',
          'type': 'expense',
          'icon': 'subscriptions',
          'color': CategoryPalette.defaults['Assinaturas'],
          'is_default': 1,
          'is_subscription': 1,
        });
      }
    }
  }

  /// v3: valores em centavos inteiros e cores Grafite nas categorias padrão.
  ///
  /// `transactions` e `goals` não são referenciadas por outras tabelas e são
  /// recriadas. `accounts` é referenciada por `transactions`, então recebe uma
  /// coluna nova; a antiga `initial_balance` fica sem uso (tem DEFAULT 0), o
  /// que evita recriar uma tabela pai com as chaves estrangeiras ativas.
  Future<void> _upgradeToCents(Transaction txn) async {
    await txn.execute(
      'ALTER TABLE accounts '
      'ADD COLUMN initial_balance_cents INTEGER NOT NULL DEFAULT 0',
    );
    await txn.execute(
      'UPDATE accounts '
      'SET initial_balance_cents = CAST(ROUND(initial_balance * 100) AS INTEGER)',
    );

    await _createTransactionsTable(txn, 'transactions_v3');
    await txn.execute('''
      INSERT INTO transactions_v3 (
        id, type, amount_cents, category_id, account_id, date, description,
        is_paid, installment_group, installment_number, installment_count,
        created_at
      )
      SELECT
        id, type, CAST(ROUND(amount * 100) AS INTEGER), category_id,
        account_id, date, description, is_paid, installment_group,
        installment_number, installment_count, created_at
      FROM transactions
    ''');
    await txn.execute('DROP TABLE transactions');
    await txn.execute('ALTER TABLE transactions_v3 RENAME TO transactions');
    await _createTransactionIndexes(txn);

    await _createGoalsTable(txn, 'goals_v3');
    await txn.execute('''
      INSERT INTO goals_v3 (
        id, name, target_amount_cents, current_amount_cents, deadline,
        created_at
      )
      SELECT
        id, name, CAST(ROUND(target_amount * 100) AS INTEGER),
        CAST(ROUND(current_amount * 100) AS INTEGER), deadline, created_at
      FROM goals
    ''');
    await txn.execute('DROP TABLE goals');
    await txn.execute('ALTER TABLE goals_v3 RENAME TO goals');

    for (final entry in CategoryPalette.legacyDefaults.entries) {
      await txn.update(
        'categories',
        {'color': CategoryPalette.defaults[entry.key]},
        where: 'name = ? AND color = ? AND is_default = 1',
        whereArgs: [entry.key, entry.value],
      );
    }
  }

  Future<void> _createTransactionsTable(
    DatabaseExecutor database,
    String name,
  ) =>
      database.execute('''
        CREATE TABLE $name (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
          amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
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

  Future<void> _createTransactionIndexes(DatabaseExecutor database) async {
    await database.execute(
      'CREATE INDEX idx_transactions_date ON transactions(date)',
    );
    await database.execute(
      'CREATE INDEX idx_transactions_due_status '
      'ON transactions(is_paid, date)',
    );
  }

  Future<void> _createGoalsTable(DatabaseExecutor database, String name) =>
      database.execute('''
        CREATE TABLE $name (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          target_amount_cents INTEGER NOT NULL,
          current_amount_cents INTEGER NOT NULL DEFAULT 0,
          deadline TEXT,
          created_at TEXT NOT NULL
        )
      ''');

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
    // A fresh install has 1 seeded account and 0 transactions (sum = 1).
    // Any real user data — a transaction OR a second account — pushes this
    // above 1, triggering the conflict prompt instead of a silent download.
    final rows = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM transactions) +
        (SELECT COUNT(*) FROM accounts) AS data_count
    ''');
    return ((rows.first['data_count'] as int? ?? 0)) > 1;
  }

  Future<Map<String, dynamic>> exportSnapshot() async {
    final snapshot = <String, dynamic>{};
    for (final entry in SnapshotMigrator.columns.entries) {
      snapshot[entry.key] = await db.query(entry.key, columns: entry.value);
    }
    // Preferências de tema, bloqueio e onboarding pertencem ao dispositivo.
    snapshot['settings'] = <Map<String, Object?>>[];
    snapshot['exported_at'] = DateTime.now().toUtc().toIso8601String();
    snapshot['schema_version'] = AppConstants.databaseVersion;
    return snapshot;
  }

  /// Substitui os dados financeiros pelo conteúdo do snapshot. Antes disso,
  /// guarda uma cópia dos dados atuais para permitir desfazer a restauração.
  Future<void> restoreSnapshot(Map<String, dynamic> snapshot) async {
    final tables = SnapshotMigrator.upgrade(snapshot);
    if (await hasLocalData()) await _writeSafetyCopy();
    await _replaceData(tables);
  }

  /// Data da cópia feita antes da última restauração, se existir.
  Future<DateTime?> safetyCopyDate({DateTime? now}) async {
    final file = _safetyCopyFile;
    if (file == null || !await file.exists()) return null;
    final date = await file.lastModified();
    if ((now ?? DateTime.now()).difference(date) > safetyCopyLifetime) {
      await file.delete();
      return null;
    }
    return date;
  }

  /// Desfaz a última restauração, voltando aos dados que existiam antes dela.
  Future<void> restoreSafetyCopy() async {
    final file = _safetyCopyFile;
    if (file == null || !await file.exists()) {
      throw const SnapshotException('Não há restauração para desfazer.');
    }
    final json = await _safetyCopyCipher.decrypt(await file.readAsBytes());
    final data = jsonDecode(json);
    await _replaceData(
      SnapshotMigrator.upgrade(Map<String, dynamic>.from(data as Map)),
    );
    await file.delete();
  }

  File? get _safetyCopyFile =>
      _directory == null ? null : File(p.join(_directory!, _safetyCopyName));

  /// Cifrada com uma chave gerada no aparelho (Keystore/cofre), não com uma
  /// senha do usuário: precisa poder ser lida de volta sem perguntar nada,
  /// para "Desfazer última restauração" continuar sendo um toque só.
  Future<void> _writeSafetyCopy() async {
    final file = _safetyCopyFile;
    if (file == null) return;
    final json = jsonEncode(await exportSnapshot());
    await file.writeAsBytes(
      await _safetyCopyCipher.encrypt(json),
      flush: true,
    );
  }

  Future<void> _replaceData(
    Map<String, List<Map<String, Object?>>> tables,
  ) async {
    await db.transaction((txn) async {
      for (final table in SnapshotMigrator.columns.keys.toList().reversed) {
        await txn.delete(table);
      }
      for (final entry in tables.entries) {
        for (final row in entry.value) {
          await txn.insert(entry.key, row);
        }
      }
    });
  }
}
