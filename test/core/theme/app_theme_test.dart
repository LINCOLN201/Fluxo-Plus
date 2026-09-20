import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/theme/app_colors.dart';
import 'package:fluxo_plus/core/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme.dark() registers AppColors.dark', (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox();
        },
      ),
    ));
    final theme = Theme.of(capturedContext);
    expect(theme.extension<AppColors>(), AppColors.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.dark.background);
  });

  testWidgets('AppTheme.light() registers AppColors.light', (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox();
        },
      ),
    ));
    final theme = Theme.of(capturedContext);
    expect(theme.extension<AppColors>(), AppColors.light);
    expect(theme.scaffoldBackgroundColor, AppColors.light.background);
  });
}
