import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

class CloudSyncService {
  CloudSyncService(this._database, this._client);

  final AppDatabase _database;
  final SupabaseClient? _client;
  static const confirmationRedirect =
      'https://lincoln201.github.io/Fluxo-Plus/confirmado.html';

  bool get isConfigured => _client != null;
  User? get currentUser => _client?.auth.currentUser;

  /// Primeiro nome para a saudação: o da conta ou, sem nome cadastrado,
  /// a primeira parte do e-mail sem números ("lincolnqueiroz201" → "Lincolnqueiroz").
  String? get displayName {
    final user = currentUser;
    if (user == null) return null;
    final metadata = user.userMetadata;
    final value = metadata?['full_name'] ?? metadata?['name'];
    if (value is String) {
      final name = firstName(value);
      if (name != null) return name;
    }
    return firstName(user.email?.split('@').first ?? '');
  }

  static const _nameKey = 'display_name';

  /// Nome escolhido pelo usuário em Configurações; na falta dele, o da conta.
  Future<String?> preferredName() async =>
      firstName(await _readSetting(_nameKey) ?? '') ?? displayName;

  Future<void> savePreferredName(String name) async {
    final value = name.trim();
    if (value.isEmpty) {
      await _database.db.delete(
        'settings',
        where: 'key = ?',
        whereArgs: [_nameKey],
      );
      return;
    }
    await _writeSetting(_nameKey, value);
    if (currentUser == null) return;
    try {
      await _client!.auth.updateUser(
        UserAttributes(data: {'full_name': value}),
      );
    } catch (_) {
      // Sem internet o nome continua salvo neste aparelho.
    }
  }

  /// Primeira palavra, sem números nem separadores, com inicial maiúscula.
  static String? firstName(String value) {
    final word = value
        .replaceAll(RegExp(r'[0-9._\-+]+'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .first;
    if (word.isEmpty) return null;
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }

  Stream<AuthState>? get authChanges => _client?.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    _requireClient();
    try {
      await _client!.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw CloudSyncException(_friendlyAuthMessage(error.message));
    } catch (_) {
      throw const CloudSyncException(
        'Não foi possível conectar. Verifique sua internet e tente novamente.',
      );
    }
  }

  Future<void> signUp(
    String email,
    String password, {
    String? name,
  }) async {
    _requireClient();
    try {
      await _client!.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: confirmationRedirect,
        data: name == null || name.trim().isEmpty
            ? null
            : {'full_name': name.trim()},
      );
    } on AuthException catch (error) {
      throw CloudSyncException(_friendlyAuthMessage(error.message));
    } catch (_) {
      throw const CloudSyncException(
        'Não foi possível criar a conta. Verifique sua internet.',
      );
    }
  }

