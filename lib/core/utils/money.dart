/// Valores monetários são gravados em centavos inteiros para que somas no
/// SQLite nunca acumulem erro de ponto flutuante. As telas continuam usando
/// `double` em reais; a conversão acontece só na fronteira com o banco.
abstract final class Money {
  static int toCents(num value) => (value * 100).round();

  static double fromCents(Object? cents) => ((cents as num?) ?? 0) / 100;
}
