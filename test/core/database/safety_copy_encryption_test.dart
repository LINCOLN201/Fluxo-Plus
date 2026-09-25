import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/features/transactions/data/transaction_repository.dart';
import 'package:fluxo_plus/shared/models/category.dart';
import 'package:fluxo_plus/shared/models/finance_transaction.dart';
import 'package:path/path.dart' as p;

import '../../support/test_database.dart';

void main() {
  test(
      'a cópia de segurança antes da restauração fica cifrada no disco, '
      'não em texto puro', () async {
    final opened = await TestDatabase.open();
    final repo = TransactionRepository(opened.database);
    await repo.create(
      FinanceTransaction(
        type: TransactionType.income,
        amount: 9999.99,
        categoryId: 1,
        accountId: 1,
        date: DateTime(2026, 9, 1),
        description: 'Salário confidencial',
        createdAt: DateTime(2026, 9, 1),
      ),
    );

    await opened.database.restoreSnapshot({
      'schema_version': 3,
      'accounts': [],
      'categories': [],
      'transactions': [],
      'goals': [],
      'settings': [],
    });

    final file = File(
      p.join(opened.directory.path, 'antes-da-restauracao.enc'),
    );
    // O conteúdo é binário cifrado: procuramos a sequência de bytes exata
    // (não texto) para provar que a frase e o valor não aparecem soltos em
    // nenhuma parte do arquivo, byte a byte.
    final bytes = await file.readAsBytes();
    bool containsBytes(List<int> needle) {
      outer:
      for (var i = 0; i <= bytes.length - needle.length; i++) {
        for (var j = 0; j < needle.length; j++) {
          if (bytes[i + j] != needle[j]) continue outer;
        }
        return true;
      }
      return false;
    }

    // Quem só tem acesso ao arquivo (sem o Keystore/cofre do aparelho) não
    // consegue ler nenhum dado financeiro nele.
    expect(containsBytes(utf8.encode('Salário confidencial')), isFalse);
    expect(containsBytes(utf8.encode('999999')), isFalse);

    // Mas "Desfazer" continua funcionando com um toque, sem pedir senha.
    await opened.database.restoreSafetyCopy();
    final restored = (await repo.list()).single;
    expect(restored.transaction.description, 'Salário confidencial');

    await opened.dispose();
  });
}
