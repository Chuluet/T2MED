import 'package:flutter/material.dart';

/// Widget reutilizable: encabezado con logo e ícono de la app T2MED.
class AppLogoHeader extends StatelessWidget {
  final String appName;
  final double avatarRadius;

  const AppLogoHeader({
    super.key,
    this.appName = 'T2MED',
    this.avatarRadius = 70,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medication_outlined, color: Color(0xFF1E88E5), size: 28),
            const SizedBox(width: 10),
            Text(
              appName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF1E88E5), size: 28),
          ],
        ),
        const SizedBox(height: 32),
        // Avatar circular con ícono de usuario (más grande)
        Container(
          width: avatarRadius * 2,
          height: avatarRadius * 2,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFD6E8FB),
          ),
          child: Icon(
            Icons.person_outline_rounded,
            size: avatarRadius * 0.9,
            color: const Color(0xFF1E88E5),
          ),
        ),
      ],
    );
  }
}
