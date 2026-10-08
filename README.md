# Fluxo+

Aplicativo de finanças pessoais, gratuito e open source, que funciona **sem
internet** — seus dados ficam no seu aparelho, não em algum servidor.

**[Conhecer e baixar no site oficial](https://lincoln201.github.io/Fluxo-Plus/)**
· disponível para Android, Windows e Linux.

## O que o Fluxo+ faz

- Receitas, despesas, vencimentos, parcelas e lançamentos recorrentes
  (aluguel, assinaturas, salário fixo);
- Dashboard com saldo, previsão do mês e despesas por categoria;
- Contas, categorias personalizadas e metas financeiras com prazo;
- Relatórios mensais;
- Backup local protegido por senha — sem depender de nuvem de terceiro;
- Bloqueio por PIN e biometria;
- Sincronização opcional entre aparelhos (Premium), com backup criptografado
  na nuvem;
- Temas claro e escuro.

Sem login, nenhuma informação financeira sai do aparelho. A política de
privacidade completa está no
[site oficial](https://lincoln201.github.io/Fluxo-Plus/privacidade.html).

## Licença

Distribuído sob a licença MIT. Consulte [LICENSE](LICENSE).

---

## Para desenvolvedores

O restante deste documento é sobre compilar e contribuir com o código —
não é necessário para só usar o app (baixe pelo link acima).

### Requisitos

- Flutter estável atual (Dart 3.4 ou superior);
- Android Studio/SDK para Android;
- Xcode em um Mac para iOS e macOS;
- Visual Studio 2022 com **Desktop development with C++** para Windows;
- toolchain GTK exigida pelo Flutter para Linux.

Confira a instalação com:

```powershell
flutter doctor
```

### Preparar e rodar

Este repositório contém todo o código do app. Como os runners nativos são
gerados pelo próprio Flutter, rode uma vez, na raiz:

```powershell
flutter create --project-name fluxo_plus --org br.com.fluxoplus --platforms android,ios,windows,macos,linux .
flutter pub get
flutter analyze
flutter test
flutter run
```

No Windows, o mesmo processo pode ser executado com:

```powershell
.\scripts\bootstrap.ps1
```

Escolha um dispositivo específico com `flutter devices` e
`flutter run -d <id>`. O banco fica no diretório de suporte privado da aplicação
e é criado automaticamente na primeira execução.

### Gerar APK

```powershell
flutter build apk --release
```

O arquivo será criado em `build/app/outputs/flutter-apk/app-release.apk`.
Para publicação na Play Store, prefira `flutter build appbundle --release` e
configure uma chave de assinatura própria.

### Gerar EXE para Windows

Em um Windows com o workload C++ do Visual Studio:

```powershell
flutter config --enable-windows-desktop
flutter build windows --release
```

O executável e suas DLLs ficam em
`build/windows/x64/runner/Release/`. Distribua a pasta inteira, não apenas o
`.exe`.

### Gerar pacote para Linux

Em um Linux com as dependências de build (`clang cmake ninja-build
pkg-config libgtk-3-dev`):

```bash
flutter config --enable-linux-desktop
flutter build linux --release
```

O executável e suas bibliotecas ficam em
`build/linux/x64/release/bundle/`. Distribua a pasta inteira, não apenas o
binário.

### Publicação e atualizações automáticas

O projeto inclui GitHub Actions para validar o código e publicar APK, Windows
e Linux automaticamente a cada tag de versão. Builds públicos consultam a última GitHub
Release ao iniciar e oferecem a atualização adequada, sem afetar o modo
offline. No Android, dá para avisar por notificação push mesmo com o app
fechado (opcional, via Firebase Cloud Messaging — ver seção 5 de
[docs/RELEASES.md](docs/RELEASES.md)).

Consulte [docs/RELEASES.md](docs/RELEASES.md) para configurar a assinatura
Android, os Secrets e publicar a primeira versão.

Para habilitar autenticação, sincronização e backup em nuvem, consulte
[docs/SUPABASE.md](docs/SUPABASE.md) e execute o schema com RLS incluído no
projeto.

O modelo comercial e a separação entre recursos gratuitos e serviços Premium
estão documentados em [docs/MONETIZATION.md](docs/MONETIZATION.md).

### Fluxo de contribuição

O desenvolvimento acontece na branch `dev`. Cada alteração passa por análise,
testes e builds Android/Windows/Linux antes de entrar na `main`. A publicação
só é iniciada depois da integração validada, por meio de uma tag de versão.

O que falta, por fase, está em [docs/ROADMAP.md](docs/ROADMAP.md).

Consulte [docs/RELEASES.md](docs/RELEASES.md) para o fluxo completo:
`dev` → CI → Pull Request → `main` → release.

### Estrutura

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── backup/        backup local criptografado
│   ├── constants/
│   ├── database/      SQLite, migrações e snapshots
│   ├── premium/
│   ├── security/      PIN e biometria
│   ├── sync/          sincronização com Supabase
│   ├── theme/
│   ├── update/
│   └── utils/
├── features/
│   ├── accounts/  categories/  dashboard/  goals/
│   ├── notifications/  onboarding/  premium/  reports/
│   ├── settings/  shell/  splash/  transactions/
└── shared/
    ├── models/
    └── widgets/
site/                  site oficial (GitHub Pages)
```

### Segurança

Detalhes técnicos das proteções em [docs/SECURITY.md](docs/SECURITY.md).
