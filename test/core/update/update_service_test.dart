import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/update/update_service.dart';

void main() {
  test('fica desativado sem repositório configurado', () {
    final service = UpdateService(repository: '');
    expect(service.isConfigured, isFalse);
    service.close();
  });

  test('aceita owner e nome de repositório', () {
    final service = UpdateService(repository: 'fluxo-plus/fluxo-plus');
    expect(service.isConfigured, isTrue);
    service.close();
  });

  test('só confia em downloads do GitHub via HTTPS', () {
    expect(
      UpdateService.isTrustedDownload(
        Uri.parse('https://github.com/o/r/releases/download/v1/a.apk'),
      ),
      isTrue,
    );
    expect(
      UpdateService.isTrustedDownload(Uri.parse('http://github.com/a.apk')),
      isFalse,
    );
    expect(
      UpdateService.isTrustedDownload(Uri.parse('https://github.com.evil.io')),
      isFalse,
    );
  });

  test('lê o hash no formato do sha256sum', () {
    const hash =
        'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855';
    expect(
      UpdateService.parseChecksum('$hash  fluxo-plus-android.apk\n'),
      hash.toLowerCase(),
    );
    expect(UpdateService.parseChecksum('sem hash'), isNull);
  });

  test('calcula SHA-256 em partes', () async {
    expect(
      await UpdateService.sha256Hex(
        Stream.fromIterable([
          'ab'.codeUnits,
          'c'.codeUnits,
        ]),
      ),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
}
