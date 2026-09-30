# Instagram corporativo do Fluxo+

Kit completo para abrir e alimentar o perfil oficial: dados do perfil, identidade
visual, os 9 primeiros posts (já em imagem), capas de destaques, modelo de story,
legendas e calendário do primeiro mês.

Todas as imagens estão em [`imagens/`](imagens/) e são geradas a partir de
[`fonte/pecas.html`](fonte/pecas.html) — para editar um texto, altere o HTML e rode:

```bash
node marketing/instagram/fonte/render.mjs   # requer o pacote playwright
```

---

## 1. Criar a conta

1. Crie um **e-mail próprio da marca** (ex.: `contato.fluxoplus@gmail.com`) —
   não use o e-mail pessoal: separa a vida pessoal do trabalho e facilita
   passar o acesso para outra pessoa no futuro.
2. No app do Instagram: **Criar nova conta** com esse e-mail.
3. Usuário: **`@fluxoplus.app`** (alternativas se estiver ocupado:
   `@fluxoplus`, `@fluxoplusapp`, `@usefluxoplus`).
   Se mudar o @, troque também o texto `@fluxoplus.app` em `fonte/pecas.html`
   e gere as imagens de novo.
4. **Configurações → Tipo de conta → Mudar para conta profissional → Empresa**.
   Categoria: **Aplicativo** (ou "Software" / "Serviços financeiros").
5. Ative a **autenticação em dois fatores** e guarde os códigos de backup.
6. Opcional: crie a página no Facebook e vincule (necessário para Meta Business
   Suite, agendamento e anúncios).

## 2. Perfil

| Campo | Conteúdo |
|---|---|
| Foto | [`imagens/perfil.png`](imagens/perfil.png) (1080×1080, recortada em círculo) |
| Nome | `Fluxo+ · Finanças pessoais` (o nome entra na busca — por isso a palavra-chave) |
| Usuário | `@fluxoplus.app` |
| Categoria | Aplicativo |
| Link | `https://lincoln201.github.io/Fluxo-Plus/` |

**Bio** (até 150 caracteres):

```
Seu dinheiro organizado, no seu aparelho 💚
📴 Funciona sem internet · sem login
🔒 Grátis e de código aberto
⬇️ Android e Windows
```

## 3. Destaques (stories fixos)

Suba cada capa como story, fixe em um destaque e use a imagem como capa.

| Destaque | Capa | O que guardar |
|---|---|---|
| Novidades | [`destaque-novidades.png`](imagens/destaque-novidades.png) | Cada versão nova (use as notas de `docs/releases/`) |
| Dicas | [`destaque-dicas.png`](imagens/destaque-dicas.png) | Dicas de finanças |
| Tutoriais | [`destaque-tutoriais.png`](imagens/destaque-tutoriais.png) | Como instalar o APK, criar conta, fazer backup |
| Premium | [`destaque-premium.png`](imagens/destaque-premium.png) | O que vem no Premium (quando abrir as assinaturas) |
| Dúvidas | [`destaque-duvidas.png`](imagens/destaque-duvidas.png) | Perguntas frequentes do site |

## 4. Identidade visual

Mesma identidade **Grafite** do app e do site (`lib/core/theme/app_colors.dart`).

| Uso | Cor |
|---|---|
| Fundo | `#0A0A0B` |
| Cartões | `#151516` / borda `#262628` |
| Texto | `#F2F2F0` · secundário `#8A8A8E` |
| Destaque (verde-limão) | `#C6FF5E` |
| Alerta / despesa | `#F2B84B` / `#FF5C5C` |

- Fonte: **Manrope** (ExtraBold nos títulos, Medium nos textos).
- Formato dos posts: **1080×1350 (4:5)** — ocupa mais espaço no feed.
- Uma ideia por post; destaque em verde só a parte mais importante da frase.
- Etiqueta no topo (`PRIVACIDADE`, `DICA DO FLUXO`…) diz o assunto na hora.

## 5. Tom de voz

- **Próximo e direto**, como um amigo organizado — "você", frases curtas.
- **Sem julgamento**: nada de "pare de gastar com besteira".
- **Honesto**: só prometa o que o app já faz. Premium ainda não está aberto —
  fale como "em breve".
- Evite jargão financeiro; quando usar, explique.

## 6. Pilares de conteúdo

| Pilar | % do feed | Exemplos |
|---|---|---|
| Educação financeira | 40% | 50/30/20, reserva de emergência, controlar assinaturas, cartão de crédito |
| Produto | 30% | Recursos, tutoriais, novidades de versão |
| Valores da marca | 20% | Privacidade, offline, código aberto, gratuito |
| Comunidade | 10% | Enquetes, respostas a dúvidas, depoimentos, bastidores do desenvolvimento |

Frequência inicial realista: **3 posts por semana** (seg/qua/sex) + **stories
3–5×/semana**. Constância vale mais que volume.

## 7. Os 9 primeiros posts

