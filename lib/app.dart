import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite/sqflite.dart';

import 'core/constants/app_constants.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'core/update/update_prompt.dart';
import 'core/update/app_update.dart';
import 'core/update/update_service.dart';
import 'core/backup/local_backup_service.dart';
import 'core/premium/premium_entitlement.dart';
import 'core/security/biometric_service.dart';
import 'core/security/identity_check.dart';
import 'core/security/pin_service.dart';
import 'core/security/screen_privacy_service.dart';
import 'core/theme/app_colors.dart';
import 'core/sync/cloud_sync_service.dart';
import 'core/premium/premium_service.dart';
import 'core/update/push_notification_service.dart';
import 'features/dashboard/data/dashboard_repository.dart';
import 'features/accounts/data/account_repository.dart';
import 'features/categories/data/category_repository.dart';
import 'features/goals/data/goal_repository.dart';
import 'features/reports/data/report_repository.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/shell/presentation/main_shell.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/transactions/data/transaction_repository.dart';

class FluxoApp extends StatefulWidget {
  const FluxoApp({
    super.key,
    required this.database,
    required this.dashboardRepository,
    required this.transactionRepository,
    required this.updateService,
    required this.accountRepository,
    required this.categoryRepository,
    required this.goalRepository,
    required this.reportRepository,
    required this.cloudSyncService,
    required this.biometricService,
    required this.premiumService,
    required this.pinService,
    required this.localBackupService,
    required this.screenPrivacyService,
    required this.pushNotificationService,
  });

  final AppDatabase database;
  final DashboardRepository dashboardRepository;
  final TransactionRepository transactionRepository;
  final UpdateService updateService;
  final AccountRepository accountRepository;
  final CategoryRepository categoryRepository;
  final GoalRepository goalRepository;
  final ReportRepository reportRepository;
  final CloudSyncService cloudSyncService;
  final BiometricService biometricService;
  final PremiumService premiumService;
  final PinService pinService;
  final LocalBackupService localBackupService;
  final ScreenPrivacyService screenPrivacyService;
  final PushNotificationService pushNotificationService;

  @override
  State<FluxoApp> createState() => _FluxoAppState();
}

