import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/database/database_key_service.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('gera uma chave de 256 bits no formato bruto do SQLCipher', () async {
    final service = DatabaseKeyService();
    final key = await service.rawKey();

    expect(key, matches(RegExp(r"^x'[0-9a-f]{64}'$")));
  });

  test('reaproveita a mesma chave em vez de gerar outra a cada chamada',
      () async {
    final service = DatabaseKeyService();
    final first = await service.rawKey();
    final second = await service.rawKey();

    expect(second, first);
  });

  test('cada instância nova ainda lê a chave já guardada no armazenamento',
      () async {
    final first = await DatabaseKeyService().rawKey();
    final second = await DatabaseKeyService().rawKey();

    expect(second, first);
  });
}
