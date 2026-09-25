import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/security/secure_session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'sb-projeto-auth-token';

  test('usa a mesma chave padrão do supabase_flutter', () {
    expect(
      SecureSessionStorage.defaultKey('https://projeto.supabase.co'),
      key,
    );
  });

  test('migra a sessão em texto puro e apaga a cópia antiga', () async {
    SharedPreferences.setMockInitialValues({key: '{"token":"abc"}'});
    FlutterSecureStorage.setMockInitialValues({});
    final storage = SecureSessionStorage(key: key);

    await storage.initialize();

    expect(await storage.accessToken(), '{"token":"abc"}');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(key), isFalse);
  });

  test('grava, lê e remove a sessão', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final storage = SecureSessionStorage(key: key);
    await storage.initialize();

    expect(await storage.hasAccessToken(), isFalse);
    await storage.persistSession('sessao');
    expect(await storage.accessToken(), 'sessao');
    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
  });
}
