import 'package:flutter/material.dart';

/// Contenedor agrupado con borde azul que envuelve múltiples ProfileOptionTile.
/// Agrega divisores automáticos entre cada opción.
class ProfileSectionCard extends StatelessWidget {
  final List<Widget> children;

  const ProfileSectionCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final List<Widget> divided = [];
    for (int i = 0; i < children.length; i++) {
      divided.add(children[i]);
      if (i < children.length - 1) {
        divided.add(const Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: Color(0xFFEEF2F6),
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E88E5), width: 1.5),
      ),
      child: Column(children: divided),
    );
  }
}
