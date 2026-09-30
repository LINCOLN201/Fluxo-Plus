# Instagram corporativo da Fluxo Ecossistema

Kit para abrir e alimentar o perfil oficial da **Fluxo Ecossistema**: dados do
perfil, identidade visual, os 9 primeiros posts (já em imagem), capas de
destaques, modelo de story, legendas e calendário do primeiro mês.

O perfil é da **marca-mãe** (Fluxo). Cada app do ecossistema aparece como
produto dentro dele — o **Fluxo+** (finanças pessoais) é o primeiro e, por
enquanto, o único no ar. Quando surgir um app novo, ele ganha destaque e posts
próprios, sem precisar abrir outra conta.

Todas as imagens estão em [`imagens/`](imagens/) e são geradas a partir de
[`fonte/pecas.html`](fonte/pecas.html) — para editar um texto, altere o HTML e rode:

```bash
node marketing/instagram/fonte/render.mjs   # requer o pacote playwright
```

---

## 1. Criar a conta

1. Crie um **e-mail próprio da marca** (ex.: `contato.fluxoecossistema@gmail.com`) —
   não use o e-mail pessoal: separa a vida pessoal do trabalho e facilita
   passar o acesso para outra pessoa no futuro.
2. No app do Instagram: **Criar nova conta** com esse e-mail.
3. Usuário: **`@fluxoecossistema`** — o mesmo nome da organização no GitHub
   (`github.com/fluxoecossistema`). Alternativas se estiver ocupado:
   `@fluxo.ecossistema`, `@ecossistemafluxo`, `@somosfluxo`.
   Se mudar o @, troque também o texto `@fluxoecossistema` em
   `fonte/pecas.html` e gere as imagens de novo.
4. **Configurações → Tipo de conta → Mudar para conta profissional → Empresa**.
   Categoria: **Empresa de tecnologia** (ou "Software" / "Aplicativo").
5. Ative a **autenticação em dois fatores** e guarde os códigos de backup.
6. Opcional: crie a página no Facebook e vincule (necessário para Meta Business
   Suite, agendamento e anúncios).

## 2. Perfil

| Campo | Conteúdo |
|---|---|
| Foto | [`imagens/perfil.png`](imagens/perfil.png) — logotipo "fluxo" (1080×1080, recortada em círculo) |
| Nome | `Fluxo Ecossistema · Apps` (o nome entra na busca) |
| Usuário | `@fluxoecossistema` |
| Categoria | Empresa de tecnologia |
| Link | `https://lincoln201.github.io/Fluxo-Plus/` (troque por um site da Fluxo ou uma página de links quando houver mais de um app) |

**Bio** (até 150 caracteres):

```
Apps que organizam a vida, com você no controle 💚
🔒 Privados · 🔓 Código aberto
💰 Fluxo+: finanças pessoais grátis
⬇️ Baixe no link
```

## 3. Destaques (stories fixos)

Suba cada capa como story, fixe em um destaque e use a imagem como capa.

| Destaque | Capa | O que guardar |
|---|---|---|
| Sobre | [`destaque-sobre.png`](imagens/destaque-sobre.png) | Quem é a Fluxo, princípios, bastidores |
| Fluxo+ | [`destaque-fluxo-plus.png`](imagens/destaque-fluxo-plus.png) | Tutoriais do app (instalar o APK, backup), Premium quando abrir |
| Novidades | [`destaque-novidades.png`](imagens/destaque-novidades.png) | Cada versão nova de qualquer app (notas em `docs/releases/`) |
| Dicas | [`destaque-dicas.png`](imagens/destaque-dicas.png) | Dicas de finanças e organização |
| Dúvidas | [`destaque-duvidas.png`](imagens/destaque-duvidas.png) | Perguntas frequentes |

Cada app novo do ecossistema ganha um destaque próprio, com o logo dele.

## 4. Identidade visual

Mesma identidade **Grafite** do Fluxo+ (`lib/core/theme/app_colors.dart`),
usada como identidade da marca-mãe.

| Uso | Cor |
|---|---|
| Fundo | `#0A0A0B` |
| Cartões | `#151516` / borda `#262628` |
| Texto | `#F2F2F0` · secundário `#8A8A8E` |
| Destaque (verde-limão) | `#C6FF5E` |
| Alerta / despesa | `#F2B84B` / `#FF5C5C` |

- **Marca-mãe:** logotipo "fluxo" em Manrope ExtraBold, verde-limão. Assina os
  posts institucionais (rodapé "fluxo ecossistema").
