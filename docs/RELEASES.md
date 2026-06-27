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

## 3. Publicar

Atualize a versão do `pubspec.yaml`, faça commit e crie uma tag igual:

```powershell
git tag v0.2.0
git push origin main
git push origin v0.2.0
```

O workflow `.github/workflows/release.yml` executa análise e testes, gera:

- `fluxo-plus-android.apk`;
- `fluxo-plus-windows.zip`;
- uma GitHub Release com notas automáticas.

O `--build-name` usa a própria tag. Isso garante que o app instalado reconheça
corretamente a próxima versão.

## Comportamento da atualização

- Android: baixa o APK e o sistema solicita confirmação para instalar. O Android
  não permite instalação silenciosa de APK comum.
- Windows: baixa o ZIP da versão. O usuário substitui a instalação atual.
- Sem conexão ou se o GitHub estiver indisponível: nenhuma mensagem aparece e
  todas as funções locais continuam disponíveis.

Uma etapa futura pode trocar o ZIP do Windows por MSIX/App Installer assinado,
permitindo instalação e atualização gerenciadas pelo próprio Windows.
