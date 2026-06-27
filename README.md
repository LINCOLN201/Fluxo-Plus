# Fluxo+

Aplicativo open source de finanças pessoais, moderno e offline-first, feito com
Flutter. O Fluxo+ mantém os dados no dispositivo e foi desenhado para Android,
iOS, Windows, macOS e Linux. Web/PWA e sincronização opcional com Supabase estão
no roadmap, mas não fazem parte desta versão.

## O que já funciona

- splash e onboarding persistente;
- dashboard responsivo com saldo, receitas, despesas, economia e lançamentos
  recentes calculados diretamente no SQLite;
- cadastro de receita ou despesa com valor, categoria, conta, data e descrição;
- listagem, edição, exclusão e filtros de transações por mês, tipo e categoria;
- contas com saldo inicial, saldo calculado e proteção de histórico;
- categorias padrão e personalizadas para receitas e despesas;
- metas financeiras com prazo e acompanhamento de progresso;
- relatórios mensais de receita x despesa e gastos por categoria;
- temas escuro (padrão) e claro, com preferência salva localmente;
- SQLite real em Android/iOS (`sqflite`) e desktop
  (`sqflite_common_ffi`);
- conta principal e categorias brasileiras criadas no primeiro uso;
- navegação adaptativa: barra inferior no celular e rail no desktop;
- moeda e datas no padrão brasileiro;
- schema preparado para contas, categorias, transações, metas e configurações;
- arquitetura por features, com persistência e regras fora das telas.

Todas as áreas do MVP estão conectadas ao banco local e funcionam sem internet.

## Requisitos

- Flutter estável atual (Dart 3.4 ou superior);
- Android Studio/SDK para Android;
- Xcode em um Mac para iOS e macOS;
- Visual Studio 2022 com **Desktop development with C++** para Windows;
- toolchain GTK exigida pelo Flutter para Linux.

Confira a instalação com:

```powershell
flutter doctor
```

## Preparar e rodar

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

## Gerar APK

```powershell
flutter build apk --release
```

O arquivo será criado em `build/app/outputs/flutter-apk/app-release.apk`.
Para publicação na Play Store, prefira `flutter build appbundle --release` e
configure uma chave de assinatura própria.

## Gerar EXE para Windows

Em um Windows com o workload C++ do Visual Studio:

```powershell
flutter config --enable-windows-desktop
flutter build windows --release
```

O executável e suas DLLs ficam em
`build/windows/x64/runner/Release/`. Distribua a pasta inteira, não apenas o
`.exe`.

## Atualizações pela internet

O projeto inclui GitHub Actions para validar o código e publicar APK e Windows
automaticamente a cada tag de versão. Builds públicos consultam a última GitHub
Release ao iniciar e oferecem a atualização adequada, sem afetar o modo
offline.

Consulte [docs/RELEASES.md](docs/RELEASES.md) para configurar a assinatura
Android, os Secrets e publicar a primeira versão.

Para habilitar autenticação, sincronização e backup em nuvem, consulte
[docs/SUPABASE.md](docs/SUPABASE.md) e execute o schema com RLS incluído no
projeto.

## Estrutura

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── database/
│   ├── theme/
│   └── utils/
├── features/
│   ├── dashboard/
│   ├── onboarding/
│   ├── shell/
│   ├── splash/
│   └── transactions/
└── shared/
    ├── models/
    └── widgets/
```

O Supabase não é dependência do projeto e nenhuma informação sai do
dispositivo.

## Próximos passos

1. Biometria, PIN e backup local criptografado.
2. Migrações avançadas, testes de repositório e testes de interface.
3. Sincronização opcional e criptografada via Supabase, sem remover o modo
   offline.
4. Web/PWA com uma estratégia de armazenamento compatível.

## Segurança e privacidade

Esta versão não possui login, pagamentos, analytics ou sincronização remota.
Dados financeiros são locais. Antes de produção, o roadmap prevê criptografia,
backup seguro, bloqueio biométrico e uma política de privacidade.

## Licença

Distribuído sob a licença MIT. Consulte [LICENSE](LICENSE).
