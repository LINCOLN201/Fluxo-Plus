# Publicação e atualizações

O Fluxo+ continua totalmente funcional sem internet. Quando uma versão pública
é compilada pelo GitHub Actions, o endereço do repositório é incorporado ao app.
Ao iniciar com conexão, ele consulta a última GitHub Release e oferece o arquivo
correto para Windows ou Android.

## 1. Criar o repositório

Publique este código em um repositório GitHub. O workflow descobre
automaticamente o identificador `owner/repository`.

## 2. Criar a chave Android

Execute uma única vez e guarde o arquivo e as senhas em local seguro:

```powershell
keytool -genkeypair -v `
  -keystore upload-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload
```

Nunca faça commit do `.jks`. Se essa chave for perdida, APKs já instalados não
aceitarão novas versões distribuídas diretamente.

Converta o arquivo para Base64:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("upload-keystore.jks")
) | Set-Clipboard
```

Cadastre estes Actions Secrets no GitHub:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

## 3. Fluxo de desenvolvimento

Toda alteração deve começar na branch `dev`:

```powershell
git switch dev
git pull origin dev
```

Cada push para `dev` executa o workflow
`.github/workflows/quality.yml`, que valida:

- formatação;
- análise estática;
- testes automatizados;
- compilação de APK de teste;
- compilação do aplicativo Windows de teste.

Os builds de teste ficam disponíveis como artefatos temporários por sete dias.
Não crie uma tag enquanto essas verificações estiverem pendentes ou falhando.

Quando todas as verificações passarem, abra um Pull Request de `dev` para
`main`. A `main` representa exclusivamente código validado e pronto para uma
futura publicação.

## 4. Publicar

Depois do Pull Request aprovado e integrado à `main`, atualize a versão do
`pubspec.yaml`, valide novamente e crie uma tag igual:

```powershell
git switch main
git pull origin main
git tag v0.2.0
git push origin v0.2.0
```

O workflow `.github/workflows/release.yml` executa análise e testes, gera:

- `fluxo-plus-android.apk`;
- `fluxo-plus-windows.zip`;
- uma GitHub Release com notas automáticas.

Antes de criar a tag, escreva `docs/releases/vX.Y.Z.md` com as novidades em
linguagem simples. Esse texto abre a Release e aparece no aviso de
atualização dentro do app (as primeiras 7 linhas), por isso use frases curtas.
Inclua `[mandatory]` somente se a atualização for obrigatória.

O `--build-name` usa a própria tag. Isso garante que o app instalado reconheça
corretamente a próxima versão.

Resumindo: `dev` → CI verde → Pull Request → `main` → tag → publicação.

O workflow de release também verifica se o commit marcado pela tag pertence à
`main`. Uma tag criada diretamente na `dev` será recusada e não produzirá APK,
Windows ou GitHub Release.

## Comportamento da atualização

- Android: baixa o APK e o sistema solicita confirmação para instalar. O Android
  não permite instalação silenciosa de APK comum.
- Windows: baixa o ZIP da versão. O usuário substitui a instalação atual.
- Sem conexão ou se o GitHub estiver indisponível: nenhuma mensagem aparece e
  todas as funções locais continuam disponíveis.

Uma etapa futura pode trocar o ZIP do Windows por MSIX/App Installer assinado,
permitindo instalação e atualização gerenciadas pelo próprio Windows.

## 5. Notificação push de atualização (opcional, só Android)

Além de o app verificar sozinho quando é aberto, dá para avisar quem já
instalou mesmo com o app fechado há dias, com uma notificação de verdade na
barra do celular. Sem isso configurado, o app funciona exatamente igual — só
não manda essa notificação.

### 5.1. Criar o projeto no Firebase

1. Acesse [console.firebase.google.com](https://console.firebase.google.com) e
   crie um projeto novo (gratuito, sem cartão).
2. Dentro do projeto, adicione um app **Android** com o pacote
   `br.com.fluxoplus.app` (o mesmo `applicationId` do
   `android/app/build.gradle.kts`).
3. Baixe o arquivo **`google-services.json`** gerado nessa etapa.
4. Para rodar localmente (`flutter run`), coloque esse arquivo em
   `android/app/google-services.json` — ele já está no `.gitignore`, nunca é
   commitado. Para builds locais sem esse arquivo, o app compila normal, só
   sem notificações.
5. Anote o **Project ID** (aparece em Configurações do projeto → Geral).

### 5.2. Criar a chave de serviço (para o GitHub Actions enviar o aviso)

1. Configurações do projeto → **Contas de serviço** → **Gerar nova chave
   privada**. Baixa um arquivo `.json`.
2. Converta para Base64:

   ```powershell
   [Convert]::ToBase64String(
     [IO.File]::ReadAllBytes("nome-do-arquivo.json")
   ) | Set-Clipboard
   ```

### 5.3. Cadastrar os Secrets

Em Settings → Secrets and variables → Actions do repositório, adicione:

- `FIREBASE_PROJECT_ID` — o Project ID da etapa 5.1.
- `FIREBASE_SERVICE_ACCOUNT_BASE64` — o conteúdo em Base64 da etapa 5.2.

Na próxima tag publicada, o job **"Avisar quem já instalou (push)"** do
`release.yml` roda automaticamente e manda a notificação. Sem esses dois
Secrets, esse job é pulado — nada quebra.

O app se inscreve sozinho no aviso assim que abre pela primeira vez, sem
conta nem cadastro: é um único tópico do Firebase Cloud Messaging
(`atualizacoes`), sem identificar quem instalou.
