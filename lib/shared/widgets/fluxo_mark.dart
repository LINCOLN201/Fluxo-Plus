import 'package:flutter/material.dart';

/// A logo oficial do Fluxo+ (recortada de `assets/icon/fluxo_plus_monochrome.png`,
/// a mesma usada no ícone do app), tingida para funcionar nos dois temas.
class FluxoMark extends StatelessWidget {
  const FluxoMark({super.key, required this.size, this.color});

  final double size;

  /// Cor da marca; por padrão segue `context.colors.textPrimary`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/fluxo_mark.png',
      width: size,
      height: size,
      color: color,
      colorBlendMode: BlendMode.srcIn,
    );
  }
}
