import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/security/pin_service.dart';

import '../../support/test_database.dart';

void main() {
  late TestDatabase opened;
  late PinService service;

  setUp(() async {
    opened = await TestDatabase.open();
    service = PinService(opened.database, iterations: 1000);
  });
  tearDown(() => opened.dispose());

  test('define, verifica e remove o PIN', () async {
    expect(await service.isEnabled(), isFalse);
    await service.setPin('2468');
    expect(await service.isEnabled(), isTrue);
    expect(await service.verify('2468'), isTrue);
    expect(await service.verify('1357'), isFalse);
    await service.clear();
    expect(await service.isEnabled(), isFalse);
  });

  test('não guarda o PIN em texto', () async {
    await service.setPin('2468');
    final rows = await opened.database.db.query('settings');
    expect(rows.map((row) => row['value']).join(), isNot(contains('2468')));
  });

  test('bloqueia após tentativas erradas', () async {
    await service.setPin('2468');
    for (var i = 0; i < PinService.maxAttempts; i++) {
      await service.verify('0000');
    }
    expect(service.blockedFor, isNotNull);
    expect(await service.verify('2468'), isFalse);
  });

  test('valida formato do PIN', () {
    expect(PinService.isValid('1234'), isTrue);
    expect(PinService.isValid('123'), isFalse);
    expect(PinService.isValid('12a4'), isFalse);
    expect(PinService.isValid('123456789'), isFalse);
  });
}
