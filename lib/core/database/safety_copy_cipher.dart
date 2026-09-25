import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Criptografa a cópia de segurança gravada antes de qualquer restauração.
///
/// Diferente do backup local (que usa a senha do usuário), esta cópia
/// precisa ser lida sem pedir nada — é o "desfazer" de um toque só. A chave
/// fica no armazenamento seguro do sistema (o mesmo Keystore/cofre usado
/// para a sessão da conta), nunca no arquivo em si.
class SafetyCopyCipher {
  SafetyCopyCipher(
      {FlutterSecureStorage storage = const FlutterSecureStorage()})
      : _storage = storage;

  static const _keyName = 'safety_copy_key';

  final FlutterSecureStorage _storage;

  Future<Uint8List> encrypt(String plainText) async {
    final key = await _secretKey();
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(plainText),
      secretKey: key,
    );
    // nonce + mac + texto cifrado, tudo em um único arquivo binário.
    return Uint8List.fromList([
      ...box.nonce,
      ...box.mac.bytes,
      ...box.cipherText,
    ]);
  }

  Future<String> decrypt(Uint8List data) async {
    const nonceLength = 12;
    const macLength = 16;
    if (data.length < nonceLength + macLength) {
      throw const FormatException('Cópia de segurança corrompida.');
    }
    final key = await _secretKey();
    final plain = await AesGcm.with256bits().decrypt(
      SecretBox(
        data.sublist(nonceLength + macLength),
        nonce: data.sublist(0, nonceLength),
        mac: Mac(data.sublist(nonceLength, nonceLength + macLength)),
      ),
      secretKey: key,
    );
    return utf8.decode(plain);
  }

  Future<SecretKey> _secretKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) {
      return SecretKey(base64Decode(existing));
    }
    final generated = await AesGcm.with256bits().newSecretKey();
    final bytes = await generated.extractBytes();
    await _storage.write(key: _keyName, value: base64Encode(bytes));
    return generated;
  }
}
