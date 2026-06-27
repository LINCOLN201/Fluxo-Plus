import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF050807),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SplashMark(),
            SizedBox(height: 20),
            Text(
              'Fluxo+',
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Seu dinheiro. Seu controle.',
              style: TextStyle(color: Color(0xFFB7C2BD), fontSize: 16),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 34,
              child: LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: Color(0xFF1A2420),
                borderRadius: BorderRadius.all(Radius.circular(8)),
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
        color: const Color(0xFF0D1712),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1F3D2D)),
        boxShadow: const [
          BoxShadow(color: Color(0x440F9D58), blurRadius: 30),
        ],
      ),
      child: const Icon(
        Icons.show_chart_rounded,
        size: 45,
        color: AppColors.primary,
      ),
    );
  }
}
