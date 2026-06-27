import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async =>
      await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;

  Future<bool> authenticate() async {
    if (!await isAvailable()) return false;
    return _auth.authenticate(
      localizedReason: 'Desbloqueie o Fluxo+ para acessar suas finanças',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
  }
}
