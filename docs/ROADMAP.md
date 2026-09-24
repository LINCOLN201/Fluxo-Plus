# Roteiro do Fluxo+

Lista única do que falta, organizada em fases. Marque `[x]` ao concluir e
mantenha este arquivo atualizado a cada versão.

Legenda: **(você)** depende do dono do produto · **(código)** é implementação.

---

## Fase 0 — Fechar a 0.6.0 (agora)

- [ ] **(código)** CI verde no PR #6 (formatação, análise, testes, APK e Windows).
- [ ] **(você)** Revisar e fazer o merge do PR #6 na `main`.
- [ ] **(você)** Reativar o projeto no Supabase (está pausado).
- [ ] **(você)** Supabase → Authentication → URL Configuration: adicionar
      `https://lincoln201.github.io/Fluxo-Plus/confirmado.html`.
- [ ] **(código)** Com o Supabase ativo: conferir tabelas `user_backups` e
      `premium_subscriptions`, regras de acesso (RLS) e avisos de segurança.
- [ ] **(você)** GitHub → Settings → Pages → Source: **GitHub Actions**; conferir
      o site no ar.
- [ ] **(você)** Testar no aparelho real antes de publicar:
  - [ ] atualizar da 0.5.0 com dados reais e conferir saldos e relatórios;
  - [ ] exportar e importar backup local no Android e no Windows;
  - [ ] ativar PIN, fechar e abrir o app; testar biometria junto;
  - [ ] entrar na conta em um segundo aparelho com dados e ver a pergunta
        de conflito.
- [x] **(código)** Notas da versão escritas em `docs/releases/v0.6.0.md`.
- [ ] **(você)** Publicar pela tag `v0.6.0` depois do merge.

## Fase 1 — 0.7.0: assinatura Premium por Pix Automático

Pré-requisitos **(você)**:
- [ ] Escolher o PSP com API de Pix Automático (comparar tarifas e repasse).
- [ ] Conta PJ (CNPJ ou MEI) e credenciais da API.
- [ ] Termos de uso e política de cancelamento/reembolso (7 dias do CDC).
- [ ] Avaliar o plano pago do Supabase (não pausa por inatividade).

Implementação **(código)** — detalhes em
`docs/superpowers/specs/2026-09-24-versao-0.6.0-orientacoes.md`, seção 9:
- [ ] Edge Function `pix-assinar` (cria a recorrência e devolve o QR/copia e cola).
- [ ] Edge Function `pix-webhook` (valida e atualiza `premium_subscriptions`).
- [ ] Tela de checkout e de "cancelar assinatura" na aba Premium.
- [ ] Testes com o ambiente de homologação (sandbox) do PSP.
- [ ] **Excluir conta pelo app** (apaga conta e backup na nuvem) — a política
      de privacidade já promete esse direito (LGPD).
- [ ] Termos de uso publicados no site.
- [ ] Ligar `AppConstants.premiumEnforced = true`, com aviso prévio a quem já
      usa a nuvem.

## Fase 2 — 0.8.0: recursos Premium

- [ ] Histórico de backups na nuvem (voltar a uma versão anterior).
- [ ] Lançamentos recorrentes (aluguel, assinaturas, salário).
- [ ] Cartões de crédito com fatura e fechamento.
- [ ] Orçamento por categoria com alertas.
- [ ] Relatórios avançados (tendências, patrimônio).
- [ ] Exportação PDF e Excel.

## Fase 3 — Qualidade e distribuição

- [ ] Quebrar telas grandes: `dashboard_screen.dart` (~990 linhas) e
      `main_shell.dart` (~710).
- [ ] Testes de tela para Dashboard, Transações e Relatórios.
- [ ] Revisão de acessibilidade (tamanhos de toque, leitores de tela).
- [ ] Atualizar dependências (há pacotes com versões novas incompatíveis
      com as restrições atuais).
- [ ] Assinatura de código do Windows (evitar alerta do SmartScreen).
- [ ] Builds de iOS/macOS/Linux no CI (hoje só Android e Windows).
- [ ] Decidir sobre a Play Store (exige revisar as regras de cobrança do Google).
- [ ] Voltar ao fluxo `dev` → CI → PR → `main` descrito no README.

## Fase 4 — Futuro

- [ ] Sincronização granular (mesclar alterações em vez de escolher um lado).
- [ ] Web/PWA com armazenamento compatível.
- [ ] Inteligência financeira (análises, alertas e previsões).

---

## Concluído

### 0.6.0 (PR #6)
- [x] Site oficial (início, privacidade, e-mail confirmado) e workflow do Pages.
- [x] Valores em centavos inteiros (schema v3) com migração testada.
- [x] Cores Grafite nas categorias padrão; paleta extra Premium.
- [x] Backup local criptografado gratuito e "desfazer restauração".
- [x] Sincronização que pergunta antes de sobrescrever.
- [x] PIN + biometria; tela de bloqueio Grafite.
- [x] Aba Premium com plano atual em destaque; vitalício removido.
- [x] Saudação com o primeiro nome (editável).
- [x] Saldo de Contas com a mesma regra do Dashboard + previsto.
- [x] 70 testes automatizados.

### 0.5.0
- [x] Identidade visual Grafite (tema claro e escuro).

### 0.4.0
- [x] Vencimentos, parcelas e novos relatórios.
