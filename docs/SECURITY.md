# Segurança do Fluxo+

O que protegemos, como, e o que ainda falta. Atualize a cada mudança que
envolva dados.

## Onde os dados ficam

| Dado | Onde | Proteção |
|------|------|----------|
| Contas, transações, metas, categorias | SQLite no diretório privado do app | Sandbox do sistema; fora do backup do Google (Android) |
| PIN | Tabela `settings` | Só o hash PBKDF2-SHA256 com sal; nunca sai do aparelho |
| Sessão da conta (tokens) | Keystore (Android) / cofre de credenciais (Windows) | `SecureSessionStorage` |
| Backup local | Arquivo `.fluxobackup` escolhido pelo usuário | AES-256-GCM, chave derivada da senha (PBKDF2, 200 mil iterações) |
| Cópia antes de restaurar | Diretório privado do app | Expira em 7 dias |
| Backup na nuvem | Supabase `user_backups` | HTTPS + RLS (cada usuário só lê/grava o próprio) |

## Medidas em vigor

**Aparelho**
- `allowBackup=false` e regras de extração: o banco não vai para o backup do
  Google Drive nem para a transferência entre aparelhos.
- `FLAG_SECURE` ligado por padrão: nada aparece em capturas, gravações e na
  miniatura dos apps recentes (o usuário pode desligar, com confirmação).
- Tráfego sem criptografia proibido (`usesCleartextTraffic=false`).
- Bloqueio por PIN e/ou biometria ao abrir e ao voltar para o app.
- PIN com limite de tentativas: 5 erros → espera de 30 s, dobrando a cada
  erro até 1 hora; o contador fica gravado (reabrir o app não zera).
- Desligar biometria, PIN ou a proteção de tela exige confirmar identidade.
- Exportar, importar, restaurar ou desfazer restauração exige PIN/biometria
  quando o bloqueio está ativo.

**Dados**
- Valores em centavos inteiros; consultas SQL sempre parametrizadas.
- Restauração valida o formato, recusa versões futuras e guarda cópia antes.
- Configurações do aparelho (PIN, tema, bloqueio) nunca entram em backups.

**Atualizações**
- Só aceita instaladores de `github.com` via HTTPS.
- Cada Release publica `.sha256`; o app confere o APK antes de instalar e
  descarta o arquivo se não bater. O Android ainda confere a assinatura.
- O APK baixado fica numa pasta própria, a única exposta ao instalador.

**Nuvem (Supabase)** — `supabase/schema.sql`
- RLS em todas as tabelas; visitantes sem login (`anon`) sem acesso.
- O app não pode apagar backups nem alterar assinaturas.
- Backup precisa ser um objeto JSON de até 20 MB.

**Site**
- Content-Security-Policy restritiva (sem scripts), sem referrer.

## Próximos passos recomendados

1. **Criptografar o banco local (SQLCipher)**, com a chave no Keystore/cofre.
   Protege contra aparelho com root ou cópia física do armazenamento. Exige
   trocar o `sqflite` e migrar bancos existentes; deve ser feito numa versão
   própria e testado em aparelho real antes de publicar.
2. **Criptografia de ponta a ponta no backup da nuvem**, com uma senha de
   sincronização que só o usuário conhece: nem o Supabase conseguiria ler os
   dados. Exige cuidado com recuperação (senha perdida = backup perdido).
3. **Excluir conta pelo app** (LGPD), com função no servidor.
4. **Assinatura de código do Windows**.
5. Rodar o verificador de segurança do Supabase (`get_advisors`) a cada
   mudança no banco.

## Teste de invasão (25/09/2026)

Ataques reais, executados contra o app compilado e o código, não só teoria.
Achados por gravidade, já com o que foi corrigido.

### Corrigido nesta rodada

- **Condição de corrida no bloqueio do PIN** — disparando várias tentativas
  de PIN ao mesmo tempo (um script de ataque, não uma pessoa digitando),
  o contador de erros perdia gravações por causa da disputa entre as
  tentativas simultâneas, e o bloqueio nunca chegava a ativar. Comprovado:
  10 tentativas erradas em paralelo, e o PIN certo ainda era aceito logo
  em seguida, sem nenhuma espera. **Corrigido:** a checagem e a gravação
  do contador agora acontecem dentro de uma transação do banco, que
  serializa tentativas concorrentes.
- **Builds de produção sem ofuscação** — o APK e o instalador do Windows
  saíam com todos os nomes de classes, métodos e mensagens do código
  legíveis, facilitando engenharia reversa. **Corrigido:** os workflows de
  publicação agora usam `--obfuscate`; os símbolos para decifrar relatórios
  de falha ficam guardados só como artefato interno do CI, nunca públicos.
