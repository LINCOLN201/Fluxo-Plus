import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

class CloudSyncService {
  CloudSyncService(this._database, this._client);

  final AppDatabase _database;
  final SupabaseClient? _client;
  static const confirmationRedirect =
      'https://github.com/LINCOLN201/Fluxo-Plus';

  bool get isConfigured => _client != null;
  User? get currentUser => _client?.auth.currentUser;

  Stream<AuthState>? get authChanges => _client?.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    _requireClient();
    try {
      await _client!.auth.signInWithPassword(email: email, password: password);
      await synchronize();
    } on AuthException catch (error) {
      throw CloudSyncException(_friendlyAuthMessage(error.message));
    } catch (_) {
      throw const CloudSyncException(
        'Não foi possível conectar. Verifique sua internet e tente novamente.',
      );
    }
  }

  Future<void> signUp(String email, String password) async {
    _requireClient();
    try {
      await _client!.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: confirmationRedirect,
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
      await synchronize();
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
    await _saveLastSync(now);
    return now;
  }

  Future<DateTime> restoreBackup() async {
    final user = _requireUser();
    final row = await _client!
        .from('user_backups')
        .select('payload, updated_at')
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) {
      throw StateError('Nenhum backup encontrado nesta conta.');
    }
    await _database.restoreSnapshot(
      Map<String, dynamic>.from(row['payload'] as Map),
    );
    final updatedAt = DateTime.parse(row['updated_at'] as String).toLocal();
    await _saveLastSync(DateTime.now());
    return updatedAt;
  }

  Future<DateTime?> lastSyncAt() async {
    final rows = await _database.db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['last_sync_at'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['value'] as String);
  }

  Future<SyncResult> synchronize() async {
    final user = _requireUser();
    final row = await _client!
        .from('user_backups')
        .select('payload, updated_at')
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) {
      return SyncResult(SyncDirection.uploaded, await uploadBackup());
    }

    final cloudUpdated = DateTime.parse(row['updated_at'] as String).toLocal();
    final lastSync = await lastSyncAt();
    if (lastSync == null ||
        cloudUpdated.isAfter(lastSync.add(const Duration(seconds: 2)))) {
      await _database.restoreSnapshot(
        Map<String, dynamic>.from(row['payload'] as Map),
      );
      final now = DateTime.now();
      await _saveLastSync(now);
      return SyncResult(SyncDirection.downloaded, cloudUpdated);
    }
    return SyncResult(SyncDirection.uploaded, await uploadBackup());
  }

  Future<void> _saveLastSync(DateTime value) => _database.db.insert(
        'settings',
        {
          'key': 'last_sync_at',
          'value': value.toLocal().toIso8601String(),
        },
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

enum SyncDirection { uploaded, downloaded }

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
