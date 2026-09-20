# Identidade visual "Grafite Fluxo+" — design

**Status:** aprovado para plano de implementação
**Sub-projeto:** 1 de 4 (fundação) do esforço "melhorar UX do Fluxo+ para o usuário final"
**Ordem completa:** (1) navegação e visual geral ← este documento · (2) fluxo de adicionar transação (quick-add) · (3) dashboard e insights · (4) orçamento por categoria

## Contexto

O Fluxo+ é o app carro-chefe do ecossistema (Flutter, local-first, SQLite + backup Supabase, v0.4.0). O pedido original foi "melhorar todo o sistema para o usuário final" — escopo grande demais para uma spec só, então foi decomposto em 4 sub-projetos sequenciais. Este documento cobre o primeiro: a fundação visual, da qual os outros três dependem para não gerar retrabalho de estilo.

### Pesquisa de referência

Pesquisa rápida sobre tendências de UX em apps financeiros (2026) e concorrentes diretos (Mobills, Organizze, YNAB, Nubank) mostrou:
- Tendência geral: personalização por IA, mobile-first com gestos, "data storytelling" em vez de dashboards estáticos (relevante para o sub-projeto 3, não este).
- No mercado brasileiro, verde já é usado por vários concorrentes/adjacentes (PicPay, Sicoob) e o Fluxo+ atual também é verde — pouco diferenciado.
- Nubank e apps "premium" usam paletas de marca fortes (roxo, no caso do Nubank) em vez do verde-fintech genérico.

Isso motivou a escolha de uma identidade visual própria em vez de apenas refinar o verde existente.

## Processo de decisão

Três direções visuais foram apresentadas com mockups comparativos (cartão de saldo + item de transação) via companion visual: **A) Evolutivo** (mantém verde atual, só consolida tokens), **B) Nova identidade índigo + coral**, **C) Grafite premium** (fundo quase preto, acento lima elétrico). O usuário escolheu **C) Grafite premium** de forma consistente e repetida.

Em seguida, três níveis de uso de cor para sinalizar receita/despesa foram comparados: **A) Mono** (só sinal +/-), **B) Semântico sutil** (tons dessaturados), **C) Vívido** (vermelho/lima saturados). Escolhido **C) Vívido**.

Duas decisões de escopo confirmadas em texto:
- Manter tema claro E escuro (não abandonar o tema claro, não tratá-lo como fallback de segunda classe) — precisa de uma versão clara equivalente ao grafite, com o mesmo par de acentos, ajustada para contraste adequado.
- Manter a estrutura de navegação atual (bottom nav + FAB central no mobile, tela "Mais" agrupando itens extras, sidebar fixa no desktop) — este sub-projeto é um reskin visual, não uma reestruturação de navegação.

## Escopo

**Dentro do escopo:**
- Novo conjunto de tokens de cor (dark e light) em `lib/core/theme/app_colors.dart` e `lib/core/theme/app_theme.dart`.
- Migração de cores hard-coded espalhadas pelo código (ex.: hex literais em `main_shell.dart` — `Color(0xFF0D1820)`, `Color(0xFFE4F7EB)`, etc. — e em outras telas de `lib/features/**/presentation/`) para os tokens centralizados.
- Aplicação da nova paleta em todas as telas existentes, sem alterar sua estrutura/layout.

**Fora do escopo (fica para sub-projetos seguintes ou não entra):**
- Reestruturação de navegação (itens da barra, o que vai para "Mais", ordem).
- Novas funcionalidades (quick-add, insights de dashboard, orçamento por categoria — sub-projetos 2, 3 e 4).
- Troca de tipografia (mantém família Manrope) e de iconografia (mantém Material Icons).
- Golden tests / testes de regressão visual automatizados — validação é manual.

## Tokens de cor

### Tema escuro (padrão)

| Token | Valor | Uso |
|---|---|---|
| `background` | `#0A0A0B` | fundo geral do app |
| `surface` | `#151516` | cards, superfícies elevadas de primeiro nível |
| `surfaceElevated` | `#1A1A1C` | avatares, elementos de destaque sobre `surface` |
| `border` | `#262628` | bordas sutis de card/input |
| `textPrimary` | `#F2F2F0` | texto principal |
| `textMuted` | `#8A8A8E` | labels, texto secundário |
| `textMutedDim` | `#6E6E72` | texto terciário (datas, metadados) |
| `primary` (acento) | `#C6FF5E` | ações, indicador de navegação ativo, saldo positivo |
| `expense` | `#FF5C5C` | valores de despesa |
| `income` | `#C6FF5E` | valores de receita (reaproveita o acento) |
| `warning` | tom âmbar ajustado ao grafite (ex.: `#F2B84B`, validar contraste) | avisos, vencimentos próximos |

### Tema claro (equivalente)