Poste **na ordem 01 → 09**. Como o feed mostra o mais recente primeiro, o post
09 (verde, "Baixe agora") fica no topo da grade.

### Post 01 — Apresentação · [`post-01.png`](imagens/post-01.png)

```
Chegou o Fluxo+ 💚

Um app de finanças pessoais que respeita você:
✅ Gratuito
✅ Funciona sem internet
✅ Sem login — seus dados ficam no seu aparelho
✅ Código aberto

Receitas, despesas, vencimentos, parcelas, metas e relatórios em um só lugar.

Disponível para Android e Windows. Link na bio 👆

#fluxoplus #financaspessoais #controlefinanceiro #organizacaofinanceira #educacaofinanceira
```

### Post 02 — Privacidade · [`post-02.png`](imagens/post-02.png)

```
Seu extrato conta muito sobre a sua vida. Por isso ele não deveria morar no servidor de ninguém.

No Fluxo+ você não cria conta, não faz login e nenhuma informação financeira sai do aparelho. Ainda dá para travar o app com PIN ou biometria e fazer backup em um arquivo protegido por senha.

Privacidade não é recurso extra. É o padrão.

#fluxoplus #privacidade #financaspessoais #segurancadigital #appdefinancas
```

### Post 03 — Offline · [`post-03.png`](imagens/post-03.png)

```
Gastou? Anota na hora — com ou sem sinal. 📴

O Fluxo+ funciona 100% offline: na fila do mercado, no metrô, na viagem, no sítio. Nada depende de internet para você registrar e consultar suas finanças.

Qual o lugar mais sem sinal em que você já precisou anotar um gasto? 👇

#fluxoplus #offline #controlefinanceiro #financaspessoais #dicasdefinancas
```

### Post 04 — Recursos · [`post-04.png`](imagens/post-04.png)

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

### Post 05 — Gratuito · [`post-05.png`](imagens/post-05.png)

```
"Mas qual é a pegadinha?" 🤔

Nenhuma. O Fluxo+ é gratuito para sempre: transações, contas, categorias, metas e relatórios sem limite, sem anúncio e sem vender seus dados.

Em breve teremos um plano Premium opcional para quem quiser backup na nuvem e sincronização entre aparelhos. O essencial continua grátis.

#fluxoplus #appgratuito #financaspessoais #controlefinanceiro #economia
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

### Post 08 — Código aberto · [`post-08.png`](imagens/post-08.png)

```
Por que o Fluxo+ é open source? 🔓

Porque um app que cuida do seu dinheiro precisa merecer sua confiança. Todo o código está publicado no GitHub, sob licença MIT: qualquer pessoa pode conferir como o app funciona e o que ele faz (e não faz) com os seus dados.

Dev? Contribuições são bem-vindas 🤝

#opensource #codigoaberto #flutter #fluxoplus #financaspessoais
```

### Post 09 — Baixe · [`post-09.png`](imagens/post-09.png)

```
Pronto para organizar o seu fluxo? 💚

⬇️ Baixe grátis no link da bio
📱 Android (APK) · 💻 Windows

O app avisa sozinho quando sair versão nova. Conta pra gente o que achou nos comentários!

#fluxoplus #financaspessoais #controlefinanceiro #appdefinancas #organizacaofinanceira
```

## 8. Calendário do primeiro mês

| Semana | Segunda | Quarta | Sexta | Stories |
|---|---|---|---|---|
| 1 | 01 Apresentação | 02 Privacidade | 03 Offline | Bastidores: por que o app foi criado |
| 2 | 04 Recursos | 05 Gratuito | 06 Dica 50/30/20 | Enquete: "Você anota seus gastos?" |
| 3 | 07 Vencimentos | 08 Código aberto | 09 Baixe agora | Tutorial: como instalar o APK |
| 4 | Dica: reserva de emergência | Novidade da última versão | Carrossel: assinaturas esquecidas | Caixa de perguntas |

Horários com bom alcance para público brasileiro: **12h–13h** e **19h–21h**
(ajuste depois pelos Insights do perfil).

## 9. Rotina e métricas

- Responda comentários e DMs em até 24 h — no começo, cada pessoa conta.
- Toda versão nova (`docs/releases/`) vira story em **Novidades**.
- Olhe os **Insights** uma vez por semana: alcance, salvamentos e cliques no link.
  Post muito salvo = repita o formato.
- Meta do primeiro trimestre: consistência (36 posts), não número de seguidores.

## 10. Checklist de lançamento

- [ ] E-mail da marca criado
- [ ] Conta criada com o @ escolhido e 2FA ativo
- [ ] Conta profissional (Empresa · Aplicativo)
- [ ] Foto, nome, bio e link preenchidos
- [ ] 5 destaques criados com as capas
- [ ] Posts 01 a 09 publicados conforme o calendário
- [ ] Link do Instagram adicionado no rodapé do site (`site/index.html`)
