import 'dart:async';
import 'dart:ui' show Color;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificação de "chegou atualização", mesmo com o app fechado.
///
/// Usa um único tópico do Firebase Cloud Messaging (`atualizacoes`), sem
/// conta nem identificação de quem instalou: o app se inscreve sozinho e o
/// workflow de publicação manda um aviso para o tópico a cada versão nova
/// (ver `.github/workflows/release.yml`).
///
/// Sem `android/app/google-services.json` no build (Firebase não
/// configurado), tudo aqui vira um não-fazer-nada silencioso — o app
/// continua 100% funcional e offline, só sem esse aviso.
class PushNotificationService {
  static const topic = 'atualizacoes';
  static const _channelId = 'atualizacoes';
  static const _updateActionKey = 'update';

  final _tapController = StreamController<void>.broadcast();
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Dispara sempre que a pessoa toca numa notificação de atualização —
  /// com o app aberto, em segundo plano ou completamente fechado.
  Stream<void> get onUpdateTapped => _tapController.stream;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (error) {
      debugPrint('Notificações push desativadas: $error');
      return;
    }

    await _initLocalNotifications();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    unawaited(messaging.subscribeToTopic(topic));

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp
        .listen((_) => _tapController.add(null));

    final openedFromTerminated = await messaging.getInitialMessage();
    if (openedFromTerminated != null) _tapController.add(null);

    _ready = true;
  }

  Future<void> _initLocalNotifications() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      'Atualizações do Fluxo+',
      'Avisa quando uma nova versão do app está disponível.',
      importance: Importance.defaultImportance,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_fluxo'),
      ),
      onSelectNotification: (payload) async {
        if (payload == _updateActionKey) _tapController.add(null);
      },
    );
  }

  /// FCM só mostra a notificação sozinho quando o app está em segundo plano
  /// ou fechado; com o app aberto, mostramos manualmente para o aviso
  /// aparecer sempre do mesmo jeito.
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!_ready) return;
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Atualizações do Fluxo+',
          'Avisa quando uma nova versão do app está disponível.',
          icon: 'ic_stat_fluxo',
          color: Color(0xFFC6FF5E),
          priority: Priority.high,
        ),
      ),
      payload: _updateActionKey,
    );
  }

  Future<void> dispose() async {
    await _tapController.close();
  }
}
