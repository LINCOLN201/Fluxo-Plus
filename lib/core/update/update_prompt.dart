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
    builder: (context) => PopScope(
      canPop: !update.mandatory,
      child: AlertDialog(
        icon: const Icon(Icons.system_update_rounded),
        title: Text('Fluxo+ ${update.version} disponível'),
        content: Text(
          update.notes.trim().isEmpty
              ? 'Uma nova versão está pronta para instalar.'
              : update.notes.trim(),
          maxLines: 8,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!update.mandatory)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Agora não'),
            ),
          FilledButton.icon(
            onPressed: () async {
              await service.openDownload(update);
              if (context.mounted && !update.mandatory) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Baixar atualização'),
          ),
        ],
      ),
    ),
  );
}
