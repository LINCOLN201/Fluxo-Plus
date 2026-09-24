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
  static const minLength = 4;
  static const maxLength = 8;
  static const maxAttempts = 5;
  static const lockout = Duration(seconds: 30);

  final AppDatabase _database;
  final int iterations;

  int _failures = 0;
  DateTime? _blockedUntil;

  Future<bool> isEnabled() async => await _read() != null;

  static bool isValid(String pin) =>
      pin.length >= minLength &&
      pin.length <= maxLength &&
      RegExp(r'^\d+$').hasMatch(pin);

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

  Future<bool> verify(String pin) async {
    if (blockedFor != null) return false;
    final stored = await _read();
    if (stored == null) return false;
    final hash = await _hash(
      pin,
      base64Decode(stored['salt'] as String),
      (stored['iterations'] as num).toInt(),
    );
    final expected = base64Decode(stored['hash'] as String);
    if (_constantTimeEquals(hash, expected)) {
      _failures = 0;
      _blockedUntil = null;
      return true;
    }
    _failures++;
    if (_failures >= maxAttempts) {
      _failures = 0;
      _blockedUntil = DateTime.now().add(lockout);
    }
    return false;
  }

  Future<void> clear() => _database.db.delete(
        'settings',
        where: 'key = ?',
        whereArgs: [_key],
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
