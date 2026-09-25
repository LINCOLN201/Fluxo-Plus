import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/backup/local_backup_service.dart';
import 'package:fluxo_plus/core/premium/premium_service.dart';
import 'package:fluxo_plus/core/security/biometric_service.dart';
import 'package:fluxo_plus/core/security/identity_check.dart';
import 'package:fluxo_plus/core/security/pin_service.dart';
import 'package:fluxo_plus/core/security/screen_privacy_service.dart';
import 'package:fluxo_plus/core/sync/cloud_sync_service.dart';
import 'package:fluxo_plus/core/theme/app_theme.dart';
import 'package:fluxo_plus/core/update/update_service.dart';
import 'package:fluxo_plus/features/premium/presentation/premium_screen.dart';
import 'package:fluxo_plus/features/settings/presentation/settings_screen.dart';

import '../support/test_database.dart';

/// Renderiza as telas novas da 0.6.0 em tamanho de celular e desktop, nos
/// dois temas, garantindo que não há estouro de layout nem exceções.
void main() {
  late TestDatabase opened;

  setUpAll(() async {
    // Fonte real do app, para medir o texto como no aparelho.
    final bytes = File('assets/fonts/Manrope-Variable.ttf').readAsBytesSync();
    await (FontLoader('Manrope')
          ..addFont(Future.value(ByteData.sublistView(bytes))))
        .load();
  });

  setUp(() async => opened = await TestDatabase.open());
  tearDown(() => opened.dispose());

  Widget app(ThemeData theme, Widget home) => MaterialApp(
        theme: theme,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
  }

  for (final (name, theme) in [
    ('escuro', AppTheme.dark()),
    ('claro', AppTheme.light()),
  ]) {
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      final label = '$name ${size.width.toInt()}px';

      testWidgets('Premium mostra o plano atual ($label)', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final service = PremiumService(opened.database, null);
        await tester.pumpWidget(app(theme, PremiumScreen(service: service)));
        await settle(tester);
        expect(find.text('SEU PLANO ATUAL'), findsOneWidget);
        expect(find.text('Gratuito'), findsOneWidget);
        expect(find.text('Vitalício'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Configurações com backup e segurança ($label)',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          app(
            theme,
            SettingsScreen(
              themeMode: ThemeMode.dark,
              onThemeChanged: (_) {},
              cloudSyncService: CloudSyncService(opened.database, null),
              biometricEnabled: false,
              onBiometricChanged: (_) async => false,
              updateService: UpdateService(repository: ''),
              onDataChanged: () {},
              premiumService: PremiumService(opened.database, null),
              pinService: PinService(opened.database, iterations: 1000),
              onLockSettingsChanged: () {},
              localBackupService: LocalBackupService(opened.database),
              database: opened.database,
              onOpenPremium: () {},
              identityCheck: IdentityCheck(
                pinService: PinService(opened.database, iterations: 1000),
                biometricService: BiometricService(),
                biometricEnabled: () => false,
              ),
              screenPrivacyService: ScreenPrivacyService(opened.database),
            ),
          ),
        );
        await settle(tester);
        await tester.scrollUntilVisible(
          find.text('Backup local criptografado'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await settle(tester);
        await tester.scrollUntilVisible(
          find.text('Bloqueio por PIN'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Bloqueio por PIN'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
