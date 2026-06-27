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
}
