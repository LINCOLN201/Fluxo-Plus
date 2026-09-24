abstract final class AppConstants {
  static const appName = 'Fluxo+';
  static const appVersion = '0.6.0';
  static const databaseName = 'fluxo_plus.db';
  static const databaseVersion = 3;

  /// Enquanto as assinaturas não estiverem abertas, os recursos Premium ficam
  /// liberados para todos (ver docs/MONETIZATION.md). Ligar somente depois da
  /// integração com o provedor de pagamentos.
  static const premiumEnforced = false;

  static const siteUrl = 'https://lincoln201.github.io/Fluxo-Plus/';
}
