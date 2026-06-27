import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';

class CloudSyncService {
  CloudSyncService(this._database, this._client);

  final AppDatabase _database;
  final SupabaseClient? _client;

  bool get isConfigured => _client != null;
  User? get currentUser => _client?.auth.currentUser;

  Stream<AuthState>? get authChanges => _client?.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    _requireClient();
    await _client!.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    _requireClient();
    await _client!.auth.signUp(email: email, password: password);
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
    return DateTime.parse(row['updated_at'] as String).toLocal();
  }

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
}
