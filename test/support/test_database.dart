import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluxo_plus/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Banco SQLite real (via FFI) em um diretório temporário exclusivo do teste.
class TestDatabase {
  TestDatabase._(this.directory, this.database);

  final Directory directory;
  final AppDatabase database;

  String get path => p.join(directory.path, 'fluxo_plus.db');

  static Future<TestDatabase> open({Directory? directory}) async {
    sqfliteFfiInit();
    // A cópia de segurança antes de restaurar usa o armazenamento seguro do
    // sistema; nos testes não há Keystore/cofre real, então usamos o mock.
    FlutterSecureStorage.setMockInitialValues({});
    final dir =
        directory ?? await Directory.systemTemp.createTemp('fluxo_plus_test_');
    final database = AppDatabase(databaseFactoryFfi);
    await database.initialize(
      path: p.join(dir.path, 'fluxo_plus.db'),
      directory: dir.path,
    );
    return TestDatabase._(dir, database);
  }

  Future<void> dispose() async {
    await database.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
