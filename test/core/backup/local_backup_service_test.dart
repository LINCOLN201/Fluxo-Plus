import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/backup/local_backup_service.dart';
import 'package:fluxo_plus/features/goals/data/goal_repository.dart';
import 'package:fluxo_plus/shared/models/goal.dart';

import '../../support/test_database.dart';

void main() {
  late TestDatabase opened;
  late LocalBackupService service;

  setUp(() async {
    opened = await TestDatabase.open();
    service = LocalBackupService(opened.database, iterations: 1000);
  });
  tearDown(() => opened.dispose());

  test('exporta criptografado e importa com a senha correta', () async {
    final goals = GoalRepository(opened.database);
    await goals.save(
      Goal(
        name: 'Carro novo',
        targetAmount: 40000,
        currentAmount: 1500.5,
        createdAt: DateTime(2026, 9, 1),
      ),
    );

    final file = await service.export('senha-forte');
    expect(utf8.decode(file), isNot(contains('Carro novo')));

    await goals.delete((await goals.list()).single.id!);
    await service.import(file, 'senha-forte');

    final restored = (await goals.list()).single;
    expect(restored.name, 'Carro novo');
    expect(restored.currentAmount, 1500.5);
  });

  test('senha errada não altera os dados', () async {
    final file = await service.export('senha-forte');
    await expectLater(
      service.import(file, 'outra-senha'),
      throwsA(
        isA<LocalBackupException>().having(
          (error) => error.message,
          'message',
          contains('Senha incorreta'),
        ),
      ),
    );
  });

  test('recusa arquivo que não é backup do Fluxo+', () async {
    await expectLater(
      service.import(Uint8List.fromList(utf8.encode('{"a":1}')), 'qualquer'),
      throwsA(isA<LocalBackupException>()),
    );
  });

  test('exige senha mínima', () async {
    await expectLater(
      service.export('123'),
      throwsA(isA<LocalBackupException>()),
    );
  });

  test('sugere nome de arquivo com a data', () {
    expect(
      service.suggestedFileName(DateTime(2026, 9, 4)),
      'fluxo-plus-2026-09-04.fluxobackup',
    );
  });
}
