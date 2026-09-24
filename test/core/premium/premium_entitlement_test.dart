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

  test('plano premium ativo sem data de fim libera recursos', () {
    const entitlement = PremiumEntitlement(
      plan: PremiumPlan.premium,
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

  test('com a cobrança desligada, recursos premium ficam liberados', () {
    const entitlement = PremiumEntitlement.free();

    expect(
      entitlement.allows(PremiumFeature.cloudBackup, enforced: false),
      isTrue,
    );
    expect(
      entitlement.allows(PremiumFeature.cloudBackup, enforced: true),
      isFalse,
    );
    expect(
      const PremiumEntitlement(plan: PremiumPlan.premium, status: 'active')
          .allows(PremiumFeature.customColors, enforced: true),
      isTrue,
    );
  });
}
