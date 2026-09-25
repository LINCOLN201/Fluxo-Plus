import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/backup/local_backup_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/security/identity_check.dart';
import '../../../core/theme/app_colors.dart';

/// Backup local criptografado — recurso gratuito.
class LocalBackupPanel extends StatefulWidget {
  const LocalBackupPanel({
    super.key,
    required this.service,
    required this.database,
    required this.onDataChanged,
    required this.identityCheck,
  });

  final LocalBackupService service;
  final IdentityCheck identityCheck;
  final AppDatabase database;
  final VoidCallback onDataChanged;

  @override
  State<LocalBackupPanel> createState() => _LocalBackupPanelState();
}

class _LocalBackupPanelState extends State<LocalBackupPanel> {
  bool _busy = false;
  late Future<DateTime?> _safetyCopy;

  @override
  void initState() {
    super.initState();
    _safetyCopy = widget.database.safetyCopyDate();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _busyWhile(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) _message('Não foi possível concluir: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _safetyCopy = widget.database.safetyCopyDate();
        });
      }
    }
  }

  Future<String?> _askPassword({required bool confirm}) async {
    final password = TextEditingController();
    final repeat = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(confirm ? 'Senha do backup' : 'Abrir backup'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                confirm
                    ? 'O arquivo será protegido com esta senha. Prefira uma '
                        'frase do que uma palavra só (ex.: "sol quente de '
                        'domingo"). Guarde-a bem: sem ela não é possível '
                        'recuperar o backup.'
                    : 'Digite a senha usada ao gerar o backup.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: password,
                autofocus: true,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
                validator: (value) =>
                    (value?.length ?? 0) < LocalBackupService.minPasswordLength
                        ? 'Use pelo menos '
                            '${LocalBackupService.minPasswordLength} caracteres'
                        : null,
              ),
              if (confirm) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: repeat,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Repita a senha'),
                  validator: (value) =>
                      value == password.text ? null : 'As senhas não coincidem',
                ),
              ],
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
            child: Text(confirm ? 'Gerar backup' : 'Continuar'),
          ),
        ],
      ),
    );
    return ok == true ? password.text : null;
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ==
      true;

  Future<bool> _confirmIdentity(String reason) =>
      widget.identityCheck.confirm(context, reason: reason);

  Future<void> _export() async {
    if (!await _confirmIdentity('Confirme para exportar seus dados.')) return;
    if (!mounted) return;
    final password = await _askPassword(confirm: true);
    if (password == null || !mounted) return;
    await _busyWhile(() async {
      final bytes = await widget.service.export(password);
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Salvar backup do Fluxo+',
        fileName: widget.service.suggestedFileName(),
        bytes: bytes,
      );
      if (saved != null && mounted) _message('Backup salvo.');
    });
  }

  Future<void> _import() async {
    if (!await _confirmIdentity('Confirme para substituir seus dados.')) {
      return;
    }
    final file = await FilePicker.pickFile(dialogTitle: 'Escolha o backup');
    if (file == null || !mounted) return;
    final proceed = await _confirm(
      'Importar backup?',
      'Os dados deste aparelho serão substituídos pelos do arquivo. Uma cópia '
          'dos dados atuais é guardada para você poder desfazer.',
      'Importar',
    );
    if (!proceed || !mounted) return;
    final password = await _askPassword(confirm: false);
    if (password == null || !mounted) return;
    await _busyWhile(() async {
      await widget.service.import(await file.readAsBytes(), password);
      widget.onDataChanged();
      if (mounted) _message('Backup importado.');
    });
  }

  Future<void> _undo(DateTime date) async {
    final proceed = await _confirm(
      'Desfazer última restauração?',
      'Os dados voltam a ser os que existiam em '
          '${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(date)}, antes da '
          'restauração.',
      'Desfazer',
    );
    if (!proceed || !mounted) return;
    if (!await _confirmIdentity('Confirme para desfazer a restauração.')) {
      return;
    }
    await _busyWhile(() async {
      await widget.database.restoreSafetyCopy();
      widget.onDataChanged();
      if (mounted) _message('Restauração desfeita.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.enhanced_encryption_outlined,
                color: context.colors.primary,
              ),
              title: const Text('Backup local criptografado'),
              subtitle: const Text(
                'Gere um arquivo protegido por senha e guarde onde preferir. '
                'Gratuito.',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _export,
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Exportar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _import,
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Importar'),
                  ),
                ),
              ],
            ),
            FutureBuilder<DateTime?>(
              future: _safetyCopy,
              builder: (context, snapshot) {
                final date = snapshot.data;
                if (date == null) return const SizedBox.shrink();
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: _busy ? null : () => _undo(date),
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Desfazer última restauração'),
                    ),
                  ),
                );
              },
            ),
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
