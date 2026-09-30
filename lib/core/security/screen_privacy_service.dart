import 'dart:io';

import 'package:flutter/services.dart';

/// Esconde o conteúdo do app em capturas de tela, gravações e na miniatura
/// dos apps recentes (Android). Sempre ligado — não é uma opção do usuário,
/// é parte da segurança do app (dados financeiros não devem parar num
/// print ou numa gravação de tela por engano).
class ScreenPrivacyService {
  static const _channel = MethodChannel('br.com.fluxoplus.app/security');

  bool get isSupported => Platform.isAndroid;

  Future<void> apply() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod('setSecureScreen', {'enabled': true});
    } on MissingPluginException {
      // Sem a Activity nativa (ex.: testes), não há o que aplicar.
    }
  }
}
