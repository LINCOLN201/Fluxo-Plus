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
- [x] **(código)** Reforço de segurança dos dados (ver `docs/SECURITY.md`).
- [ ] **(você)** Com o Supabase ativo, rodar o trecho "Reforço de segurança"
      do `supabase/schema.sql` no SQL Editor (ou pedir para eu aplicar).

## Notificação push de atualização (pronta, falta você configurar)

Avisa quem já instalou o Fluxo+ quando sai uma versão nova, com notificação
de verdade na barra do celular — mesmo com o app fechado. Passo a passo
completo em `docs/RELEASES.md`, seção 5.

- [x] **(código)** App se inscreve sozinho no aviso (Firebase Cloud
      Messaging), sem conta nem identificação de quem instalou.
- [x] **(código)** Notificação com a logo do Fluxo+, funcionando com o app
      aberto, em segundo plano ou fechado.
- [x] **(código)** Workflow de publicação manda o aviso automaticamente a
      cada versão nova (job "Avisar quem já instalou").
- [ ] **(você)** Criar o projeto no [Firebase](https://console.firebase.google.com)
      e cadastrar `FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_BASE64` **e
      `GOOGLE_SERVICES_JSON_BASE64`** nos Secrets do GitHub (`docs/RELEASES.md`,
      seção 5) — os três são necessários; faltando o terceiro, o aviso "sai"
      mas nenhum aparelho recebe (era exatamente o caso da v0.6.3: só os dois
      primeiros nunca foram cadastrados, então o job era pulado silenciosamente).
- [ ] **(você)** Testar no aparelho: publicar uma versão de teste e conferir
      se a notificação chega com o app fechado.
- Só Android por enquanto; o Windows continua avisando só quando o app abre.

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
- [x] **Excluir conta pelo app** (apaga conta e backup na nuvem) — a política
      de privacidade já prometia esse direito (LGPD); agora tem botão na tela
      de sincronização, com confirmação em duas etapas (aviso + PIN/biometria).
- [ ] Termos de uso publicados no site.
- [ ] Ligar `AppConstants.premiumEnforced = true`, com aviso prévio a quem já
      usa a nuvem.

## Fase 1.5 — Segurança avançada

Teste de invasão feito em 25/09/2026 (`docs/SECURITY.md`, seção "Teste de
invasão"). Corrigidos: cópia de segurança em texto puro, nome de arquivo da
atualização vulnerável a path traversal, senha mínima fraca do backup local,
condição de corrida no bloqueio do PIN, builds de produção sem ofuscação.

- [x] **(prioridade alta, achado do pentest)** Criptografar o banco local com
      SQLCipher (chave no Keystore), só Android — feito em 27/09/2026, ver
      `docs/SECURITY.md`.
  - [ ] Mesma coisa no Windows: precisa de um `sqlite3` compilado com
        SQLCipher, sem pacote Flutter pronto para isso hoje; exige compilar
        e testar a DLL num PC Windows de verdade.
  - [x] Migração automática de bancos antigos (sem criptografia) para o
        formato cifrado — implementada em `AppDatabase.migrateToCipherIfNeeded`
        (28/09/2026), seguindo a receita oficial do SQLCipher (ATTACH +
        `sqlcipher_export`); o arquivo original vira `.pre-cipher-backup` em
        vez de ser apagado, como rede de segurança. **Ainda não validada num
        aparelho Android real** — o SQLCipher nativo não existe fora de uma
        build Android, então isso não roda no `flutter test` (só a lógica de
        quando migrar ou não está coberta por teste). Testar isso num
        aparelho de verdade, com um banco antigo de exemplo, antes de
        confiar 100% nela.
- [ ] Criptografia de ponta a ponta no backup da nuvem.

## Fase 1.6 — Fundação de engenharia (auditoria 28/09/2026)

Auditoria técnica pedida depois do incidente do Secret do Supabase (v0.6.1),
antes de continuar com features novas. Detalhe completo do que motivou cada
item nesta sessão de trabalho.

- [x] Relatório de erros em produção (Firebase Crashlytics) —
      `lib/core/observability/error_reporter.dart`, ligado junto do resto do
      Firebase (opcional, sem `google-services.json` não faz nada). Um crash
      de produção só foi descoberto porque a pessoa avisou manualmente, dias
      depois, com dados já perdidos — agora fica registrado sozinho.
- [x] `release.yml` passa a rodar a mesma checagem de conexão com o Supabase
      que o `quality.yml` já tinha, nos dois jobs (`android` e `windows`) —
      antes só rodava no push para `dev`, então um Secret podia quebrar
      entre isso e a publicação da tag sem nada acusar.
- [x] Job `windows` do `release.yml` passa a rodar `flutter analyze` e
      `flutter test` antes de compilar — antes só compilava, sem nenhuma
      checagem própria da plataforma.
- [x] Erros antes silenciosamente descartados (`catch (_) {}`) em
      `cloud_sync_service.dart` e `premium_service.dart` agora são
      registrados no relatório de erros, sem mudar o comportamento visível
      para quem usa o app.
- [x] `ANDROID_KEYSTORE_BASE64`/`ANDROID_STORE_PASSWORD`/`ANDROID_KEY_ALIAS`
      passam a ser validados de verdade (`keytool -list`) antes de assinar o
      APK, não só conferidos como "não vazio".
- [x] `FIREBASE_SERVICE_ACCOUNT_BASE64`/`FIREBASE_PROJECT_ID` passam a ser
      validados (JSON decodifica, campos certos presentes, `project_id`
      bate) antes de tentar notificar — antes um valor errado (não ausente)
      falhava de um jeito confuso dentro do script Python.
- [x] `docs/SECRETS.md`: checklist único com todos os Secrets do CI/CD e
      como conferir cada um, referenciado de `docs/RELEASES.md` e
      `docs/SUPABASE.md`.
- [x] Tabelas órfãs `transactions`/`goals` identificadas no projeto Supabase
      (não usadas por nenhum código do app — só `user_backups` e
      `premium_subscriptions` são usadas) — deixadas como estão, decisão de
      apagar ou não fica com quem administra o projeto (**(você)**), por ser
      uma mudança destrutiva num banco também usado por outra coisa.
- [ ] **(você)** No painel do Supabase (Authentication → Policies → Password
      Security), ativar a proteção contra senha vazada
      (`auth_leaked_password_protection`) — não é algo alterável por SQL.
- [ ] Cobertura de testes: sem nenhum teste para `cloud_sync_service.dart`
      (o serviço que falhou silenciosamente), `push_notification_service.dart`
      e as telas de Configurações (sincronização, backup, segurança), Contas,
      Categorias, Metas, Relatórios e Onboarding. Escopo grande demais para
      resolver de uma vez; entra como item recorrente até fechar.
- [ ] `biometric_service.dart` não tem nenhum ajuste por plataforma nem
      teste que confirme que funciona igual no Windows (Windows Hello via
      `local_auth`) — comportamento hoje só verificado "de olho".
- [ ] `dashboard_screen.dart` (1099 linhas) e `main_shell.dart` (714)
      continuam sem a divisão em telas menores já prevista na Fase 3.

## Fase 2 — 0.8.0: recursos Premium

- [ ] Histórico de backups na nuvem (voltar a uma versão anterior).
- [x] Lançamentos recorrentes (aluguel, assinaturas, salário) —
      **(auditoria 28/09/2026)** todo concorrente pesquisado (Mobills,
      Organizze, GuiaBolso) tem isso; era o recurso mais básico que faltava.
      Diferente de parcelas (quantidade fixa e conhecida), uma recorrência
      não tem fim: `TransactionRepository.createRecurring` gera 12 meses de
      início e `extendRecurringOccurrences` (chamado ao abrir o app) completa
      o horizonte aos poucos, sem gerar anos de lançamentos de uma vez.
      "Parar de repetir" apaga só as ocorrências futuras pendentes, mantém
      o histórico pago.
- [ ] Cartões de crédito com fatura e fechamento — **(auditoria
      28/09/2026)** segundo recurso mais citado nos comparativos depois de
      Open Finance; Organizze mostra fatura e limite na tela inicial.
- [ ] Edição em lote de transações (marcar várias e editar/excluir de uma
      vez) — **(auditoria 28/09/2026)** reclamação real e recorrente sobre
      o Mobills no Reclame Aqui por não ter isso; barato de implementar,
      ninguém reclama se já vier pronto.
- [ ] Orçamento por categoria com alertas.
- [ ] Relatórios avançados (tendências, patrimônio) — concorrentes bem
      avaliados (Organizze) também são criticados por não terem
      profundidade aqui; é diferencial, não só paridade.
- [ ] Exportação PDF e Excel.
- [ ] Widget de tela inicial (Android/iOS) — **(auditoria 28/09/2026)**
      citado como recurso esperado em comparativos de apps financeiros;
      não é oferecido hoje.

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
- [ ] **(você, decisão de negócio)** Open Finance — conectar direto no banco
      e importar transações automaticamente, sem lançar na mão. **(auditoria
      28/09/2026)** é a diferença nº 1 entre o Fluxo+ e todo concorrente
      pesquisado (Mobills, Organizze, GuiaBolso) — todos usam isso. Exige
      credenciamento no Banco Central/Open Finance Brasil; projeto grande,
      fica de fora por enquanto, mas é o maior gap competitivo do produto.
- [ ] Conta compartilhada (casal/família): convidar alguém para ver/editar
      a mesma conta na nuvem — **(auditoria 28/09/2026)** Organizze tem, e
      existem apps só para isso (Noh, Juntos). O Fluxo+ já tem conta na
      nuvem, então é uma extensão natural, não uma feature nova do zero.

### O que o Fluxo+ já tem de diferencial (auditoria 28/09/2026)

Não é só ficar correndo atrás da concorrência — nesses pontos o Fluxo+ já
está à frente do que foi pesquisado:
- Banco de dados local criptografado (SQLCipher) — não visto nos
  concorrentes pesquisados.
- Backup local sem depender de nuvem de terceiro.
- Notificação de atualização com o app fechado.
- A reclamação mais comum sobre concorrentes pagos (Mobills, no Reclame
  Aqui) é cobrança indevida após cancelamento — um fluxo de cancelamento
  fácil dentro do app (Fase 1, Pix Automático) já nasce em vantagem de
  confiança.
- Seção de assinaturas/streamers com total mensal e catálogo dos serviços
  mais comuns — ideia do dono do produto, não vista nos concorrentes
  pesquisados (que só têm "categoria", sem uma visão dedicada de quanto
  sai todo mês em streaming/música/nuvem).

---

## Concluído

### Pós-0.6.3
- [x] Notificação push de atualização nunca chegava a nenhum aparelho —
      relatado depois da v0.6.3 sair sem avisar quem já tinha o app.
      Investigando o log do job "Avisar quem já instalou" dessa publicação:
      "Firebase não configurado — pulando notificação." Não era bug: os
      Secrets `FIREBASE_PROJECT_ID`/`FIREBASE_SERVICE_ACCOUNT_BASE64` nunca
      foram cadastrados. Só que também tinha um bug real por trás — mesmo
      cadastrando os dois, `release.yml` nunca embutia o
      `google-services.json` no APK publicado (só o passo a passo local
      mencionava isso), então nenhum build publicado teria o Firebase
      configurado de verdade, e a notificação nunca chegaria a lugar
      nenhum mesmo com os Secrets certos. Corrigido: novo Secret
      `GOOGLE_SERVICES_JSON_BASE64` + passo "Configurar Firebase (opcional)"
      no job `android`, com `scripts/check_google_services_secret.py`
      validando o JSON antes de compilar. Documentado em
      `docs/RELEASES.md` (seção 5.3) e `docs/SECRETS.md`.
- [x] Seção "Assinaturas" — lista dedicada de streamers/serviços por
      assinatura (Netflix, Spotify, Disney+ etc.), com catálogo dos mais
      comuns no Brasil (ícone + cor, sem logo de ninguém) e opção "Outro"
      pra nome livre. Reaproveita o motor de recorrências (schema v5: nova
      categoria padrão "Assinaturas", `TransactionRepository
      .listActiveSubscriptions()`) — sem infraestrutura nova. Mostra o
      total mensal e a próxima cobrança de cada uma; cancelar usa o mesmo
      `stopRecurring` (mantém o histórico pago). Acessível em "Mais" no
      celular e na barra lateral no desktop.

### Pós-0.6.2 (continuação)
- [x] "Excluir conta" — botão na tela de sincronização apaga a conta e o
      backup na nuvem (inclusive assinatura Premium, se houver) pra sempre,
      sem precisar abrir uma issue no GitHub. Função `delete_own_account()`
      no Supabase (SECURITY DEFINER, só apaga a própria conta de quem
      chama), com `ON DELETE CASCADE` já existente cuidando do resto.
      Confirmação em duas etapas: diálogo de aviso + PIN/biometria
      (`IdentityCheck`). Dados deste aparelho não são afetados.

### Pós-0.6.2
- [x] "Esqueci minha senha" — não existia no app; agora usa o mesmo padrão
      de código por e-mail já usado na confirmação de cadastro (sem precisar
      de deep link). Depende do modelo de e-mail "Reset Password" no painel
      do Supabase mostrar `{{ .Token }}`, igual ao de confirmação — conferir
      ao testar.
- [x] Cadastro travava pedindo um código de confirmação que, em projetos
      Supabase com confirmação por e-mail desligada, nunca chega — a pessoa
      ficava esperando indefinidamente. `CloudSyncService.signUp` agora
      devolve se a conta já veio confirmada/logada; nesse caso o app pula
      direto para a sincronização, sem pedir código nenhum.
- [x] Dashboard tinha um botão de mês que só mostrava o mês atual e não
      fazia nada ao tocar (`onPressed: () {}`, nunca implementado) — quem
      lançava uma conta com vencimento no mês seguinte via o resumo do
      Dashboard sempre zerado, sem nenhum jeito de olhar aquele outro mês.
      Agora o botão navega entre meses (setas + toque volta pro mês atual)
      e a previsão salarial e as despesas por categoria passam a refletir
      o mês escolhido ("Saldo total" continua histórico, de todas as
      contas, e "Transações recentes" continua mostrando os últimos
      lançamentos de qualquer mês — os dois por design, sem mudança aqui).

### 0.6.2 (hotfix, PR #19)
- [x] Corrige o Secret `SUPABASE_URL` de produção, que apontava para um
      projeto inexistente desde a 0.6.0 — sincronização com a nuvem nunca
      havia funcionado de fato em nenhuma versão publicada.
- [x] CI passa a validar de verdade a conexão com o Supabase antes de
      compilar, para esse tipo de erro não chegar mais em silêncio a uma
      versão publicada.

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
