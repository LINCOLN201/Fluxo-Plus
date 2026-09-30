import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Título + subtítulo de uma seção de tela, no mesmo padrão usado em
/// Relatórios, "Mais" e Configurações — pra toda tela de lista agrupada
/// usar a mesma hierarquia visual em vez de cada uma inventar a sua.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: TextStyle(color: context.colors.textMuted)),
        ],
      ],
    );
  }
}
