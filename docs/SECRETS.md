# Secrets do GitHub Actions: referência única

Todos os Secrets que o CI/CD do Fluxo+ usa, num só lugar, com como conferir
se cada um ainda está certo — sem precisar publicar uma versão para
descobrir que um deles quebrou. Cada um também tem instruções detalhadas de
como criar em `docs/SUPABASE.md` ou `docs/RELEASES.md`; este documento é só
o checklist de verificação.

Motivo de existir: em setembro de 2026, `SUPABASE_URL` apontou por meses
para um projeto Supabase que não existia mais, sem que nada no CI acusasse
isso — o app compilava normal e só falhava no celular de quem já tinha
instalado, na hora de sincronizar. Os passos "Confirmar conexão com o
Supabase" no `quality.yml` e no `release.yml` existem para isso não se
repetir; os outros Secrets abaixo ainda não têm uma checagem tão forte
quanto essa.

## Supabase (sincronização e Premium)

| Secret | Onde é usado | Como conferir |
|---|---|---|
| `SUPABASE_URL` | `quality.yml`, `release.yml` | O passo "Confirmar conexão com o Supabase" testa de verdade, em toda build. Manualmente: `curl -I https://SEU-PROJETO.supabase.co/auth/v1/settings` deve responder `200`. |
| `SUPABASE_PUBLISHABLE_KEY` | idem | Mesma checagem acima (a chave vai no header `apikey`). Confira também que é a **Publishable Key**, nunca a `service_role` — ver `docs/SUPABASE.md`. |

## Assinatura Android

| Secret | Onde é usado | Como conferir |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | `release.yml` (job `android`) | O passo "Configurar assinatura Android" agora roda `keytool -list` no keystore decodificado — se o Base64 estiver corrompido ou não for mais um `.jks` válido, o build falha aí, antes de tentar assinar o APK. |
| `ANDROID_STORE_PASSWORD` | idem | Validado pelo mesmo `keytool -list` (usa a senha para abrir o keystore). |
| `ANDROID_KEY_ALIAS` | idem | Validado pelo mesmo passo (`keytool -list -alias`). |
| `ANDROID_KEY_PASSWORD` | idem | **Não** é validado por `keytool -list` (não precisa da senha da chave individual para listar). Só é conferido de fato na hora de assinar o APK — se estiver errado, o job falha em "Gerar APK". |

Se qualquer um desses quatro mudar (nova chave, senha trocada), releases
futuras deixam de conseguir assinar o APK da mesma forma que os aparelhos já
instalados esperam — perder o keystore original é irreversível para quem já
tem o app instalado (ver `docs/RELEASES.md`, seção 2).

## Firebase (notificação push de atualização, opcional)

| Secret | Onde é usado | Como conferir |
|---|---|---|
| `FIREBASE_PROJECT_ID` | `release.yml` (job `notify`) | O passo "Enviar notificação push" agora confere que bate com o `project_id` de dentro do JSON da conta de serviço, antes de tentar notificar. |
| `FIREBASE_SERVICE_ACCOUNT_BASE64` | idem | O mesmo passo decodifica o Base64, valida que é um JSON de verdade e que tem `project_id`, `client_email` e `private_key` preenchidos. |

Sem esses dois, o job `notify` é pulado silenciosamente ("Firebase não
configurado — pulando notificação.") — isso é esperado e não quebra a
publicação. Um valor **presente mas errado** agora falha o job com uma
mensagem dizendo qual Secret conferir, em vez de falhar de um jeito confuso
lá dentro do script Python.

## Ao trocar qualquer Secret

1. Atualize o valor em Settings → Secrets and variables → Actions.
2. Espere o próximo push para `dev` (ou rode manualmente o workflow
   "Validar desenvolvimento") e confira o passo correspondente no log.
3. Só crie/publique uma tag depois desse CI passar com o Secret novo.
