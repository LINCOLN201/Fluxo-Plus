import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/update/app_update.dart';
import 'package:fluxo_plus/core/update/update_prompt.dart';
import 'package:fluxo_plus/core/update/update_service.dart';

void main() {
  testWidgets('exibe popup de nova versão sobre o Navigator', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final service = UpdateService(repository: 'LINCOLN201/Fluxo-Plus');

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('Fluxo+')),
      ),
    );

    unawaited(
      showUpdatePrompt(
        navigatorKey.currentContext!,
        update: AppUpdate(
          version: '9.9.9',
          releaseUrl: Uri.parse('https://example.com/release'),
          downloadUrl: Uri.parse('https://example.com/app.apk'),
          notes: 'Nova versão de teste',
          mandatory: false,
        ),
        service: service,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fluxo+ 9.9.9 disponível'), findsOneWidget);
    expect(find.text('Baixar atualização'), findsOneWidget);
    service.close();
  });
}
