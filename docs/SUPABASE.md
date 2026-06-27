# Supabase: autenticação, sincronização e backup

O Fluxo+ continua offline-first. O Supabase é opcional e armazena um snapshot
JSON do banco local por usuário. Cada usuário só acessa o próprio backup por
meio de Row Level Security (RLS).

## Configuração

1. Crie um projeto no Supabase.
2. Abra o SQL Editor e execute `supabase/schema.sql`.
3. Em Authentication, habilite Email/Password.
4. Copie a Project URL e a Publishable Key.
5. Para um build local:

```powershell
flutter build apk --release `
  --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=SUA_CHAVE_PUBLICA
```

Para releases automáticas, adicione os Actions Secrets:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

A chave usada no cliente deve ser a **Publishable Key**, nunca `service_role`.

## Operação

- O usuário cria uma conta ou entra em Configurações.
- **Enviar backup** grava o snapshot imediatamente.
- O app também envia um backup ao ir para segundo plano.
- **Restaurar** substitui o banco local pelo último snapshot da conta.
- Sem conexão, o SQLite funciona normalmente.

O modelo atual usa estratégia de último backup válido. Sincronização granular
com resolução de conflitos por registro pode ser adicionada numa versão futura.
