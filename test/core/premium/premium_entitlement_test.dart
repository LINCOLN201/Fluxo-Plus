import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/premium/premium_entitlement.dart';

void main() {
  test('plano gratuito não libera recursos premium', () {
    const entitlement = PremiumEntitlement.free();

    expect(entitlement.isActive, isFalse);
    expect(
      entitlement.canUse(PremiumFeature.automaticBackup),
      isFalse,
    );
  });

  test('plano vitalício ativo não expira', () {
    const entitlement = PremiumEntitlement(
      plan: PremiumPlan.lifetime,
      status: 'active',
    );

    expect(entitlement.isActive, isTrue);
    expect(entitlement.canUse(PremiumFeature.advancedReports), isTrue);
  });

  test('período premium vencido fica inativo', () {
    final entitlement = PremiumEntitlement(
      plan: PremiumPlan.premium,
      status: 'active',
      currentPeriodEnd: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    expect(entitlement.isActive, isFalse);
  });
}
