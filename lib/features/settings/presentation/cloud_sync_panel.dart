import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/security/identity_check.dart';
import '../../../core/sync/cloud_sync_service.dart';
import '../../../core/theme/app_colors.dart';

class CloudSyncPanel extends StatefulWidget {
  const CloudSyncPanel({
    super.key,
    required this.service,
    required this.onDataChanged,
    required this.allowed,
    required this.onOpenPremium,
    required this.identityCheck,
  });

  final CloudSyncService service;
  final IdentityCheck identityCheck;
  final VoidCallback onDataChanged;

  /// Backup na nuvem liberado pelo plano (Premium).
  final bool allowed;
  final VoidCallback onOpenPremium;

  @override
  State<CloudSyncPanel> createState() => _CloudSyncPanelState();
}

class _CloudSyncPanelState extends State<CloudSyncPanel> {
  bool _busy = false;
  late Future<DateTime?> _lastSync;

  @override
  void initState() {
    super.initState();
    _lastSync = widget.service.lastSyncAt();
  }

  void _refreshLastSync() {
    if (mounted) setState(() => _lastSync = widget.service.lastSyncAt());
  }

  Future<void> _authenticate() async {
    final name = TextEditingController();
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
                if (createAccount) ...[
                  TextFormField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Como podemos chamar você?',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe seu nome'
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
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
    final accountEmail = email.text.trim();
    final succeeded = await _run(() async {
      if (createAccount) {
        await widget.service.signUp(
          accountEmail,
          password.text,
          name: name.text,
        );
      } else {
        await widget.service.signIn(accountEmail, password.text);
      }
    },
        createAccount
            ? 'Código de confirmação enviado por e-mail.'
            : 'Conectado.');
    if (createAccount && succeeded && mounted) {
      await _confirmEmailCode(accountEmail);
    } else if (succeeded && mounted) {
      await _synchronize();
    }
  }

  Future<void> _resendConfirmation() async {
    final email = TextEditingController();
    final key = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reenviar confirmação'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail da conta'),
            validator: (value) => value != null && value.contains('@')
                ? null
                : 'Informe um e-mail válido',
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
            child: const Text('Reenviar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final accountEmail = email.text.trim();
    final succeeded = await _run(
      () => widget.service.resendConfirmation(accountEmail),
      'Novo código enviado por e-mail.',
    );
    if (succeeded && mounted) await _confirmEmailCode(accountEmail);
  }

  Future<void> _confirmEmailCode(String email) async {
    final code = TextEditingController();
    final key = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar e-mail'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Digite o código de 8 dígitos enviado para $email.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: code,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'Código de confirmação',
                ),
                validator: (value) => (value?.trim().length ?? 0) == 8
                    ? null
                    : 'Informe os 8 dígitos',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Confirmar depois'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final succeeded = await _run(
      () => widget.service.verifyEmailCode(email, code.text),
      'E-mail confirmado. Conta conectada.',
    );
    if (succeeded && mounted) await _synchronize();
  }

  /// Sincroniza e, se aparelho e nuvem mudaram, pergunta qual lado manter.
  Future<void> _synchronize() async {
    if (!widget.allowed) return;
    SyncResult? result;
    await _run(() async {
      result = await widget.service.synchronize();
    }, 'Sincronização concluída.');
    final pending = result;
    if (pending == null || !mounted) return;
    if (pending.direction == SyncDirection.downloaded) widget.onDataChanged();
    if (pending.direction != SyncDirection.conflict) return;

    final choice = await showDialog<SyncResolution>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.compare_arrows_rounded),
        title: const Text('Dados diferentes encontrados'),
        content: Text(
          'Este aparelho e o backup na nuvem '
          '(salvo em ${_format(pending.at)}) têm alterações diferentes. '
          'Qual versão você quer manter?\n\n'
          'Se escolher a nuvem, uma cópia dos dados deste aparelho é '
          'guardada e pode ser recuperada em "Desfazer última restauração".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Decidir depois'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, SyncResolution.useCloud),
            child: const Text('Usar a nuvem'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, SyncResolution.keepLocal),
            child: const Text('Manter este aparelho'),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == SyncResolution.useCloud &&
        !await widget.identityCheck.confirm(
          context,
          reason: 'Confirme para substituir os dados deste aparelho.',
        )) {
      return;
    }
    final ok = await _run(
      () => widget.service.synchronize(resolution: choice),
      choice == SyncResolution.useCloud
          ? 'Backup da nuvem aplicado neste aparelho.'
          : 'Dados deste aparelho enviados para a nuvem.',
    );
    if (ok) widget.onDataChanged();
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar da nuvem?'),
        content: const Text(
          'Os dados deste aparelho serão substituídos pelo backup da nuvem. '
          'Uma cópia dos dados atuais é guardada para você poder desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!await widget.identityCheck.confirm(
      context,
      reason: 'Confirme para substituir os dados deste aparelho.',
    )) {
      return;
    }
    final ok = await _run(
      widget.service.restoreBackup,
      'Backup restaurado neste dispositivo.',
    );
    if (ok) widget.onDataChanged();
  }

  static String _format(DateTime value) =>
      DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(value.toLocal());

  Widget _locked(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
        leading: Icon(Icons.cloud_outlined, color: context.colors.primary),
        title: const Text('Backup na nuvem é Premium'),
        subtitle: const Text(
          'Guarde seus dados automaticamente e use o Fluxo+ em mais de um '
          'aparelho. O backup local continua gratuito.',
        ),
        trailing: TextButton(
          onPressed: widget.onOpenPremium,
          child: const Text('Conhecer'),
        ),
      ),
    );
  }

  Future<bool> _run(
    Future<void> Function() action,
    String success,
  ) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
        setState(() {});
        _refreshLastSync();
      }
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível concluir: $error')),
        );
      }
      return false;
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
    if (!widget.allowed) return _locked(context);
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
                color: user == null ? null : context.colors.primary,
              ),
              // E-mails longos não quebram no meio da palavra.
              title: Text(
                user?.email ?? 'Conecte sua conta',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                user == null
                    ? 'Entre para sincronizar seus dispositivos.'
                    : 'Seus aparelhos compartilham o mesmo backup.',
              ),
              trailing: user == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          onPressed: _busy ? null : _authenticate,
                          child: const Text('Entrar'),
                        ),
                      ],
                    )
                  : TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              widget.service.signOut, 'Conta desconectada.'),
                      child: const Text('Sair'),
                    ),
            ),
            if (user == null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _busy ? null : _resendConfirmation,
                  icon: const Icon(Icons.mark_email_unread_outlined),
                  label: const Text('Reenviar confirmação'),
                ),
              ),
            if (user != null) ...[
              const Divider(),
              FutureBuilder<DateTime?>(
                future: _lastSync,
                builder: (context, snapshot) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('Última sincronização'),
                  subtitle: Text(
                    snapshot.data == null
                        ? 'Ainda não sincronizado'
                        : _format(snapshot.data!),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _synchronize,
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Sincronizar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _restore,
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
