import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/sync/cloud_sync_service.dart';
import '../../../core/update/update_prompt.dart';
import '../../../core/update/update_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.cloudSyncService,
    required this.biometricEnabled,
    required this.onBiometricChanged,
    required this.updateService,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final CloudSyncService cloudSyncService;
  final bool biometricEnabled;
  final Future<bool> Function(bool) onBiometricChanged;
  final UpdateService updateService;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Aparência',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tema do aplicativo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'O Fluxo+ usa o modo escuro por padrão.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Escuro'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Claro'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (value) => onThemeChanged(value.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Atualizações',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _UpdatePanel(service: updateService),
          const SizedBox(height: 24),
          Text(
            'Segurança',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              value: biometricEnabled,
              secondary: const Icon(Icons.fingerprint_rounded),
              title: const Text('Bloqueio biométrico'),
              subtitle: const Text(
                'Solicitar biometria ao abrir o aplicativo.',
              ),
              onChanged: (value) async {
                final changed = await onBiometricChanged(value);
                if (!changed && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Biometria indisponível ou autenticação cancelada.',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sincronização e backup',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _CloudSyncPanel(service: cloudSyncService),
          const SizedBox(height: 24),
          Text(
            'Privacidade e dados',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Dados locais'),
                  subtitle: const Text(
                    'Suas informações permanecem neste dispositivo.',
                  ),
                  trailing: const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.cloud_done_outlined),
                  title: Text('Offline-first'),
                  subtitle: Text(
                    'A nuvem é opcional; o SQLite continua funcionando offline.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Fluxo+',
                applicationVersion: '0.1.0',
                applicationLegalese: '© 2026 Fluxo+ contributors\nLicença MIT',
                children: const [
                  SizedBox(height: 12),
                  Text(
                    'Finanças pessoais offline-first, seguras e open source.',
                  ),
                ],
              ),
              leading: Icon(
                dark ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Fluxo+'),
              subtitle: const Text('Open source • Licença MIT'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatePanel extends StatefulWidget {
  const _UpdatePanel({required this.service});

  final UpdateService service;

  @override
  State<_UpdatePanel> createState() => _UpdatePanelState();
}

class _UpdatePanelState extends State<_UpdatePanel> {
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final update = await widget.service.check();
      if (!mounted) return;
      if (update == null) {
        final version = await widget.service.currentVersion();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Você já está na versão mais recente: $version')),
        );
      } else {
        await showUpdatePrompt(
          context,
          update: update,
          service: widget.service,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao verificar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FutureBuilder<String>(
        future: widget.service.currentVersion(),
        builder: (context, snapshot) => ListTile(
          leading: const Icon(Icons.system_update_rounded),
          title: const Text('Atualização pela internet'),
          subtitle: Text(
            snapshot.hasData
                ? 'Versão instalada: ${snapshot.data}'
                : 'Consultando versão instalada…',
          ),
          trailing: FilledButton(
            onPressed: _checking ? null : _check,
            child: _checking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verificar'),
          ),
        ),
      ),
    );
  }
}

class _CloudSyncPanel extends StatefulWidget {
  const _CloudSyncPanel({required this.service});

  final CloudSyncService service;

  @override
  State<_CloudSyncPanel> createState() => _CloudSyncPanelState();
}

class _CloudSyncPanelState extends State<_CloudSyncPanel> {
  bool _busy = false;

  Future<void> _authenticate() async {
    final email = TextEditingController();
    final password = TextEditingController();
    var createAccount = false;
    final key = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(createAccount ? 'Criar conta' : 'Entrar no Fluxo+'),
          content: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (value) => value != null && value.contains('@')
                      ? null
                      : 'Informe um e-mail válido',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  validator: (value) => (value?.length ?? 0) < 6
                      ? 'Use pelo menos 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      setDialogState(() => createAccount = !createAccount),
                  child: Text(
                    createAccount ? 'Já tenho uma conta' : 'Criar uma conta',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(context, true);
              },
              child: Text(createAccount ? 'Criar' : 'Entrar'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      if (createAccount) {
        await widget.service.signUp(email.text.trim(), password.text);
      } else {
        await widget.service.signIn(email.text.trim(), password.text);
      }
    },
        createAccount
            ? 'Conta criada. Confirme o e-mail, se solicitado.'
            : 'Conectado.');
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível concluir: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.service.isConfigured) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.cloud_off_outlined),
          title: Text('Supabase não configurado'),
          subtitle: Text(
            'Compile com SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY.',
          ),
        ),
      );
    }
    final user = widget.service.currentUser;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                user == null ? Icons.cloud_off_outlined : Icons.cloud_done,
                color: user == null ? null : AppColors.primary,
              ),
              title: Text(user?.email ?? 'Conecte sua conta'),
              subtitle: Text(
                user == null
                    ? 'Entre para sincronizar seus dispositivos.'
                    : 'Backup protegido pela sua conta.',
              ),
              trailing: user == null
                  ? FilledButton(
                      onPressed: _busy ? null : _authenticate,
                      child: const Text('Entrar'),
                    )
                  : TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              widget.service.signOut, 'Conta desconectada.'),
                      child: const Text('Sair'),
                    ),
            ),
            if (user != null) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                await widget.service.uploadBackup();
                              }, 'Backup enviado para a nuvem.'),
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Enviar backup'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                await widget.service.restoreBackup();
                              }, 'Backup restaurado. Reinicie para atualizar tudo.'),
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: const Text('Restaurar'),
                    ),
                  ),
                ],
              ),
            ],
            if (_busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