  Future<void> resendConfirmation(String email) async {
    _requireClient();
    try {
      await _client!.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: confirmationRedirect,
      );
    } on AuthException catch (error) {
      throw CloudSyncException(_friendlyAuthMessage(error.message));
    } catch (_) {
      throw const CloudSyncException(
        'Não foi possível reenviar. Verifique sua internet.',
      );
    }
  }

  Future<void> verifyEmailCode(String email, String code) async {
    _requireClient();
    try {
      await _client!.auth.verifyOTP(
        email: email,
        token: code.trim(),
        type: OtpType.signup,
      );
    } on AuthException catch (error) {
      throw CloudSyncException(_friendlyAuthMessage(error.message));
    } catch (_) {
      throw const CloudSyncException(
        'Não foi possível validar o código. Verifique sua internet.',
      );
    }
  }

  Future<void> signOut() async => _client?.auth.signOut();

  Future<DateTime> uploadBackup() async {
    final user = _requireUser();
    final now = DateTime.now().toUtc();
    await _client!.from('user_backups').upsert({
      'user_id': user.id,
      'payload': await _database.exportSnapshot(),
      'updated_at': now.toIso8601String(),
    });
    await _saveLastSync(user.id, now);
    return now;
  }

  /// Traz o backup da nuvem para este aparelho, substituindo os dados locais
  /// (uma cópia deles é guardada antes, permitindo desfazer).
  Future<DateTime> restoreBackup() async {
    final user = _requireUser();
    final row = await _fetchBackup(user.id);
    if (row == null) {
      throw StateError('Nenhum backup encontrado nesta conta.');
    }
    return _download(user.id, row);
  }

  Future<DateTime?> lastSyncAt() async {
    final value = await _readSetting(_lastSyncKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  /// O aparelho nunca sobrescreve a nuvem, nem a nuvem o aparelho, sem
  /// saber que isso é seguro. Quando os dois lados mudaram desde a última
  /// sincronização deste aparelho, devolve [SyncDirection.conflict] e a
  /// escolha fica com o usuário ([resolution]).
  Future<SyncResult> synchronize({SyncResolution? resolution}) async {
    final user = _requireUser();
    final row = await _fetchBackup(user.id);
    final action = SyncPlanner.decide(
      cloudUpdatedAt: row == null ? null : _parseCloudDate(row),
      hasLocalData: await _database.hasLocalData(),
      knownCloudVersion: await _knownCloudVersion(user.id),
      resolution: resolution,
    );
    return switch (action) {
      SyncAction.upload =>
        SyncResult(SyncDirection.uploaded, await uploadBackup()),
      SyncAction.download =>
        SyncResult(SyncDirection.downloaded, await _download(user.id, row!)),
      SyncAction.conflict =>
        SyncResult(SyncDirection.conflict, _parseCloudDate(row!).toLocal()),
    };
  }

  Future<Map<String, dynamic>?> _fetchBackup(String userId) => _client!
      .from('user_backups')
      .select('payload, updated_at')
      .eq('user_id', userId)
      .maybeSingle();

  Future<DateTime> _download(String userId, Map<String, dynamic> row) async {
    await _database.restoreSnapshot(
      Map<String, dynamic>.from(row['payload'] as Map),
    );
    final cloudUpdatedAt = _parseCloudDate(row);
    await _saveLastSync(userId, cloudUpdatedAt);
    return cloudUpdatedAt.toLocal();
  }

  static DateTime _parseCloudDate(Map<String, dynamic> row) =>
      DateTime.parse(row['updated_at'] as String).toUtc();

  static const _lastSyncKey = 'last_sync_at';
  static const _knownVersionKey = 'cloud_known_version';

  /// Versão da nuvem que este aparelho conhece (enviou ou baixou por último),
  /// vinculada ao usuário: trocar de conta não herda o estado anterior.
  Future<DateTime?> _knownCloudVersion(String userId) async {
    final value = await _readSetting(_knownVersionKey);
    if (value == null) return null;
    try {
      final data = jsonDecode(value) as Map;
      if (data['user_id'] != userId) return null;
      return DateTime.tryParse(data['updated_at'] as String);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLastSync(String userId, DateTime cloudVersion) async {
    await _writeSetting(_lastSyncKey, DateTime.now().toIso8601String());
    await _writeSetting(
      _knownVersionKey,
      jsonEncode({
        'user_id': userId,
        'updated_at': cloudVersion.toUtc().toIso8601String(),
      }),
    );
  }

  Future<String?> _readSetting(String key) async {
    final rows = await _database.db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> _writeSetting(String key, String value) => _database.db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  SupabaseClient _requireClient() {
    if (_client == null) {
      throw StateError('Supabase ainda não foi configurado.');
    }
    return _client;
  }

  User _requireUser() {
    _requireClient();
    final user = _client!.auth.currentUser;
    if (user == null) throw StateError('Entre na sua conta primeiro.');
    return user;
  }

  String _friendlyAuthMessage(String message) {
    final value = message.toLowerCase();
    if (value.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (value.contains('email not confirmed')) {
      return 'Confirme o e-mail recebido antes de entrar.';
    }
    if (value.contains('already registered') ||
        value.contains('already been registered')) {
      return 'Este e-mail já possui uma conta.';
    }
    if (value.contains('rate limit')) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    if (value.contains('token') &&
        (value.contains('expired') || value.contains('invalid'))) {
      return 'Código inválido ou expirado. Solicite um novo código.';
    }
    if (value.contains('password')) {
      return 'A senha não atende aos requisitos de segurança.';
    }
    return 'Não foi possível autenticar: $message';
  }
}

enum SyncDirection { uploaded, downloaded, conflict }

/// Escolha do usuário quando aparelho e nuvem mudaram ao mesmo tempo.
enum SyncResolution { keepLocal, useCloud }

enum SyncAction { upload, download, conflict }

/// Regra de decisão da sincronização, separada para ser testável.
abstract final class SyncPlanner {
  static SyncAction decide({
    required DateTime? cloudUpdatedAt,
    required bool hasLocalData,
    required DateTime? knownCloudVersion,
    SyncResolution? resolution,
  }) {
    if (cloudUpdatedAt == null) return SyncAction.upload;
    if (resolution == SyncResolution.useCloud) return SyncAction.download;
    if (resolution == SyncResolution.keepLocal) return SyncAction.upload;
    // Aparelho novo ou vazio: só recebe.
    if (!hasLocalData) return SyncAction.download;
    // A nuvem ainda é a versão que este aparelho conhece: enviar é seguro.
    if (knownCloudVersion != null &&
        cloudUpdatedAt.isAtSameMomentAs(knownCloudVersion)) {
      return SyncAction.upload;
    }
    return SyncAction.conflict;
  }
}

class SyncResult {
  const SyncResult(this.direction, this.at);

  final SyncDirection direction;
  final DateTime at;
}

class CloudSyncException implements Exception {
  const CloudSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}
