import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gera e guarda a chave que cifra o banco de dados local (SQLCipher,
/// só Android por enquanto — ver `docs/ROADMAP.md`).
///
/// Um segredo de 256 bits gerado no aparelho, não uma senha do usuário: fica
/// só no Keystore e o app precisa conseguir abrir o banco sozinho, sem
/// perguntar nada, toda vez que inicia.
class DatabaseKeyService {
  DatabaseKeyService({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const _keyName = 'database_encryption_key';

  final FlutterSecureStorage _storage;

  /// Chave no formato bruto do SQLCipher (`x'...'`): sem derivação por
  /// senha, já é um segredo de 256 bits gerado no aparelho.
  Future<String> rawKey() async {
    final existing = await _storage.read(key: _keyName);
    final hex = existing ?? await _generate();
    return "x'$hex'";
  }

  Future<String> _generate() async {
    final generated = await AesGcm.with256bits().newSecretKey();
    final bytes = await generated.extractBytes();
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _storage.write(key: _keyName, value: hex);
    return hex;
  }
}
