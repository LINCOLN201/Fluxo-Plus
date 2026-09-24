import '../constants/app_constants.dart';

enum PremiumPlan { free, premium }

enum PremiumFeature {
  cloudBackup,
  automaticBackup,
  multiDeviceSync,
  backupHistory,
  recurringTransactions,
  creditCards,
  installments,
  categoryBudgets,
  advancedReports,
  pdfExport,
  excelExport,
  financialIntelligence,
  customColors,
}

class PremiumEntitlement {
  const PremiumEntitlement({
    required this.plan,
    this.status = 'inactive',
    this.currentPeriodEnd,
    this.trialEndsAt,
  });

  const PremiumEntitlement.free()
      : plan = PremiumPlan.free,
        status = 'inactive',
        currentPeriodEnd = null,
        trialEndsAt = null;

  final PremiumPlan plan;
  final String status;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEndsAt;

  bool get isActive {
    if (plan == PremiumPlan.free) return false;
    if (status != 'active' && status != 'trialing') return false;
    final limit = status == 'trialing' ? trialEndsAt : currentPeriodEnd;
    return limit == null || limit.isAfter(DateTime.now());
  }

  bool canUse(PremiumFeature feature) => isActive;

  /// Se o recurso pode ser usado agora. Com a cobrança desligada
  /// ([AppConstants.premiumEnforced]), tudo fica liberado.
  bool allows(
    PremiumFeature feature, {
    bool enforced = AppConstants.premiumEnforced,
  }) =>
      !enforced || canUse(feature);

  String get label => switch (plan) {
        PremiumPlan.free => 'Gratuito',
        PremiumPlan.premium =>
          status == 'trialing' ? 'Premium em teste' : 'Premium',
      };
}
