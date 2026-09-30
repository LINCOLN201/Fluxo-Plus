# Instagram corporativo da Fluxo Ecossistema

Kit para abrir e alimentar o perfil oficial da **Fluxo Ecossistema**: dados do
perfil, identidade visual, os 9 primeiros posts (já em imagem), capas de
destaques, modelo de story, legendas e calendário do primeiro mês.

O perfil é da **marca-mãe** (Fluxo). Cada produto aparece dentro dele:
**Fluxo+** (finanças pessoais, para pessoas) e **FluxoCheck** (rotinas e
prevenção no varejo, para empresas). Produto novo ganha destaque e posts
próprios, sem abrir outra conta.

Logos, cores e regras de uso vêm do [manual da marca](../marca/) — as peças
daqui usam os arquivos de `marketing/marca/logos/`.

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
| Foto | [`imagens/perfil.png`](imagens/perfil.png) — símbolo "três lâminas" da Fluxo (1080×1080, recortada em círculo) |
| Nome | `Fluxo Ecossistema · Apps` (o nome entra na busca) |
| Usuário | `@fluxoecossistema` |
| Categoria | Empresa de tecnologia |
| Link | `https://lincoln201.github.io/Fluxo-Plus/` (troque por um site da Fluxo ou uma página de links quando houver mais de um app) |

**Bio** (até 150 caracteres):

```
Tecnologia que organiza, com você no controle 💚
💰 Fluxo+ · finanças pessoais grátis
✅ FluxoCheck · rotinas do varejo
🔒 Privado por padrão · ⬇️ link
```

## 3. Destaques (stories fixos)

Suba cada capa como story, fixe em um destaque e use a imagem como capa.

| Destaque | Capa | O que guardar |
|---|---|---|
| Sobre | [`destaque-sobre.png`](imagens/destaque-sobre.png) | Quem é a Fluxo, princípios, bastidores |
| Fluxo+ | [`destaque-fluxo-plus.png`](imagens/destaque-fluxo-plus.png) | Tutoriais do app (instalar o APK, backup), Premium quando abrir |
| FluxoCheck | [`destaque-fluxocheck.png`](imagens/destaque-fluxocheck.png) | O que faz, rotinas que cobre, como pedir uma demonstração |
| Novidades | [`destaque-novidades.png`](imagens/destaque-novidades.png) | Cada versão nova de qualquer app (notas em `docs/releases/`) |
| Dicas | [`destaque-dicas.png`](imagens/destaque-dicas.png) | Dicas de finanças e organização |
| Dúvidas | [`destaque-duvidas.png`](imagens/destaque-duvidas.png) | Perguntas frequentes |

Cada app novo do ecossistema ganha um destaque próprio, com o logo dele.

## 4. Identidade visual

Siga o **[manual da marca](../marca/manual-da-marca-fluxo.pdf)**. Resumo:

- **Símbolo "três lâminas"** da Fluxo no perfil e nos posts institucionais.
- Os apps aparecem **sempre com a logo original** + a assinatura "um produto fluxo".
- **Cores:** grafite `#0A0A0B` e lima `#C6FF5E` (≈70% grafite, 10% lima).
- **Fonte:** Manrope — ExtraBold nos títulos, Medium nos textos.
- **Formato:** 1080×1350 (4:5). Uma ideia por post; verde só no trecho-chave.
- Posts institucionais assinam com o logo **fluxo**; posts de produto, com a
  logo do app à esquerda e "um produto fluxo" à direita.
- Para posts novos, use os [templates](../marca/templates/) prontos.

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
| Produtos | 30% | Fluxo+ (recursos, tutoriais) · FluxoCheck (rotinas, bastidores de piloto sem expor o cliente) · novidades |
| Marca e princípios | 20% | Privacidade, código aberto, gratuito, visão do ecossistema |
| Comunidade e bastidores | 15% | Enquetes, dúvidas, depoimentos, como os apps são feitos |

Frequência inicial realista: **3 posts por semana** (seg/qua/sex) + **stories
3–5×/semana**. Constância vale mais que volume.

## 7. Os 9 primeiros posts

Poste **na ordem 01 → 09**. O post 01 apresenta a Fluxo; do 02 ao 05 o
Fluxo+; 06 é dica; 07 apresenta o FluxoCheck; 08 traz os princípios da marca; o 09 (verde,
"Baixe agora") fica no topo da grade, porque o feed mostra o mais recente primeiro.

### Post 01 — Fluxo Ecossistema · [`post-01.png`](imagens/post-01.png)

```
Prazer, somos a Fluxo 💚

Criamos apps que transformam rotinas bagunçadas em fluxos claros — em casa e no trabalho.

💰 Fluxo+ · finanças pessoais, grátis e de código aberto
✅ FluxoCheck · checklists e prevenção para o varejo

Simples de usar, funcionando até sem internet e com os seus dados protegidos. E vem mais por aí 👀

#fluxoecossistema #tecnologia #produtividade #fluxoplus #fluxocheck
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

### Post 07 — FluxoCheck · [`post-07.png`](imagens/post-07.png)

```
Além das finanças de casa, a Fluxo também organiza a rotina da loja 🏪

O FluxoCheck é o nosso sistema de checklists para o varejo:
✅ Temperaturas, balanças, NR-12/EPI e hortifrúti por horário
📴 Funciona offline e sincroniza sozinho
⚠️ Divergência registrada vira ação corretiva
📄 Relatórios em PDF para a liderança de prevenção

Tem loja ou trabalha com prevenção de perdas? Chama no direct para conhecer 👇

#fluxocheck #fluxoecossistema #varejo #prevencaodeperdas #supermercado
```

### Post 08 — Princípios da Fluxo · [`post-08.png`](imagens/post-08.png)

```
Todo produto da Fluxo nasce destes 4 princípios:

➡️ Simples de verdade — feito para o dia a dia, não para especialistas
📴 Funciona sem internet — registra offline e sincroniza quando der
🔒 Privacidade por padrão — seus dados protegidos e sob seu controle
🤝 Sem letra miúda — prometemos só o que entregamos

É assim no Fluxo+, é assim no FluxoCheck e vai ser assim nos próximos.

#fluxoecossistema #privacidade #tecnologia #produtividade #fluxoplus
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
| 3 | 07 FluxoCheck | 08 Princípios da Fluxo | 09 Baixe agora | Tutorial: como instalar o Fluxo+ |
| 4 | Dica: vencimentos e juros de atraso | Novidade da última versão do Fluxo+ | Carrossel: assinaturas esquecidas | Caixa de perguntas: "Que app você quer que a Fluxo crie?" |

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
- [ ] 6 destaques criados com as capas (Sobre, Fluxo+, FluxoCheck, Novidades, Dicas, Dúvidas)
- [ ] Posts 01 a 09 publicados conforme o calendário
- [ ] Link do Instagram adicionado no rodapé do site (`site/index.html`)
