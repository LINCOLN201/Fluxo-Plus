import 'package:flutter/material.dart';

import 'app_update.dart';
import 'update_service.dart';

Future<void> showUpdatePrompt(
  BuildContext context, {
  required AppUpdate update,
  required UpdateService service,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !update.mandatory,
    builder: (context) => _UpdateDialog(update: update, service: service),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.update, required this.service});

  final AppUpdate update;
  final UpdateService service;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double? _progress;
  String? _message;

  Future<void> _install() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _message = null;
    });
    try {
      final result = await widget.service.downloadAndInstall(
        widget.update,
        onProgress: (value) {
          if (mounted) setState(() => _progress = value);
        },
      );
      if (!mounted) return;
      switch (result) {
        case InstallResult.permissionRequired:
          setState(() {
            _downloading = false;
            _message =
                'Autorize o Fluxo+ a instalar aplicativos e toque novamente '
                'em Instalar.';
          });
          break;
        case InstallResult.failed:
          setState(() {
            _downloading = false;
            _message = 'Não foi possível iniciar a instalação.';
          });
          break;
        case InstallResult.externalDownload:
        case InstallResult.installerStarted:
          if (!widget.update.mandatory) Navigator.pop(context);
          break;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _message =
            'Falha ao atualizar. Verifique sua conexão e tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = widget.update;
    return PopScope(
      canPop: !update.mandatory && !_downloading,
      child: AlertDialog(
        icon: const Icon(Icons.system_update_rounded),
        title: Text('Fluxo+ ${update.version} disponível'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              update.notes.trim().isEmpty
                  ? 'Uma nova versão está pronta para instalar.'
                  : update.notes.trim(),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
            if (_downloading) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text('Baixando… ${((_progress ?? 0) * 100).round()}%'),
            ],
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          if (!update.mandatory && !_downloading)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Agora não'),
            ),
          FilledButton.icon(
            onPressed: _downloading ? null : _install,
            icon: _downloading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.install_mobile_rounded),
            label: Text(_downloading ? 'Baixando' : 'Instalar agora'),
          ),
        ],
      ),
    );
  }
}