| Token | Valor | Uso |
|---|---|---|
| `background` | `#F5F5F3` | fundo geral (off-white, não azulado como o atual) |
| `surface` | `#FFFFFF` | cards |
| `surfaceElevated` | `#F0F0EE` | avatares, destaques sobre `surface` |
| `border` | `#E4E4E1` | bordas sutis |
| `textPrimary` | `#1A1A1B` | texto principal |
| `textMuted` | `#6E6E72` | texto secundário |
| `primary` (acento) | tom de lima escurecido para contraste AA sobre branco (ex.: `#5C8A16`, validar) | ações, indicador ativo |
| `expense` | vermelho escurecido para contraste (ex.: `#D93636`, validar) | valores de despesa |
| `income` | mesmo tom escurecido do acento lima | valores de receita |
| `warning` | âmbar escurecido equivalente, validar contraste | avisos |

Os valores exatos de contraste (marcados "validar") devem ser conferidos contra WCAG AA (4.5:1 para texto) durante a implementação — os hex acima são ponto de partida, não valores finais imutáveis.

## Onde aplica

Todas as telas em `lib/features/**/presentation/` que hoje leem `AppColors`/`Theme.of(context)` (dashboard, transações, contas, metas, relatórios, categorias, configurações, premium, notificações, onboarding, splash) e `lib/features/shell/presentation/main_shell.dart` (sidebar desktop, bottom nav mobile, tela "Mais", `_FluxoMark`). Estrutura de cada tela permanece igual — muda só a pele de cor.

## Testes e validação

Sem lógica nova — é puramente visual. Validação:
- Manual, tela por tela, nos dois temas (claro/escuro), em pelo menos um formato mobile e um desktop (o app já tem breakpoint em 980px no `MainShell`).
- Checar especificamente contraste texto/fundo nos tokens "a validar" da tabela clara.
- Rodar `flutter analyze` e a suite de testes existente (`test/`) para garantir que nada quebrou — nenhum teste atual depende de cor, então não são esperadas falhas, mas é a rede de segurança de regressão do projeto.

## Riscos

- Descontentamento com o visual mais "frio"/monocromático do grafite comparado ao verde atual — mitigado pela escolha ter sido feita com mockups reais, não abstrata.
- Contraste insuficiente no tema claro se os tons "a validar" não forem ajustados com cuidado — mitigado pelo passo de validação AA explícito acima.

## Adendo pós-implementação (2026-09-20)

- **Tokens fora das tabelas originais:** `onPrimary` (escuro `#0A0A0B`, claro `#FFFFFF`) e, no claro, `textMutedDim` `#9A9A96` (apenas decorativo; hoje `textMutedDim` não é usado em `lib/`).
- **Valores finais validados no tema claro** (razão de contraste sobre a respectiva superfície): `primary`/`income` `#4A7010` (5,81:1; o `#5C8A16` sugerido não passa AA), `expense` `#C22B2B` (5,72:1), `warning` `#8A5A00` (5,93:1). O `warning` escuro `#F2B84B` foi mantido.
- **`textMuted` claro sobre `surfaceElevated`** dá 4,45:1 (abaixo de AA); por isso cabeçalhos usam `surface` + `border` (regra E3).
- **R6 — cards "hero":** quatro cards (dashboard mobile de despesas, resultado em relatórios, total em contas, cabeçalho do premium) deixaram de ser gradientes full-bleed e passaram a `surface` chapado com borda semântica. É uma mudança de tratamento além da matiz, aprovada como parte do reskin porque gradientes terminando no acento lima quebravam o contraste do texto.
- **Tema escuro** ganhou `textTheme`, `cardTheme` e temas de navegação que não tinha (cards com elevação 0, raio 20 e borda).
- **`update_prompt`:** gradiente do cabeçalho temperado (`lerp` de `background` para `primary` a .35; título/subtítulo em `textPrimary`). Cores padrão de NOVAS categorias são persistidas independentes do tema (claro: receita `#4A7010` / despesa `#C22B2B`).
- **ADIAMENTO CONHECIDO (decisão pendente com o dono do produto):** as 11 categorias padrão semeadas em `lib/core/database/app_database.dart` (~linhas 106-116) ainda usam a paleta pré-Grafite (`#0F9D58`, `#0B6B3A`, `#E53935`, …) e bancos existentes mantêm as cores gravadas; alterá-las para usuários existentes exigiria migração de dados (fora de escopo: `lib/core/database` está proibido). `_LockScreen` (`lib/app.dart`) e `EmptyState` não estavam na lista "Onde aplica" e continuam usando cores do esquema derivadas da semente.
- **Validação efetivamente realizada:** testes unitários de valores dos tokens e de contraste WCAG, testes de widget do registro do tema e uma passada de renderização headless (82 combinações tela × tema × tamanho, zero exceções em tempo de execução) no lugar do QA manual.
