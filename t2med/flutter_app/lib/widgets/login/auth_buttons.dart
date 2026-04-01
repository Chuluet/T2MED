import 'package:flutter/material.dart';

/// Botón primario reutilizable con fondo sólido (ej: "INICIAR SESIÓN").
/// Se puede usar en cualquier pantalla del flujo de autenticación.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double verticalPadding;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF2196F3),
    this.textColor = Colors.white,
    this.borderRadius = 30,
    this.verticalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// Botón secundario reutilizable con borde (ej: "CREAR CUENTA").
/// Se puede usar en pantallas de autenticación y onboarding.
class OutlinedActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color borderColor;
  final Color textColor;
  final double borderRadius;
  final double verticalPadding;

  const OutlinedActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.borderColor = const Color(0xFF2196F3),
    this.textColor = const Color(0xFF2196F3),
    this.borderRadius = 30,
    this.verticalPadding = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          side: BorderSide(color: borderColor, width: 1.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// Botón de texto simple reutilizable (ej: "¿Olvidaste tu contraseña?").
class LinkTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;

  const LinkTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.textColor = const Color(0xFF2196F3),
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor,
        ),
      ),
    );
  }
}
