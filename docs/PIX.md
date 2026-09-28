# Pix Automático — como plugar o PSP escolhido

As três Edge Functions do checkout Premium já existem e já são chamadas em
todo lugar certo: `pix-assinar` (cria a recorrência), `pix-cancelar` (cancela)
e `pix-webhook` (recebe a confirmação de pagamento do PSP e atualiza
`premium_subscriptions`). Nenhuma delas fala com nenhum PSP de verdade —
todas passam por um único ponto de troca,
`supabase/functions/_shared/pix_adapter.ts`, que hoje devolve um adaptador
"stub" (`StubPixAdapter`) cujos três métodos só lançam um erro claro. Isso é
proposital: nenhuma credencial paga entra no código sem você decidir isso
explicitamente.

Só falta **um arquivo novo** para ativar de verdade — o resto (autenticação,
RLS, atualização da tabela, tela de checkout) já está pronto e não muda.

## Passo a passo

1. **Escolher o PSP** (dono do produto): confirmar com o PSP que ele oferece
   **API de Pix Automático** (não é o Pix comum de QR Code avulso — é uma
   recorrência que o usuário autoriza uma vez só). Exemplos a comparar: Efí,
   Asaas, Mercado Pago, ou a API Pix de algum banco. Compare tarifa por
   cobrança e prazo de repasse. Abrir conta PJ (CNPJ ou MEI) se ainda não
   tiver.

2. **Escrever o adaptador** em `supabase/functions/_shared/psp/<nome-do-psp>.ts`,
   implementando a interface `PixPspAdapter` de `pix_adapter.ts`:
   - `createRecurringCharge` — chama a API do PSP para criar a recorrência e
     devolve `externalCustomerId`, `externalSubscriptionId` e o "Pix copia e
     cola" (e o QR Code em base64, se o PSP fornecer pronto).
   - `cancelRecurringCharge` — chama a API do PSP para cancelar.
   - `verifyAndParseWebhook` — confere a assinatura/segredo do webhook (cada
     PSP tem seu jeito — HMAC, token no header, IP allowlist, etc.) **antes**
     de confiar em qualquer dado do corpo, e traduz o evento do PSP para o
     formato `WebhookEvent` (`active`/`past_due`/`canceled` +
     `currentPeriodStart`/`currentPeriodEnd`).
   - As credenciais do PSP entram só como `Deno.env.get("...")` dentro desse
     arquivo — nunca direto nas três funções.

3. **Trocar o `getPixAdapter()`** em `pix_adapter.ts` para importar e devolver
   a implementação nova em vez do `StubPixAdapter`.

4. **Guardar os secrets** (nunca no app, nunca commitados):
   ```
   supabase secrets set PIX_PSP_API_KEY=... PIX_PSP_WEBHOOK_SECRET=...
   ```
   (nomes exatos ficam a critério de quem escreve o adaptador — são lidos só
   dentro dele).

5. **Publicar as funções**:
   ```
   supabase functions deploy pix-assinar
   supabase functions deploy pix-cancelar
   supabase functions deploy pix-webhook --no-verify-jwt
   ```
   `pix-webhook` precisa de `--no-verify-jwt` porque quem chama é o PSP, não
   um usuário logado — a validação de quem pode chamar é o
   `verifyAndParseWebhook` do adaptador, não o JWT do Supabase.

6. **Cadastrar a URL do webhook** no painel do PSP:
   `https://<seu-projeto>.supabase.co/functions/v1/pix-webhook`.

7. **Testar no ambiente de homologação (sandbox) do PSP** antes de qualquer
   cobrança real — a maioria oferece um.

8. **Construir a tela de checkout** no app (aba Premium): chama
   `pix-assinar`, mostra o QR Code/copia e cola, um botão "já autorizei" que
   chama `PremiumService.load(refresh: true)` até o webhook confirmar, e
   "Cancelar assinatura" chamando `pix-cancelar`. Isso ainda não existe —
   é o próximo passo depois do PSP escolhido e testado.

9. **Ligar a cobrança de verdade**: `AppConstants.premiumEnforced = true`,
   com aviso prévio a quem já usa a nuvem gratuitamente.

10. **Antes de ligar**: política de cancelamento/reembolso (direito de
    arrependimento de 7 dias do CDC) e termos de uso publicados no site —
    ver `site/`.

## Por que a divisão em três funções

- `pix-assinar` e `pix-cancelar` exigem um usuário logado (JWT do Supabase) —
  cada um só cria/cancela a própria assinatura.
- `pix-webhook` nunca tem um usuário logado (quem chama é o PSP) — por isso
  identifica a assinatura pelo `external_subscription_id` salvo em
  `pix-assinar`, e a única prova de que a chamada é legítima é a validação de
  assinatura do adaptador.
- Nenhuma das três aceita alterar `status` diretamente a partir do app: só
  `pix-webhook`, rodando com a *service role*, grava esse campo — é assim que
  a RLS de `premium_subscriptions` já funciona hoje (o app só lê).