- **Produtos:** cada app usa o próprio ícone. Posts do Fluxo+ levam o "F+" e o
  nome "Fluxo+" no rodapé.
- Fonte: **Manrope** (ExtraBold nos títulos, Medium nos textos).
- Formato dos posts: **1080×1350 (4:5)** — ocupa mais espaço no feed.
- Uma ideia por post; destaque em verde só a parte mais importante da frase.
- Etiqueta no topo (`PRIVACIDADE`, `DICA DO FLUXO`…) diz o assunto na hora.

## 5. Tom de voz

- **Próximo e direto**, como um amigo organizado — "você", frases curtas.
- **"A Fluxo" / "nós"** para a marca; **"o Fluxo+"** para o app.
- **Sem julgamento**: nada de "pare de gastar com besteira".
- **Honesto**: só prometa o que já existe. Premium do Fluxo+ e apps futuros
  são "em breve" — sem datas até estarem certas.
- Evite jargão; quando usar, explique.

## 6. Pilares de conteúdo

| Pilar | % do feed | Exemplos |
|---|---|---|
| Educação e organização | 35% | 50/30/20, reserva de emergência, assinaturas esquecidas, rotina |
| Produtos | 30% | Recursos e tutoriais do Fluxo+, novidades de versão, lançamentos de apps novos |
| Marca e princípios | 20% | Privacidade, código aberto, gratuito, visão do ecossistema |
| Comunidade e bastidores | 15% | Enquetes, dúvidas, depoimentos, como os apps são feitos |

Frequência inicial realista: **3 posts por semana** (seg/qua/sex) + **stories
3–5×/semana**. Constância vale mais que volume.

## 7. Os 9 primeiros posts

Poste **na ordem 01 → 09**. O post 01 apresenta a Fluxo; do 02 ao 05 o
Fluxo+; 06 e 07 são dicas; 08 traz os princípios da marca; o 09 (verde,
"Baixe agora") fica no topo da grade, porque o feed mostra o mais recente primeiro.

### Post 01 — Fluxo Ecossistema · [`post-01.png`](imagens/post-01.png)

```
Prazer, somos a Fluxo 💚

Um ecossistema de apps para organizar a vida sem abrir mão da sua privacidade.

Aqui a tecnologia trabalha para você — não o contrário:
🔒 Seus dados são seus
📱 Funciona no seu aparelho, até sem internet
🔓 Código aberto
🎁 O essencial é sempre gratuito

Nosso primeiro app já está no ar: o Fluxo+, de finanças pessoais. E vem mais por aí 👀

#fluxoecossistema #tecnologia #privacidade #opensource #fluxoplus
```

### Post 02 — Fluxo+: apresentação · [`post-02.png`](imagens/post-02.png)

```
Conheça o Fluxo+, o primeiro app do ecossistema Fluxo 💚

Um app de finanças pessoais que respeita você:
✅ Gratuito
✅ Funciona sem internet
✅ Sem login — seus dados ficam no seu aparelho
✅ Código aberto

Receitas, despesas, vencimentos, parcelas, metas e relatórios em um só lugar.

Disponível para Android e Windows. Link na bio 👆

#fluxoecossistema #fluxoplus #financaspessoais #controlefinanceiro #organizacaofinanceira #educacaofinanceira
```

### Post 03 — Fluxo+: privacidade · [`post-03.png`](imagens/post-03.png)

```
Seu extrato conta muito sobre a sua vida. Por isso ele não deveria morar no servidor de ninguém.

No Fluxo+ você não cria conta, não faz login e nenhuma informação financeira sai do aparelho. Ainda dá para travar o app com PIN ou biometria e fazer backup em um arquivo protegido por senha.

Privacidade não é recurso extra. É o padrão.

#fluxoplus #privacidade #financaspessoais #segurancadigital #appdefinancas
```

### Post 04 — Fluxo+: offline · [`post-04.png`](imagens/post-04.png)

```
Gastou? Anota na hora — com ou sem sinal. 📴

O Fluxo+ funciona 100% offline: na fila do mercado, no metrô, na viagem, no sítio. Nada depende de internet para você registrar e consultar suas finanças.

Qual o lugar mais sem sinal em que você já precisou anotar um gasto? 👇

#fluxoplus #offline #controlefinanceiro #financaspessoais #dicasdefinancas
```

### Post 05 — Fluxo+: recursos · [`post-05.png`](imagens/post-05.png)

