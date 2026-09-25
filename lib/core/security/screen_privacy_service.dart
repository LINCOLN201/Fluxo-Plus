import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

/// Esconde o conteúdo do app em capturas de tela, gravações e na miniatura
/// dos apps recentes (Android). Ligado por padrão.
class ScreenPrivacyService {
  ScreenPrivacyService(this._database);

  static const _channel = MethodChannel('br.com.fluxoplus.app/security');
  static const _key = 'secure_screen';

  final AppDatabase _database;

  bool get isSupported => Platform.isAndroid;

  Future<bool> isEnabled() async {
    final rows = await _database.db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_key],
      limit: 1,
    );
    return rows.isEmpty || rows.first['value'] != 'false';
  }

  Future<void> apply() async => _send(await isEnabled());

  Future<void> setEnabled(bool enabled) async {
    await _database.db.insert(
      'settings',
      {'key': _key, 'value': enabled ? 'true' : 'false'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _send(enabled);
  }

  Future<void> _send(bool enabled) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('setSecureScreen', {'enabled': enabled});
    } on MissingPluginException {
      // Sem a Activity nativa (ex.: testes), não há o que aplicar.
    }
  }
}
