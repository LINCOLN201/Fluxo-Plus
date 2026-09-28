// Cancela a recorrência do usuário autenticado no PSP. O status em
// premium_subscriptions só muda quando o pix-webhook confirmar o
// cancelamento — aqui só avisamos o PSP. Ver docs/PIX.md.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, preflightResponse } from "../_shared/cors.ts";
import { getPixAdapter, PspNotConfiguredError } from "../_shared/pix_adapter.ts";

Deno.serve(async (req) => {
  const preflight = preflightResponse(req);
  if (preflight) return preflight;

  if (req.method !== "POST") {
    return json({ error: "Método não permitido." }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "Não autenticado." }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return json({ error: "Sessão inválida ou expirada." }, 401);
  }

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const adminClient = createClient(supabaseUrl, serviceRoleKey);
  const { data: subscription, error: fetchError } = await adminClient
    .from("premium_subscriptions")
    .select("external_subscription_id")
    .eq("user_id", userData.user.id)
    .single();
  if (fetchError || !subscription?.external_subscription_id) {
    return json({ error: "Nenhuma assinatura ativa encontrada." }, 404);
  }

  try {
    const adapter = getPixAdapter();
    await adapter.cancelRecurringCharge(subscription.external_subscription_id);
    return json({ ok: true });
  } catch (error) {
    if (error instanceof PspNotConfiguredError) {
      return json({ error: error.message }, 501);
    }
    console.error("pix-cancelar falhou:", error);
    return json({ error: "Não foi possível cancelar agora." }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
