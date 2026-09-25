import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/fluxo_mark.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SplashMark(),
            const SizedBox(height: 20),
            Text(
              'Fluxo+',
              style: TextStyle(
                color: AppColors.dark.textPrimary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seu dinheiro. Seu controle.',
              style: TextStyle(color: AppColors.dark.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 34,
              child: LinearProgressIndicator(
                color: AppColors.dark.primary,
                backgroundColor: AppColors.dark.surfaceElevated,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.dark.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.dark.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.primary.withValues(alpha: .27),
            blurRadius: 30,
          ),
        ],
      ),
      child: FluxoMark(size: 50, color: AppColors.dark.textPrimary),
    );
  }
}
