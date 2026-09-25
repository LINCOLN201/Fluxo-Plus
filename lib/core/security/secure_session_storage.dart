import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Guarda a sessão da conta (tokens de acesso) no armazenamento seguro do
/// sistema — Keystore no Android, cofre de credenciais no Windows — em vez
/// das preferências comuns, que ficam em texto puro.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    required this.key,
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  /// Mesma chave que o supabase_flutter usa por padrão, para migrar a sessão
  /// já existente sem obrigar o usuário a entrar de novo.
  static String defaultKey(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  final String key;
  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {
    // Move a sessão salva pelas versões anteriores para o armazenamento
    // seguro e apaga a cópia em texto puro.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(key);
    if (legacy == null) return;
    if (await _storage.read(key: key) == null) {
      await _storage.write(key: key, value: legacy);
    }
    await prefs.remove(key);
  }

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: key);

  @override
  Future<String?> accessToken() => _storage.read(key: key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: key, value: persistSessionString);
}
