enum PremiumPlan { free, premium, lifetime }

enum PremiumFeature {
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
    if (plan == PremiumPlan.lifetime && status == 'active') return true;
    if (status != 'active' && status != 'trialing') return false;
    final limit = status == 'trialing' ? trialEndsAt : currentPeriodEnd;
    return limit == null || limit.isAfter(DateTime.now());
  }

  bool canUse(PremiumFeature feature) => isActive;

  String get label => switch (plan) {
        PremiumPlan.free => 'Gratuito',
        PremiumPlan.premium =>
          status == 'trialing' ? 'Premium em teste' : 'Premium',
        PremiumPlan.lifetime => 'Premium vitalício',
      };
}
