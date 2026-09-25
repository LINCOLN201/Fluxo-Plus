import 'dart:convert';
import 'dart:isolate';

import 'package:cryptography/cryptography.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

/// PIN de desbloqueio do app. Só o hash (PBKDF2 com sal) é guardado, e ele
/// nunca sai do aparelho: `settings` não entra nos backups.
class PinService {
  PinService(this._database, {this.iterations = 60000});

  static const _key = 'pin_hash';
  static const _failuresKey = 'pin_failures';
  static const _blockedKey = 'pin_blocked_until';
  static const minLength = 4;
  static const maxLength = 8;

  /// Tentativas livres antes do primeiro bloqueio.
  static const maxAttempts = 5;
  static const lockout = Duration(seconds: 30);
  static const maxLockout = Duration(hours: 1);

  final AppDatabase _database;
  final int iterations;

  DateTime? _blockedUntil;

  Future<bool> isEnabled() async => await _read() != null;

  static bool isValid(String pin) =>
      pin.length >= minLength &&
      pin.length <= maxLength &&
      RegExp(r'^\d+$').hasMatch(pin);

  /// Espera após erros seguidos: 30 s no 5º erro, dobrando a cada novo erro
  /// até 1 hora. Fica gravada no banco, então fechar e abrir o app não zera.
  static Duration? lockoutFor(int failures) {
    if (failures < maxAttempts) return null;
    final doublings = failures - maxAttempts;
    final seconds = lockout.inSeconds * (1 << doublings.clamp(0, 12));
    return Duration(seconds: seconds.clamp(0, maxLockout.inSeconds));
  }

  /// Carrega o bloqueio gravado (chamar antes de mostrar a tela de PIN).
  Future<void> loadLockout() async {
    final value = await _readSetting(_blockedKey);
    _blockedUntil = value == null ? null : DateTime.tryParse(value);
  }

  /// Tempo restante de espera após muitas tentativas erradas.
  Duration? get blockedFor {
    final until = _blockedUntil;
    if (until == null) return null;
    final left = until.difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  Future<void> setPin(String pin) async {
    if (!isValid(pin)) {
      throw ArgumentError('O PIN deve ter de $minLength a $maxLength números.');
    }
    final salt = SecretKeyData.random(length: 16).bytes;
    final hash = await _hash(pin, salt, iterations);
    await _database.db.insert(
      'settings',
      {
        'key': _key,
        'value': jsonEncode({
          'iterations': iterations,
          'salt': base64Encode(salt),
          'hash': base64Encode(hash),
        }),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Verifica o PIN. Duas ou mais chamadas concorrentes (um script de ataque
  /// disparando tentativas em paralelo, por exemplo) não conseguem furar o
  /// limite: a leitura e a gravação do contador de erros acontecem dentro de
  /// uma única transação do SQLite, que serializa chamadas simultâneas.
  Future<bool> verify(String pin) async {
    await loadLockout();
    if (blockedFor != null) return false;
    final stored = await _read();
    if (stored == null) return false;
    final hash = await _hash(
      pin,
      base64Decode(stored['salt'] as String),
      (stored['iterations'] as num).toInt(),
    );
    final expected = base64Decode(stored['hash'] as String);
    final matches = _constantTimeEquals(hash, expected);

    return _database.db.transaction((txn) async {
      // Reconfere o bloqueio dentro da transação: outra tentativa concorrente
      // pode ter acabado de bloquear enquanto o hash acima era calculado.
      final blockedValue = await _readSetting(_blockedKey, txn);
      final blockedUntil =
          blockedValue == null ? null : DateTime.tryParse(blockedValue);
      if (blockedUntil != null && blockedUntil.isAfter(DateTime.now())) {
        _blockedUntil = blockedUntil;
        return false;
      }

      if (matches) {
        await _resetFailures(txn);
        return true;
      }

      final failures =
          (int.tryParse(await _readSetting(_failuresKey, txn) ?? '') ?? 0) + 1;
      await _writeSetting(_failuresKey, '$failures', txn);
      final wait = lockoutFor(failures);
      if (wait != null) {
        _blockedUntil = DateTime.now().add(wait);
        await _writeSetting(_blockedKey, _blockedUntil!.toIso8601String(), txn);
      }
      return false;
    });
  }

  Future<void> clear() async {
    await _database.db.delete(
      'settings',
      where: 'key = ?',
      whereArgs: [_key],
    );
    await _resetFailures();
  }

  Future<void> _resetFailures([DatabaseExecutor? executor]) async {
    _blockedUntil = null;
    await (executor ?? _database.db).delete(
      'settings',
      where: 'key IN (?, ?)',
      whereArgs: [_failuresKey, _blockedKey],
    );
  }

  Future<String?> _readSetting(String key, [DatabaseExecutor? executor]) async {
    final rows = await (executor ?? _database.db).query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> _writeSetting(
    String key,
    String value, [
    DatabaseExecutor? executor,
  ]) =>
      (executor ?? _database.db).insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<Map<String, dynamic>?> _read() async {
    final rows = await _database.db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(
      jsonDecode(rows.first['value'] as String) as Map,
    );
  }

  static Future<List<int>> _hash(
    String pin,
    List<int> salt,
    int iterations,
  ) =>
      Isolate.run(() async {
        final key = await Pbkdf2(
          macAlgorithm: Hmac.sha256(),
          iterations: iterations,
          bits: 256,
        ).deriveKeyFromPassword(password: pin, nonce: salt);
        return key.extractBytes();
      });

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
