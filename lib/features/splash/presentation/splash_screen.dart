import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_rounded,
                size: 72, color: Colors.white),
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
              style: TextStyle(color: Color(0xFFE0F5E9), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