```
O que tem no Fluxo+? 👀

📊 Painel do mês com saldo, previsão e gastos por categoria
📅 Vencimentos e compras parceladas
🔁 Lançamentos recorrentes: aluguel, salário, assinaturas
🎯 Metas com prazo
📈 Relatórios mensais
🌗 Tema claro e escuro

Tudo gratuito e ilimitado. Salve este post para lembrar 📌

#fluxoplus #controlefinanceiro #planejamentofinanceiro #organizacaofinanceira #financaspessoais
```

### Post 06 — Dica 50/30/20 · [`post-06.png`](imagens/post-06.png)

```
Não sabe por onde começar a dividir o salário? Teste a regra 50/30/20:

🟢 50% para necessidades — moradia, contas, mercado, transporte
🟢 30% para desejos — lazer, delivery, assinaturas
🟢 20% para o futuro — reserva de emergência e metas

Não é lei: ajuste à sua realidade. O importante é saber para onde o dinheiro vai — e o painel por categoria do Fluxo+ mostra isso em segundos.

Salve e mande para quem precisa 📌

#educacaofinanceira #regra503020 #financaspessoais #dicasdefinancas #fluxoplus
```

### Post 07 — Vencimentos · [`post-07.png`](imagens/post-07.png)

```
Juros de atraso é o dinheiro mais bobo que existe. 💸

No Fluxo+ você cadastra contas com vencimento, divide compras em parcelas e marca lançamentos recorrentes. O app avisa o que vence e mostra o que já foi pago.

Chega de "ih, esqueci o boleto".

#fluxoplus #contasapagar #organizacaofinanceira #controlefinanceiro #financaspessoais
```

### Post 08 — Princípios da Fluxo · [`post-08.png`](imagens/post-08.png)

```
Todo app da Fluxo nasce destes 4 princípios:

🔒 Privacidade por padrão — seus dados são seus, não produto
📱 Seus dados no seu aparelho — nuvem só quando você escolher
🔓 Código aberto — qualquer pessoa pode conferir o código no GitHub
🎁 O essencial é gratuito — sem anúncios e sem pegadinha

O Fluxo+ foi o primeiro. Os próximos seguem o mesmo caminho.

#fluxoecossistema #privacidade #opensource #codigoaberto #tecnologia
```

### Post 09 — Baixe · [`post-09.png`](imagens/post-09.png)

```
Pronto para organizar o seu fluxo? 💚

O Fluxo+ é gratuito para sempre: transações, contas, metas e relatórios sem limite e sem anúncios.

⬇️ Baixe grátis no link da bio
📱 Android (APK) · 💻 Windows

O app avisa sozinho quando sair versão nova. Conta pra gente o que achou nos comentários!

#fluxoplus #financaspessoais #controlefinanceiro #appdefinancas #organizacaofinanceira
```

## 8. Calendário do primeiro mês

| Semana | Segunda | Quarta | Sexta | Stories |
|---|---|---|---|---|
| 1 | 01 Fluxo Ecossistema | 02 Fluxo+ | 03 Privacidade | Bastidores: por que a Fluxo nasceu |
| 2 | 04 Offline | 05 Recursos | 06 Dica 50/30/20 | Enquete: "Você anota seus gastos?" |
| 3 | 07 Vencimentos | 08 Princípios da Fluxo | 09 Baixe agora | Tutorial: como instalar o Fluxo+ |
| 4 | Dica: reserva de emergência | Novidade da última versão do Fluxo+ | Carrossel: assinaturas esquecidas | Caixa de perguntas: "Que app você quer que a Fluxo crie?" |

Horários com bom alcance para público brasileiro: **12h–13h** e **19h–21h**
(ajuste depois pelos Insights do perfil).

## 9. Rotina e métricas

- Responda comentários e DMs em até 24 h — no começo, cada pessoa conta.
- Toda versão nova (`docs/releases/`) vira story em **Novidades**.
- App novo no ecossistema: post de lançamento + destaque próprio + atualizar a bio.
- Olhe os **Insights** uma vez por semana: alcance, salvamentos e cliques no link.
  Post muito salvo = repita o formato.
- Meta do primeiro trimestre: consistência (36 posts), não número de seguidores.

## 10. Checklist de lançamento

- [ ] E-mail da marca criado
- [ ] Conta criada com o @ escolhido e 2FA ativo
- [ ] Conta profissional (Empresa · Empresa de tecnologia)
- [ ] Foto, nome, bio e link preenchidos
- [ ] 5 destaques criados com as capas (Sobre, Fluxo+, Novidades, Dicas, Dúvidas)
- [ ] Posts 01 a 09 publicados conforme o calendário
- [ ] Link do Instagram adicionado no rodapé do site (`site/index.html`)
