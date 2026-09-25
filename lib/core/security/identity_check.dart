import 'package:flutter/material.dart';

import 'biometric_service.dart';
import 'pin_service.dart';

/// Confirma que quem está com o aparelho é o dono antes de ações sensíveis
/// (exportar ou restaurar dados, desligar proteções). Sem bloqueio
/// configurado, libera direto.
class IdentityCheck {
  IdentityCheck({
    required this.pinService,
    required this.biometricService,
    required this.biometricEnabled,
  });

  final PinService pinService;
  final BiometricService biometricService;
  final bool Function() biometricEnabled;

  Future<bool> confirm(BuildContext context, {required String reason}) async {
    final pinEnabled = await pinService.isEnabled();
    if (biometricEnabled() && await biometricService.authenticate()) {
      return true;
    }
    if (!pinEnabled) return !biometricEnabled();
    if (!context.mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (context) => _PinDialog(
            pinService: pinService,
            reason: reason,
          ),
        ) ==
        true;
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.pinService, required this.reason});

  final PinService pinService;
  final String reason;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pin = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_checking) return;
    setState(() => _checking = true);
    final ok = await widget.pinService.verify(_pin.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    final wait = widget.pinService.blockedFor;
    setState(() {
      _checking = false;
      _pin.clear();
      _error = wait == null
          ? 'PIN incorreto.'
          : 'Muitas tentativas. Tente novamente mais tarde.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock_outline_rounded),
      title: const Text('Confirme que é você'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.reason),
          const SizedBox(height: 16),
          TextField(
            controller: _pin,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: PinService.maxLength,
            decoration: InputDecoration(
              labelText: 'PIN',
              counterText: '',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _checking ? null : _submit,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
