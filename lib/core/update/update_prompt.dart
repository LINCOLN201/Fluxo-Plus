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
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !update.mandatory && !_downloading,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF07120D), Color(0xFF0B6B3A)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .18),
                          ),
                        ),
                        child: const Icon(
                          Icons.system_update_alt_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fluxo+ ${update.version}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Nova versão disponível',
                        style: TextStyle(color: Color(0xFFC8EED8)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: colors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Atualização segura e assinada',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        update.notes.trim().isEmpty
                            ? 'Melhorias de estabilidade, segurança e novos '
                                'recursos estão prontas para instalar.'
                            : update.notes.trim(),
                        maxLines: 7,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_downloading) ...[
                        const SizedBox(height: 22),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 9,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Baixando atualização…'),
                            Text(
                              '${((_progress ?? 0) * 100).round()}%',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ],
                      if (_message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _message!,
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _downloading ? null : _install,
                          icon: _downloading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_done_rounded),
                          label: Text(
                            _downloading ? 'Preparando' : 'Atualizar agora',
                          ),
                        ),
                      ),
                      if (!update.mandatory && !_downloading)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Lembrar mais tarde'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
