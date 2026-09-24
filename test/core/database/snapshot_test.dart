import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/constants/app_constants.dart';
import 'package:fluxo_plus/core/database/snapshot_migrator.dart';
import 'package:fluxo_plus/core/theme/category_palette.dart';
import 'package:fluxo_plus/features/transactions/data/transaction_repository.dart';
import 'package:fluxo_plus/shared/models/category.dart';
import 'package:fluxo_plus/shared/models/finance_transaction.dart';

import '../../support/test_database.dart';

Map<String, dynamic> _backupFrom050() => {
      'schema_version': 2,
      'accounts': [
        {
          'id': 1,
          'name': 'Conta principal',
          'initial_balance': 50.25,
          'created_at': '2026-09-01T00:00:00.000',
        },
      ],
      'categories': [
        {
          'id': 1,
          'name': 'Lazer',
          'type': 'expense',
          'icon': 'celebration',
          'color': CategoryPalette.legacyDefaults['Lazer'],
          'is_default': 1,
        },
      ],
      'transactions': [
        {
          'id': 1,
          'type': 'expense',
          'amount': 12.34,
          'category_id': 1,
          'account_id': 1,
          'date': '2026-09-05T00:00:00.000',
          'description': 'Cinema',
          'is_paid': 1,
          'installment_group': null,
          'installment_number': 1,
          'installment_count': 1,
          'created_at': '2026-09-05T00:00:00.000',
        },
      ],
      'goals': [],
      'settings': [],
    };

void main() {
  late TestDatabase opened;

  setUp(() async => opened = await TestDatabase.open());
  tearDown(() => opened.dispose());

  test('exporta e restaura o próprio snapshot sem alterações', () async {
    final repository = TransactionRepository(opened.database);
    await repository.create(
      FinanceTransaction(
        type: TransactionType.expense,
        amount: 99.9,
        categoryId: 4,
        accountId: 1,
        date: DateTime(2026, 9, 20),
        description: 'Mercado',
        createdAt: DateTime(2026, 9, 20),
      ),
    );
    final snapshot = await opened.database.exportSnapshot();
    expect(snapshot['schema_version'], AppConstants.databaseVersion);

    await opened.database.restoreSnapshot(snapshot);

    final restored = await repository.list();
    expect(restored.single.transaction.amount, 99.9);
    expect(restored.single.transaction.description, 'Mercado');
  });

  test('restaura backup da 0.5.0 convertendo para centavos', () async {
    await opened.database.restoreSnapshot(_backupFrom050());

    final transaction =
        (await TransactionRepository(opened.database).list()).single;
    expect(transaction.transaction.amount, 12.34);
    expect(transaction.categoryColor, CategoryPalette.defaults['Lazer']);
    final account = await opened.database.db.query('accounts');
    expect(account.single['initial_balance_cents'], 5025);
  });

  test('recusa backup de versão mais nova', () {
    final future = {
      ..._backupFrom050(),
      'schema_version': AppConstants.databaseVersion + 1,
    };
    expect(
      () => SnapshotMigrator.upgrade(future),
      throwsA(isA<SnapshotException>()),
    );
  });

  test('recusa backup incompleto sem apagar os dados atuais', () async {
    await expectLater(
      opened.database.restoreSnapshot({'schema_version': 3}),
      throwsA(isA<SnapshotException>()),
    );
    final categories = await opened.database.db.query('categories');
    expect(categories, isNotEmpty);
  });

  test('guarda cópia antes de restaurar e permite desfazer', () async {
    final repository = TransactionRepository(opened.database);
    await repository.create(
      FinanceTransaction(
        type: TransactionType.income,
        amount: 3000,
        categoryId: 1,
        accountId: 1,
        date: DateTime(2026, 9, 1),
        description: 'Salário',
        createdAt: DateTime(2026, 9, 1),
      ),
    );
    await opened.database.restoreSnapshot(_backupFrom050());
    expect(await opened.database.safetyCopyDate(), isNotNull);
    expect((await repository.list()).single.transaction.description, 'Cinema');

    await opened.database.restoreSafetyCopy();

    expect((await repository.list()).single.transaction.description, 'Salário');
    expect(await opened.database.safetyCopyDate(), isNull);
  });
}
