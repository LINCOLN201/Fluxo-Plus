import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;

/// No Android, o banco é cifrado com SQLCipher — ver [DatabaseKeyService].
/// Nas demais plataformas ainda não existe um `sqlite3` com SQLCipher
/// testado neste projeto (ver `docs/ROADMAP.md`), então o banco continua
/// sem cifra própria.
DatabaseFactory createDatabaseFactory() {
  if (Platform.isAndroid) {
    return sqlcipher.databaseFactory;
  }
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return databaseFactory;
}