- **Cópia de segurança em texto puro** — o arquivo gravado automaticamente
  antes de qualquer restauração (nuvem, local ou "desfazer") guardava todos
  os lançamentos em JSON simples, sem nenhuma proteção, mesmo que o usuário
  tivesse acabado de proteger o backup com uma senha forte. Comprovado lendo
  o conteúdo do arquivo diretamente do disco. **Corrigido:** agora é
  cifrado com AES-256-GCM e uma chave gerada no aparelho, guardada no
  Keystore/cofre — "Desfazer" continua sendo um toque, sem pedir senha.
- **Nome do arquivo da atualização vulnerável a path traversal** — o app
  usava o número da versão vindo da Release do GitHub direto no caminho do
  arquivo baixado, sem checar o conteúdo. Uma tag maliciosa (só possível se
  o próprio repositório de releases fosse comprometido) podia levar o
  arquivo baixado para fora da pasta pretendida. **Corrigido:** o nome do
  arquivo agora é fixo, sem nenhum dado vindo da internet.
- **Senha mínima do backup local fraca** — 6 caracteres (`"123456"` valia)
  não é páreo para um ataque offline, mesmo com 200 mil iterações de
  PBKDF2. **Corrigido:** mínimo de 10 caracteres, com sugestão de usar uma
  frase em vez de uma palavra só.

### Risco conhecido, sem correção nesta versão (ver item 1 acima)

- **[Crítico] O banco de dados local não é criptografado.** Copiando o
  arquivo `fluxo_plus.db` do aparelho (USB debugging, root, backup, malware
  com acesso ao armazenamento), qualquer programa comum lê todas as
  transações, saldos e o hash do PIN, sem passar pelo app. Comprovado: dump
  direto do arquivo com um script Python, sem nenhuma senha.
- **[Crítico], mesma causa** — **o bloqueio de tentativas do PIN só existe
  na tela do app.** Quem tem o arquivo do banco pode: (a) rodar força
  bruta offline sem nenhum limite — comprovado: um PIN de 4 dígitos foi
  quebrado em ~103 segundos com um script Python simples de uma só
  thread, sem otimização (um ataque de verdade, com GPU, faz isso em
  segundos); ou (b) apagar as linhas do PIN direto no banco e abrir o app
  sem nenhuma tela de bloqueio — comprovado ao vivo no app compilado.
  A solução dos dois é a mesma: criptografar o banco (item 1 acima).

### Testado e resistiu

- Backup local criptografado: senha errada é recusada, e qualquer byte
  adulterado no arquivo é detectado e rejeitado (autenticação do AES-GCM),
  com sal e nonce sempre novos a cada exportação.
- Nenhuma tentativa de injeção de SQL funcionou em nenhum campo de texto
  (todas as consultas usam parâmetros, nunca concatenação).
- O site não tem superfície de ataque: é estático, sem JavaScript, com
  Content-Security-Policy restritiva.
- A tela de bloqueio (PIN pela interface) respeita o limite de tentativas
  mesmo com a senha certa, enquanto o tempo de espera não passa.

### Risco aceito: o PIN fica na memória do app enquanto ele roda

Com o app aberto de verdade, tirei um retrato da memória do processo
(`gcore`) logo depois de digitar o PIN e fechar aquela tela — e o PIN
apareceu em texto puro, duas vezes, dentro da memória do próprio app.
É uma limitação do Dart/Flutter: strings não são apagadas da memória
quando deixam de ser usadas, ficam para trás até o coletor de lixo
reaproveitar aquele espaço, sem hora certa para isso.

Isso **não é o mesmo problema do banco de dados**: aqui, o invasor
precisa ter o mesmo nível de acesso de quem já invadiu o aparelho inteiro
(root ou depuração ligada, com o app aberto e destravado). Não é algo que
alguém consiga fazer só copiando um arquivo, como no caso do banco. Por
isso não é uma prioridade agora — mas fica registrado, porque nenhum
app feito em Flutter escapa dessa limitação sem escrever a comparação de
senhas em código nativo (fora do Dart), o que é um projeto à parte.

### Observação de baixo risco

- Os segredos do Supabase usados no build de teste (`SUPABASE_URL` e
  `SUPABASE_PUBLISHABLE_KEY`) ficam acessíveis a um PR de fora do
  repositório, por causa de como o GitHub Actions trata o gatilho
  `pull_request`. Não é grave hoje — são chaves públicas por natureza,
  protegidas pelas regras do banco (RLS), e as senhas de assinatura do
  Android já ficam de fora desse caminho, isoladas no workflow que só roda
  por tag. Mas vale não colocar nenhum segredo sensível em `quality.yml`
  no futuro sem repensar isso.

## Como reportar uma falha

Abra uma issue em <https://github.com/LINCOLN201/Fluxo-Plus/issues> **sem**
detalhes que permitam explorar a falha e peça um canal privado.
