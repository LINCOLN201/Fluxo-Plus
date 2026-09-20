import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/theme/app_colors.dart';

double _channelLuminance(double c) =>
    c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();

double _relativeLuminance(Color color) =>
    0.2126 * _channelLuminance(color.r) +
    0.7152 * _channelLuminance(color.g) +
    0.0722 * _channelLuminance(color.b);

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppColors.dark', () {
    test('token values', () {
      expect(AppColors.dark.background, const Color(0xFF0A0A0B));
      expect(AppColors.dark.surface, const Color(0xFF151516));
      expect(AppColors.dark.surfaceElevated, const Color(0xFF1A1A1C));
      expect(AppColors.dark.border, const Color(0xFF262628));
      expect(AppColors.dark.textPrimary, const Color(0xFFF2F2F0));
      expect(AppColors.dark.textMuted, const Color(0xFF8A8A8E));
      expect(AppColors.dark.textMutedDim, const Color(0xFF6E6E72));
      expect(AppColors.dark.primary, const Color(0xFFC6FF5E));
      expect(AppColors.dark.onPrimary, const Color(0xFF0A0A0B));
      expect(AppColors.dark.income, const Color(0xFFC6FF5E));
      expect(AppColors.dark.expense, const Color(0xFFFF5C5C));
      expect(AppColors.dark.warning, const Color(0xFFF2B84B));
    });

    test('textPrimary meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.dark.textPrimary, AppColors.dark.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('textMuted meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.dark.textMuted, AppColors.dark.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('expense meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.dark.expense, AppColors.dark.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('warning meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.dark.warning, AppColors.dark.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('onPrimary meets WCAG AA (4.5:1) on primary', () {
      expect(
        _contrastRatio(AppColors.dark.onPrimary, AppColors.dark.primary),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('AppColors.light', () {
    test('token values', () {
      expect(AppColors.light.background, const Color(0xFFF5F5F3));
      expect(AppColors.light.surface, const Color(0xFFFFFFFF));
      expect(AppColors.light.surfaceElevated, const Color(0xFFF0F0EE));
      expect(AppColors.light.border, const Color(0xFFE4E4E1));
      expect(AppColors.light.textPrimary, const Color(0xFF1A1A1B));
      expect(AppColors.light.textMuted, const Color(0xFF6E6E72));
      expect(AppColors.light.textMutedDim, const Color(0xFF9A9A96));
      expect(AppColors.light.primary, const Color(0xFF4A7010));
      expect(AppColors.light.onPrimary, const Color(0xFFFFFFFF));
      expect(AppColors.light.income, const Color(0xFF4A7010));
      expect(AppColors.light.expense, const Color(0xFFC22B2B));
      expect(AppColors.light.warning, const Color(0xFF8A5A00));
    });

    test('textPrimary meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(
            AppColors.light.textPrimary, AppColors.light.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('textMuted meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.light.textMuted, AppColors.light.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('primary meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.light.primary, AppColors.light.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('expense meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.light.expense, AppColors.light.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('warning meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.light.warning, AppColors.light.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('onPrimary meets WCAG AA (4.5:1) on primary', () {
      expect(
        _contrastRatio(AppColors.light.onPrimary, AppColors.light.primary),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  testWidgets('context.colors resolves the extension registered on the theme',
      (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.dark]),
      home: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox();
        },
      ),
    ));
    expect(capturedContext.colors, AppColors.dark);
  });
}
