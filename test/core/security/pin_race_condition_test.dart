import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/security/pin_service.dart';

import '../../support/test_database.dart';

void main() {
  test(
      'condição de corrida: várias tentativas em paralelo não furam o '
      'limite de tentativas', () async {
    final opened = await TestDatabase.open();
    final service = PinService(opened.database, iterations: 500);
    await service.setPin('2468');

    // Dispara o dobro do limite de tentativas erradas, todas ao mesmo tempo
    // (sem "await" entre elas), como um script de ataque faria para tentar
    // ganhar a corrida contra a gravação do contador no banco.
    final results = await Future.wait(
      List.generate(PinService.maxAttempts * 2, (_) => service.verify('0000')),
    );
    // ignore: avoid_print
    print('Tentativas erradas disparadas: ${results.length}');
    // ignore: avoid_print
    print('Todas recusadas? ${results.every((ok) => !ok)}');
    expect(results, everyElement(isFalse));

    // Depois da rajada, o PIN certo deve continuar recusado: o bloqueio
    // precisa ter engatilhado mesmo com as gravações do contador disputando
    // a mesma linha do banco ao mesmo tempo.
    final afterBurst = await service.verify('2468');
    expect(afterBurst, isFalse);
    expect(service.blockedFor, isNotNull);

    await opened.dispose();
  });
}
