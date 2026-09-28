// Cria a recorrência de Pix Automático para o usuário autenticado e devolve
// o QR Code / "copia e cola" para autorizar no app do banco. Ver docs/PIX.md.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, preflightResponse } from "../_shared/cors.ts";
import { getPixAdapter, PspNotConfiguredError, PixPlan } from "../_shared/pix_adapter.ts";

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
  const user = userData.user;

  let body: { plan?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Corpo da requisição inválido." }, 400);
  }
  if (body.plan !== "monthly" && body.plan !== "yearly") {
    return json({ error: 'Informe "plan": "monthly" ou "yearly".' }, 400);
  }
  const plan = body.plan as PixPlan;

  try {
    const adapter = getPixAdapter();
    const charge = await adapter.createRecurringCharge({
      userId: user.id,
      userEmail: user.email ?? "",
      plan,
    });

    // Guarda os dados da recorrência com a service role — o app só lê essa
    // tabela (RLS), quem atualiza o status é o pix-webhook.
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const adminClient = createClient(supabaseUrl, serviceRoleKey);
    const { error: upsertError } = await adminClient
      .from("premium_subscriptions")
      .upsert({
        user_id: user.id,
        plan: "premium",
        provider: "pix",
        external_customer_id: charge.externalCustomerId,
        external_subscription_id: charge.externalSubscriptionId,
        updated_at: new Date().toISOString(),
      });
    if (upsertError) throw upsertError;

    return json({
      copyPasteCode: charge.copyPasteCode,
      qrCodeImageBase64: charge.qrCodeImageBase64 ?? null,
    });
  } catch (error) {
    if (error instanceof PspNotConfiguredError) {
      return json({ error: error.message }, 501);
    }
    console.error("pix-assinar falhou:", error);
    return json({ error: "Não foi possível criar a assinatura agora." }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
