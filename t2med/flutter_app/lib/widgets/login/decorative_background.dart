import 'package:flutter/material.dart';

/// Widget reutilizable: fondo limpio sin íconos flotantes.
/// Fondo sólido suave para pantallas de autenticación.
class DecorativeBackground extends StatelessWidget {
  final Color backgroundColor;

  const DecorativeBackground({
    super.key,
    this.backgroundColor = const Color(0xFFEAEFF5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
    );
  }
}
