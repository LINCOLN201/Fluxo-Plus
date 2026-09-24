/// Cores das categorias gravadas no banco. São valores fixos, independentes do
/// tema, escolhidos para funcionar sobre as superfícies clara e escura.
abstract final class CategoryPalette {
  /// Cores Grafite das categorias criadas no primeiro uso.
  static const defaults = {
    'Salário': 0xFF4A7010,
    'Freelance': 0xFF6B8F2A,
    'Outras receitas': 0xFF6E6E72,
    'Alimentação': 0xFFC22B2B,
    'Moradia': 0xFF8A5A00,
    'Transporte': 0xFF44616F,
    'Saúde': 0xFFB0413E,
    'Lazer': 0xFFB7791F,
    'Cartão de crédito': 0xFF5A5A60,
    'Internet': 0xFF3F6E7A,
    'Outras despesas': 0xFF6E6E72,
  };

  /// Cores gravadas pelas versões anteriores à 0.6.0. Só categorias padrão que
  /// ainda têm exatamente essa cor são migradas; escolhas do usuário ficam.
  static const legacyDefaults = {
    'Salário': 0xFF0F9D58,
    'Freelance': 0xFF0B6B3A,
    'Outras receitas': 0xFF64748B,
    'Alimentação': 0xFFE53935,
    'Moradia': 0xFF7C3AED,
    'Transporte': 0xFF0284C7,
    'Saúde': 0xFFDB2777,
    'Lazer': 0xFFF59E0B,
    'Cartão de crédito': 0xFF7C3AED,
    'Internet': 0xFF0284C7,
    'Outras despesas': 0xFF64748B,
  };

  /// Paleta exclusiva do Premium para personalizar categorias.
  static const premium = [
    0xFF7FB82E,
    0xFF2F9E6E,
    0xFF1F7A8C,
    0xFF3B6FD8,
    0xFF5B5BD6,
    0xFF8B5CF6,
    0xFFC2417A,
    0xFFC22B2B,
    0xFFD9661F,
    0xFFB7791F,
    0xFF8C7A5B,
    0xFF5A5A60,
  ];
}
