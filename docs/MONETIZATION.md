# Monetização do Fluxo+

O Fluxo+ permanece open source sob licença MIT e continua funcionando
offline. A monetização será aplicada aos serviços hospedados e às conveniências
avançadas, sem bloquear transações, contas, categorias, dashboard, relatórios
básicos ou metas.

## Gratuito

- transações, contas e categorias ilimitadas;
- dashboard, relatórios básicos e metas;
- temas claro e escuro;
- SQLite local e funcionamento offline;
- backup local criptografado (arquivo protegido por senha);
- bloqueio por PIN e biometria.

## Premium planejado

- backup na nuvem, sincronização entre aparelhos e histórico de versões;
- paleta de cores exclusiva para as categorias;
- recorrências, cartões, parcelas e orçamentos;
- relatórios avançados e exportação PDF/Excel;
- inteligência financeira no roadmap.

## Preços de referência

- mensal: R$ 9,90;
- anual: R$ 79,90.

Não há plano vitalício: os serviços de nuvem têm custo recorrente.

## Forma de pagamento

Pix Automático (recorrência autorizada uma vez pelo usuário no app do banco).
A integração depende da escolha do PSP; ver
`docs/superpowers/specs/2026-09-24-versao-0.6.0-orientacoes.md`.

## Estado da implementação

A estrutura de planos, permissões, cache offline e consulta segura ao Supabase
está preparada. Os recursos Premium já checam o plano do usuário
(`PremiumEntitlement.allows`), mas a cobrança fica desligada
(`AppConstants.premiumEnforced = false`) e tudo continua liberado até a
integração do Pix Automático entrar em produção.

Somente um backend confiável poderá criar ou alterar assinaturas. O aplicativo
cliente possui acesso de leitura apenas à assinatura do usuário autenticado.