class _FluxoAppState extends State<FluxoApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool? _onboardingComplete;
  bool _updateChecked = false;
  DateTime? _lastUpdateCheck;
  AppUpdate? _availableUpdate;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _unlocked = true;

  bool get _lockEnabled => _biometricEnabled || _pinEnabled;

  late final IdentityCheck _identityCheck = IdentityCheck(
    pinService: widget.pinService,
    biometricService: widget.biometricService,
    biometricEnabled: () => _biometricEnabled,
  );

  StreamSubscription<void>? _pushTapSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.screenPrivacyService.apply());
    unawaited(widget.pushNotificationService.initialize());
    _pushTapSubscription = widget.pushNotificationService.onUpdateTapped
        .listen((_) => _handleUpdateNotificationTapped());
    _loadStartupState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lockEnabled &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden)) {
      setState(() => _unlocked = false);
    }
    if (state == AppLifecycleState.paused &&
        widget.cloudSyncService.currentUser != null) {
      unawaited(_syncSilently());
    }
    if (state == AppLifecycleState.resumed &&
        (_lastUpdateCheck == null ||
            DateTime.now().difference(_lastUpdateCheck!) >
                const Duration(minutes: 15))) {
      _updateChecked = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdates());
    }
    if (state == AppLifecycleState.resumed &&
        widget.cloudSyncService.currentUser != null) {
      unawaited(_syncSilently());
    }
  }

  Future<void> _loadStartupState() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final rows = await widget.database.db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['onboarding_complete'],
    );
    final themeRows = await widget.database.db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['theme'],
    );
    final biometricRows = await widget.database.db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['biometric_enabled'],
    );
    final biometricEnabled =
        biometricRows.isNotEmpty && biometricRows.first['value'] == 'true';
    final pinEnabled = await widget.pinService.isEnabled();
    if (mounted) {
      setState(
        () {
          _onboardingComplete =
              rows.isNotEmpty && rows.first['value'] == 'true';
          _themeMode =
              themeRows.isNotEmpty && themeRows.first['value'] == 'light'
                  ? ThemeMode.light
                  : ThemeMode.dark;
          _biometricEnabled = biometricEnabled;
          _pinEnabled = pinEnabled;
          _unlocked = !_lockEnabled;
        },
      );
      if (biometricEnabled) await _unlock();
      if (widget.cloudSyncService.currentUser != null) {
        unawaited(_syncSilently());
      }
    }
  }

  Future<void> _completeOnboarding() async {
    await widget.database.db.insert(
      'settings',
      {'key': 'onboarding_complete', 'value': 'true'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (mounted) setState(() => _onboardingComplete = true);
  }

  /// Sincronização automática: nunca resolve conflitos sozinha (o usuário
  /// decide em Configurações) e só roda quando o backup na nuvem está liberado.
  Future<void> _syncSilently() async {
    try {
      final entitlement = await widget.premiumService.load();
      if (!entitlement.allows(PremiumFeature.cloudBackup)) return;
      await widget.cloudSyncService.synchronize();
    } catch (error) {
      debugPrint('Sincronização adiada: $error');
    }
  }

  Future<void> _checkForUpdates() async {
    if (_updateChecked || !widget.updateService.isConfigured) return;
    _updateChecked = true;
    _lastUpdateCheck = DateTime.now();
    try {
      final update = await widget.updateService.check();
      if (mounted) setState(() => _availableUpdate = update);
    } catch (error) {
      debugPrint('Falha ao verificar atualizações: $error');
      // Atualizações nunca impedem o uso offline do aplicativo.
    }
  }

  Future<void> _changeTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await widget.database.db.insert(
      'settings',
      {'key': 'theme', 'value': mode == ThemeMode.light ? 'light' : 'dark'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> _unlock() async {
    final success = await widget.biometricService.authenticate();
    if (mounted && success) setState(() => _unlocked = true);
    return success;
  }

  Future<bool> _unlockWithPin(String pin) async {
    final success = await widget.pinService.verify(pin);
    if (mounted && success) setState(() => _unlocked = true);
    return success;
  }

  Future<void> _reloadLockSettings() async {
    final pinEnabled = await widget.pinService.isEnabled();
    if (mounted) setState(() => _pinEnabled = pinEnabled);
  }

  Future<bool> _changeBiometric(bool enabled) async {
    // Ligar ou desligar exige a biometria: ninguém desativa o bloqueio
    // com o aparelho de outra pessoa na mão.
    if (!await widget.biometricService.authenticate()) return false;
    await widget.database.db.insert(
      'settings',
      {'key': 'biometric_enabled', 'value': enabled ? 'true' : 'false'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (mounted) setState(() => _biometricEnabled = enabled);
    return true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_pushTapSubscription?.cancel());
    unawaited(widget.pushNotificationService.dispose());
    widget.database.close();
    widget.updateService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == true && _unlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdates());
    }
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: switch (_onboardingComplete) {
        null => const SplashScreen(),
        false => OnboardingScreen(onComplete: _completeOnboarding),
        true when !_unlocked => _LockScreen(
            biometricEnabled: _biometricEnabled,
            pinEnabled: _pinEnabled,
            onBiometric: _unlock,
            onPin: _unlockWithPin,
            pinService: widget.pinService,
          ),
        true => MainShell(
            dashboardRepository: widget.dashboardRepository,
            transactionRepository: widget.transactionRepository,
            themeMode: _themeMode,
            onThemeChanged: _changeTheme,
            accountRepository: widget.accountRepository,
            categoryRepository: widget.categoryRepository,
            goalRepository: widget.goalRepository,
            reportRepository: widget.reportRepository,
            cloudSyncService: widget.cloudSyncService,
            biometricEnabled: _biometricEnabled,
            onBiometricChanged: _changeBiometric,
            updateService: widget.updateService,
            availableUpdate: _availableUpdate,
            onOpenUpdate: _openAvailableUpdate,
            premiumService: widget.premiumService,
            pinService: widget.pinService,
            onLockSettingsChanged: _reloadLockSettings,
            localBackupService: widget.localBackupService,
            database: widget.database,
            identityCheck: _identityCheck,
            screenPrivacyService: widget.screenPrivacyService,
          ),
      },
    );
  }

  /// Tocou numa notificação de "chegou atualização": consulta de novo
  /// (ignorando o intervalo normal de 15 minutos) e já abre a tela.
  Future<void> _handleUpdateNotificationTapped() async {
    _updateChecked = false;
    await _checkForUpdates();
    await _openAvailableUpdate();
  }

  Future<void> _openAvailableUpdate() async {
    final update = _availableUpdate;
    final context = _navigatorKey.currentContext;
    if (update == null || context == null || !context.mounted) return;
    await showUpdatePrompt(
      context,
      update: update,
      service: widget.updateService,
    );
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen({
    required this.biometricEnabled,
    required this.pinEnabled,
    required this.onBiometric,
    required this.onPin,
    required this.pinService,
  });

  final bool biometricEnabled;
  final bool pinEnabled;
  final Future<bool> Function() onBiometric;
  final Future<bool> Function(String) onPin;
  final PinService pinService;

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  final _pin = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    widget.pinService.loadLockout().then((_) {
      final blocked = widget.pinService.blockedFor;
      if (mounted && blocked != null) {
        setState(() => _error = _waitMessage(blocked));
      }
    });
  }

  static String _waitMessage(Duration wait) => wait.inMinutes >= 1
      ? 'Muitas tentativas. Aguarde ${wait.inMinutes + 1} min.'
      : 'Muitas tentativas. Aguarde ${wait.inSeconds + 1} segundos.';

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    if (_checking || _pin.text.isEmpty) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final success = await widget.onPin(_pin.text);
    if (!mounted || success) return;
    final blocked = widget.pinService.blockedFor;
    setState(() {
      _checking = false;
      _pin.clear();
      _error = blocked == null ? 'PIN incorreto.' : _waitMessage(blocked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 34,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Fluxo+ bloqueado',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.pinEnabled
                        ? 'Digite seu PIN para continuar.'
                        : 'Use sua biometria para continuar.',
                    style: TextStyle(color: colors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  if (widget.pinEnabled) ...[
                    TextField(
                      controller: _pin,
                      autofocus: true,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: PinService.maxLength,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'PIN',
                        errorText: _error,
                      ),
                      onSubmitted: (_) => _submitPin(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _checking ? null : _submitPin,
                        child: const Text('Desbloquear'),
                      ),
                    ),
                  ],
                  if (widget.biometricEnabled) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: widget.pinEnabled
                          ? OutlinedButton.icon(
                              onPressed: widget.onBiometric,
                              icon: const Icon(Icons.fingerprint_rounded),
                              label: const Text('Usar biometria'),
                            )
                          : FilledButton.icon(
                              onPressed: widget.onBiometric,
                              icon: const Icon(Icons.fingerprint_rounded),
                              label: const Text('Desbloquear'),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
