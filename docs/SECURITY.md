# Segurança do Fluxo+

O que protegemos, como, e o que ainda falta. Atualize a cada mudança que
envolva dados.

## Onde os dados ficam

| Dado | Onde | Proteção |
|------|------|----------|
| Contas, transações, metas, categorias | SQLite no diretório privado do app | Sandbox do sistema; fora do backup do Google (Android) |
| PIN | Tabela `settings` | Só o hash PBKDF2-SHA256 com sal; nunca sai do aparelho |
| Sessão da conta (tokens) | Keystore (Android) / cofre de credenciais (Windows) | `SecureSessionStorage` |
| Backup local | Arquivo `.fluxobackup` escolhido pelo usuário | AES-256-GCM, chave derivada da senha (PBKDF2, 200 mil iterações) |
| Cópia antes de restaurar | Diretório privado do app | Expira em 7 dias |
| Backup na nuvem | Supabase `user_backups` | HTTPS + RLS (cada usuário só lê/grava o próprio) |

## Medidas em vigor

**Aparelho**
- `allowBackup=false` e regras de extração: o banco não vai para o backup do
  Google Drive nem para a transferência entre aparelhos.
- `FLAG_SECURE` ligado por padrão: nada aparece em capturas, gravações e na
  miniatura dos apps recentes (o usuário pode desligar, com confirmação).
- Tráfego sem criptografia proibido (`usesCleartextTraffic=false`).
- Bloqueio por PIN e/ou biometria ao abrir e ao voltar para o app.
- PIN com limite de tentativas: 5 erros → espera de 30 s, dobrando a cada
  erro até 1 hora; o contador fica gravado (reabrir o app não zera).
- Desligar biometria, PIN ou a proteção de tela exige confirmar identidade.
- Exportar, importar, restaurar ou desfazer restauração exige PIN/biometria
  quando o bloqueio está ativo.

**Dados**
- Valores em centavos inteiros; consultas SQL sempre parametrizadas.
- Restauração valida o formato, recusa versões futuras e guarda cópia antes.
- Configurações do aparelho (PIN, tema, bloqueio) nunca entram em backups.

**Atualizações**
- Só aceita instaladores de `github.com` via HTTPS.
- Cada Release publica `.sha256`; o app confere o APK antes de instalar e
  descarta o arquivo se não bater. O Android ainda confere a assinatura.
- O APK baixado fica numa pasta própria, a única exposta ao instalador.

**Nuvem (Supabase)** — `supabase/schema.sql`
- RLS em todas as tabelas; visitantes sem login (`anon`) sem acesso.
- O app não pode apagar backups nem alterar assinaturas.
- Backup precisa ser um objeto JSON de até 20 MB.

**Site**
- Content-Security-Policy restritiva (sem scripts), sem referrer.

## Próximos passos recomendados

1. **Criptografar o banco local (SQLCipher)**, com a chave no Keystore/cofre.
   Protege contra aparelho com root ou cópia física do armazenamento. Exige
   trocar o `sqflite` e migrar bancos existentes; deve ser feito numa versão
   própria e testado em aparelho real antes de publicar.
2. **Criptografia de ponta a ponta no backup da nuvem**, com uma senha de
   sincronização que só o usuário conhece: nem o Supabase conseguiria ler os
   dados. Exige cuidado com recuperação (senha perdida = backup perdido).
3. **Excluir conta pelo app** (LGPD), com função no servidor.
4. **Assinatura de código do Windows**.
5. Rodar o verificador de segurança do Supabase (`get_advisors`) a cada
   mudança no banco.

## Como reportar uma falha

Abra uma issue em <https://github.com/LINCOLN201/Fluxo-Plus/issues> **sem**
detalhes que permitam explorar a falha e peça um canal privado.
