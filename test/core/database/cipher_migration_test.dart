import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A conversão de verdade para SQLCipher só existe numa build Android real
/// (ver `AppDatabase.migrateToCipherIfNeeded`); aqui testamos só as decisões
/// de quando ela deve ou não mexer no arquivo, que não dependem do
/// SQLCipher nativo.
void main() {
  late Directory dir;
  late AppDatabase database;

  setUp(() async {
    sqfliteFfiInit();
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('fluxo_plus_cipher_test_');
    database = AppDatabase(databaseFactoryFfi);
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('não faz nada quando o banco ainda não existe (instalação nova)',
      () async {
    final path = p.join(dir.path, 'novo.db');
    await database.migrateToCipherIfNeeded(path, "x'00'");
    expect(await File(path).exists(), isFalse);
  });

  test('não mexe num arquivo que já não parece um SQLite em texto puro',
      () async {
    final path = p.join(dir.path, 'ja-cifrado.db');
    // Um arquivo já cifrado (ou qualquer coisa que não seja SQLite puro)
    // começa com bytes que não batem com o cabeçalho "SQLite format 3".
    await File(path).writeAsBytes(List<int>.filled(32, 0xAB));
    final before = await File(path).readAsBytes();

    await database.migrateToCipherIfNeeded(path, "x'00'");

    expect(await File(path).readAsBytes(), equals(before));
    expect(await File('$path.pre-cipher-backup').exists(), isFalse);
    expect(await File('$path.cipher-tmp').exists(), isFalse);
  });
}
