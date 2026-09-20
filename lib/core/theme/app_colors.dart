import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.textMutedDim,
    required this.primary,
    required this.onPrimary,
    required this.income,
    required this.expense,
    required this.warning,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color textMutedDim;
  final Color primary;
  final Color onPrimary;
  final Color income;
  final Color expense;
  final Color warning;

  static const dark = AppColors(
    background: Color(0xFF0A0A0B),
    surface: Color(0xFF151516),
    surfaceElevated: Color(0xFF1A1A1C),
    border: Color(0xFF262628),
    textPrimary: Color(0xFFF2F2F0),
    textMuted: Color(0xFF8A8A8E),
    textMutedDim: Color(0xFF6E6E72),
    primary: Color(0xFFC6FF5E),
    onPrimary: Color(0xFF0A0A0B),
    income: Color(0xFFC6FF5E),
    expense: Color(0xFFFF5C5C),
    warning: Color(0xFFF2B84B),
  );

  static const light = AppColors(
    background: Color(0xFFF5F5F3),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF0F0EE),
    border: Color(0xFFE4E4E1),
    textPrimary: Color(0xFF1A1A1B),
    textMuted: Color(0xFF6E6E72),
    textMutedDim: Color(0xFF9A9A96),
    primary: Color(0xFF4A7010),
    onPrimary: Color(0xFFFFFFFF),
    income: Color(0xFF4A7010),
    expense: Color(0xFFC22B2B),
    warning: Color(0xFF8A5A00),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? textPrimary,
    Color? textMuted,
    Color? textMutedDim,
    Color? primary,
    Color? onPrimary,
    Color? income,
    Color? expense,
    Color? warning,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textMutedDim: textMutedDim ?? this.textMutedDim,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textMutedDim: Color.lerp(textMutedDim, other.textMutedDim, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
