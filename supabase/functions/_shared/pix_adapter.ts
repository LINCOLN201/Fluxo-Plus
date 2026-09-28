// Ponto único de troca quando o PSP (provedor de pagamento) for escolhido.
// Nada aqui fala com nenhum PSP de verdade — é só o contrato que
// `pix-assinar` e `pix-webhook` usam. Ver `docs/PIX.md` para o passo a
// passo de como plugar um PSP real sem mexer nas duas funções.

export type PixPlan = "monthly" | "yearly";

export interface RecurringChargeRequest {
  userId: string;
  userEmail: string;
  plan: PixPlan;
}

export interface RecurringChargeResult {
  externalCustomerId: string;
  externalSubscriptionId: string;
  /** PNG em base64, se o PSP devolver um QR Code pronto. */
  qrCodeImageBase64?: string;
  /** Texto "Pix copia e cola" — sempre presente, é o mínimo pra autorizar. */
  copyPasteCode: string;
}

export type SubscriptionStatus =
  | "active"
  | "past_due"
  | "canceled";

export interface WebhookEvent {
  externalSubscriptionId: string;
  status: SubscriptionStatus;
  currentPeriodStart?: string;
  currentPeriodEnd?: string;
}

/** Erro de configuração: PSP ainda não plugado, ou secret faltando. Nunca é
 * culpa de quem está usando o app — é aviso pra quem está desenvolvendo. */
export class PspNotConfiguredError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PspNotConfiguredError";
  }
}

export interface PixPspAdapter {
  createRecurringCharge(
    req: RecurringChargeRequest,
  ): Promise<RecurringChargeResult>;
  cancelRecurringCharge(externalSubscriptionId: string): Promise<void>;
  /** Confere a assinatura/segredo do webhook e devolve o evento já validado.
   * Deve lançar erro se a requisição não vier mesmo do PSP. */
  verifyAndParseWebhook(req: Request): Promise<WebhookEvent>;
}

/** Adaptador padrão: sem PSP escolhido ainda, todo mundo recebe o mesmo erro
 * claro em vez de uma cobrança de verdade acontecer por engano. */
class StubPixAdapter implements PixPspAdapter {
  createRecurringCharge(_req: RecurringChargeRequest): Promise<RecurringChargeResult> {
    throw new PspNotConfiguredError(
      "Nenhum PSP de Pix Automático está configurado ainda. " +
        "Implemente PixPspAdapter em _shared/psp/<seu-psp>.ts e troque o " +
        "adaptador em getPixAdapter() (_shared/pix_adapter.ts). Ver docs/PIX.md.",
    );
  }

  cancelRecurringCharge(_externalSubscriptionId: string): Promise<void> {
    throw new PspNotConfiguredError(
      "Nenhum PSP de Pix Automático está configurado ainda. Ver docs/PIX.md.",
    );
  }

  verifyAndParseWebhook(_req: Request): Promise<WebhookEvent> {
    throw new PspNotConfiguredError(
      "Nenhum PSP de Pix Automático está configurado ainda. Ver docs/PIX.md.",
    );
  }
}

/** Troque aqui quando o PSP for escolhido: importe a implementação real
 * (ex.: `./psp/efi.ts`) e devolva ela em vez do StubPixAdapter. */
export function getPixAdapter(): PixPspAdapter {
  return new StubPixAdapter();
}
