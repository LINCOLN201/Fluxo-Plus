import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Reporta falhas para o Firebase Crashlytics, quando configurado — mesmo
/// padrão "opcional" do resto do Firebase no app: sem
/// `google-services.json`, [attach] simplesmente não é chamado e essas
/// chamadas nunca acontecem.
///
/// Existe porque um crash de produção só chegou ao conhecimento de quem
/// mantém o app porque a pessoa avisou manualmente, dias depois, já com
/// dados perdidos — antes disso não havia nenhum relatório de erro.
class ErrorReporter {
  ErrorReporter._();

  static bool _ready = false;

  /// Liga os manipuladores globais de erro. Chamado uma única vez, só depois
  /// que o Firebase já foi inicializado com sucesso (ver
  /// `PushNotificationService.initialize`).
  static void attach() {
    if (_ready) return;
    _ready = true;
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      previousOnError?.call(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Registra um erro já tratado (ex.: uma falha de rede ignorada da
  /// interface) sem mudar o comportamento existente nem interromper o fluxo.
  static void record(Object error, StackTrace stackTrace, {String? reason}) {
    if (!_ready) return;
    unawaited(
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      ),
    );
  }
}
