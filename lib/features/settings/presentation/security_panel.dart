import 'package:flutter/material.dart';

import '../../../core/security/identity_check.dart';
import '../../../core/security/pin_service.dart';
import '../../../core/security/screen_privacy_service.dart';

class SecurityPanel extends StatefulWidget {
  const SecurityPanel({
    super.key,
    required this.pinService,
    required this.biometricEnabled,
    required this.onBiometricChanged,
    required this.onChanged,
    required this.screenPrivacyService,
    required this.identityCheck,
  });

  final PinService pinService;
  final ScreenPrivacyService screenPrivacyService;
  final IdentityCheck identityCheck;
  final bool biometricEnabled;
  final Future<bool> Function(bool) onBiometricChanged;
  final VoidCallback onChanged;

  @override
  State<SecurityPanel> createState() => _SecurityPanelState();
}

class _SecurityPanelState extends State<SecurityPanel> {
  bool? _pinEnabled;
  bool? _secureScreen;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await widget.pinService.isEnabled();
    final secureScreen = await widget.screenPrivacyService.isEnabled();
    if (mounted) {
      setState(() {
        _pinEnabled = enabled;
        _secureScreen = secureScreen;
      });
    }
  }

  Future<void> _toggleSecureScreen(bool enable) async {
    if (!enable &&
        !await widget.identityCheck.confirm(
          context,
          reason: 'Confirme para permitir capturas de tela.',
        )) {
      return;
    }
    await widget.screenPrivacyService.setEnabled(enable);
    if (mounted) setState(() => _secureScreen = enable);
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  /// Pede o PIN duas vezes; devolve o PIN confirmado ou `null`.
  Future<String?> _askNewPin() async {
    final first = TextEditingController();
    final second = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir PIN'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Use de 4 a 8 números. Ele será pedido ao abrir o Fluxo+.',
              ),
              const SizedBox(height: 16),
              _pinField(first, 'Novo PIN', autofocus: true),
              const SizedBox(height: 12),
              _pinField(
                second,
                'Repita o PIN',
                validator: (value) =>
                    value == first.text ? null : 'Os PINs não coincidem',
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
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    return ok == true ? first.text : null;
  }

  Future<bool> _confirmCurrentPin() async {
    final pin = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirme o PIN atual'),
        content: _pinField(pin, 'PIN atual', autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    final valid = await widget.pinService.verify(pin.text);
    if (!valid && mounted) _message('PIN incorreto.');
    return valid;
  }

  Widget _pinField(
    TextEditingController controller,
    String label, {
    bool autofocus = false,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        autofocus: autofocus,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: PinService.maxLength,
        decoration: InputDecoration(labelText: label, counterText: ''),
        validator: (value) => !PinService.isValid(value ?? '')
            ? 'Use de 4 a 8 números'
            : validator?.call(value),
      );

  Future<void> _togglePin(bool enable) async {
    if (enable) {
      final pin = await _askNewPin();
      if (pin == null) return;
      await widget.pinService.setPin(pin);
      if (mounted) _message('PIN ativado.');
    } else {
      if (!await _confirmCurrentPin()) return;
      await widget.pinService.clear();
      if (mounted) _message('PIN desativado.');
    }
    await _load();
    widget.onChanged();
  }

  Future<void> _changePin() async {
    if (!await _confirmCurrentPin()) return;
    final pin = await _askNewPin();
    if (pin == null) return;
    await widget.pinService.setPin(pin);
    if (mounted) _message('PIN alterado.');
  }

  @override
  Widget build(BuildContext context) {
    final pinEnabled = _pinEnabled ?? false;
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            value: pinEnabled,
            secondary: const Icon(Icons.pin_outlined),
            title: const Text('Bloqueio por PIN'),
            subtitle: const Text(
              'Funciona em qualquer aparelho, com ou sem biometria.',
            ),
            onChanged: _pinEnabled == null ? null : _togglePin,
          ),
          if (pinEnabled)
            ListTile(
              leading: const SizedBox(width: 24),
              title: const Text('Alterar PIN'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _changePin,
            ),
          const Divider(height: 1),
          SwitchListTile(
            value: widget.biometricEnabled,
            secondary: const Icon(Icons.fingerprint_rounded),
            title: const Text('Bloqueio biométrico'),
            subtitle: Text(
              pinEnabled
                  ? 'Use a biometria como atalho; o PIN continua valendo.'
                  : 'Solicitar biometria ao abrir o aplicativo.',
            ),
            onChanged: (value) async {
              final changed = await widget.onBiometricChanged(value);
              if (!changed && context.mounted) {
                _message('Biometria indisponível ou autenticação cancelada.');
              }
            },
          ),
          if (widget.screenPrivacyService.isSupported) ...[
            const Divider(height: 1),
            SwitchListTile(
              value: _secureScreen ?? true,
              secondary: const Icon(Icons.visibility_off_outlined),
              title: const Text('Ocultar em capturas de tela'),
              subtitle: const Text(
                'Esconde seus valores em prints, gravações e na lista de '
                'apps recentes.',
              ),
              onChanged: _secureScreen == null ? null : _toggleSecureScreen,
            ),
          ],
        ],
      ),
    );
  }
}
