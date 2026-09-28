// Recebe o webhook do PSP (cobrança paga, atrasada ou cancelada) e atualiza
// premium_subscriptions com a service role. Nunca confia no corpo da
// requisição sem antes validar a assinatura/segredo do PSP — é isso que
// `verifyAndParseWebhook` faz. Ver docs/PIX.md.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, preflightResponse } from "../_shared/cors.ts";
import { getPixAdapter, PspNotConfiguredError } from "../_shared/pix_adapter.ts";

Deno.serve(async (req) => {
  const preflight = preflightResponse(req);
  if (preflight) return preflight;

  if (req.method !== "POST") {
    return json({ error: "Método não permitido." }, 405);
  }

  try {
    const adapter = getPixAdapter();
    // Passa a requisição original (não o body já lido) porque validar a
    // assinatura normalmente precisa do corpo bruto, antes de qualquer parse.
    const event = await adapter.verifyAndParseWebhook(req);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { error } = await adminClient
      .from("premium_subscriptions")
      .update({
        status: event.status,
        current_period_start: event.currentPeriodStart ?? null,
        current_period_end: event.currentPeriodEnd ?? null,
        updated_at: new Date().toISOString(),
      })
      .eq("external_subscription_id", event.externalSubscriptionId);
    if (error) throw error;

    return json({ ok: true });
  } catch (error) {
    if (error instanceof PspNotConfiguredError) {
      return json({ error: error.message }, 501);
    }
    // Webhook inválido (assinatura não bate) não é erro nosso — é alguém
    // tentando forjar uma cobrança. Não vaza detalhe, só recusa.
    console.error("pix-webhook rejeitou a requisição:", error);
    return json({ error: "Webhook inválido." }, 400);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
