import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../database/app_database.dart';

/// Backup local em arquivo, criptografado com uma senha escolhida pelo
/// usuário (PBKDF2-HMAC-SHA256 + AES-256-GCM). Recurso gratuito.
class LocalBackupService {
  LocalBackupService(this._database, {this.iterations = 200000});

  static const format = 'fluxo-plus-backup';
  static const fileExtension = 'fluxobackup';
  static const minPasswordLength = 10;

  final AppDatabase _database;

  /// Custo da derivação da senha. Fica gravado no arquivo, então pode ser
  /// aumentado no futuro sem quebrar backups antigos.
  final int iterations;

  String suggestedFileName([DateTime? now]) {
    final date = now ?? DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'fluxo-plus-${date.year}-${two(date.month)}-${two(date.day)}'
        '.$fileExtension';
  }

  Future<Uint8List> export(String password) async {
    final snapshot = await _database.exportSnapshot();
    return encrypt(utf8.encode(jsonEncode(snapshot)), password);
  }

  /// Substitui os dados atuais pelo backup. Uma cópia dos dados atuais é
  /// guardada antes, permitindo desfazer.
  Future<void> import(Uint8List file, String password) async {
    final plain = await decrypt(file, password);
    final Object? snapshot;
    try {
      snapshot = jsonDecode(utf8.decode(plain));
    } on FormatException {
      throw const LocalBackupException('Arquivo de backup corrompido.');
    }
    if (snapshot is! Map) {
      throw const LocalBackupException('Arquivo de backup corrompido.');
    }
    await _database.restoreSnapshot(Map<String, dynamic>.from(snapshot));
  }

  Future<Uint8List> encrypt(List<int> plain, String password) async {
    _checkPassword(password);
    final salt = SecretKeyData.random(length: 16).bytes;
    final key = await _deriveKey(password, salt, iterations);
    final box = await AesGcm.with256bits().encrypt(plain, secretKey: key);
    final envelope = {
      'format': format,
      'version': 1,
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'ciphertext': base64Encode(box.cipherText),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<List<int>> decrypt(Uint8List file, String password) async {
    final Map<String, dynamic> envelope;
    try {
      envelope = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(file)) as Map,
      );
    } catch (_) {
      throw const LocalBackupException(
        'Este arquivo não é um backup do Fluxo+.',
      );
    }
    if (envelope['format'] != format) {
      throw const LocalBackupException(
        'Este arquivo não é um backup do Fluxo+.',
      );
    }
    if (envelope['version'] != 1) {
      throw const LocalBackupException(
        'Backup criado por uma versão mais nova do Fluxo+. '
        'Atualize o aplicativo.',
      );
    }
    try {
      final key = await _deriveKey(
        password,
        base64Decode(envelope['salt'] as String),
        (envelope['iterations'] as num).toInt(),
      );
      return await AesGcm.with256bits().decrypt(
        SecretBox(
          base64Decode(envelope['ciphertext'] as String),
          nonce: base64Decode(envelope['nonce'] as String),
          mac: Mac(base64Decode(envelope['mac'] as String)),
        ),
        secretKey: key,
      );
    } on SecretBoxAuthenticationError {
      throw const LocalBackupException(
        'Senha incorreta ou arquivo corrompido.',
      );
    } on LocalBackupException {
      rethrow;
    } catch (_) {
      throw const LocalBackupException('Arquivo de backup corrompido.');
    }
  }

  void _checkPassword(String password) {
    if (password.length < minPasswordLength) {
      throw const LocalBackupException(
        'Use uma senha com pelo menos $minPasswordLength caracteres.',
      );
    }
  }

  /// A derivação é pesada de propósito; roda fora da thread da interface.
  static Future<SecretKey> _deriveKey(
    String password,
    List<int> salt,
    int iterations,
  ) async {
    final bytes = await Isolate.run(() async {
      final key = await Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: 256,
      ).deriveKeyFromPassword(password: password, nonce: salt);
      return key.extractBytes();
    });
    return SecretKey(bytes);
  }
}

class LocalBackupException implements Exception {
  const LocalBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
