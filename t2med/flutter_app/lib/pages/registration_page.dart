import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/user_service.dart';

// Widgets reutilizables
import 'package:t2med/widgets/login/app_logo_header.dart';
import 'package:t2med/widgets/login/rounded_input_field.dart';
import 'package:t2med/widgets/login/auth_buttons.dart';
import 'package:t2med/widgets/login/decorative_background.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEFF5),
      body: Stack(
        children: [
          const DecorativeBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 36),

                  // Header reutilizable con subtítulo "Crear cuenta"
                  const _RegistrationHeader(),

                  const SizedBox(height: 32),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Nombre y Apellido en fila
                        Row(
                          children: [
                            Expanded(
                              child: RoundedInputField(
                                controller: _nameController,
                                hintText: 'Nombre',
                                prefixIcon: Icons.person_outline,
                                validator: (value) => (value == null || value.isEmpty)
                                    ? 'Obligatorio'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RoundedInputField(
                                controller: _lastNameController,
                                hintText: 'Apellido',
                                prefixIcon: Icons.person_outline,
                                validator: (value) => (value == null || value.isEmpty)
                                    ? 'Obligatorio'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        RoundedInputField(
                          controller: _emailController,
                          hintText: 'Correo electrónico',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            const pattern =
                                r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@'
                                r'((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|'
                                r'(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                            return RegExp(pattern).hasMatch(value ?? '')
                                ? null
                                : 'El formato del correo no es válido';
                          },
                        ),

                        const SizedBox(height: 12),

                        RoundedInputField(
                          controller: _phoneController,
                          hintText: 'Teléfono de contacto (+57...)',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            const pattern = r'^\+[1-9]\d{0,2}\d{10}$';
                            return RegExp(pattern).hasMatch(value ?? '')
                                ? null
                                : 'Número con prefijo internacional';
                          },
                        ),

                        const SizedBox(height: 12),

                        RoundedInputField(
                          controller: _emergencyPhoneController,
                          hintText: 'Tel. emergencia (opcional)',
                          prefixIcon: Icons.phone_in_talk_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            const pattern = r'^\+[1-9]\d{0,2}\d{10}$';
                            return RegExp(pattern).hasMatch(value)
                                ? null
                                : 'Número con prefijo internacional';
                          },
                        ),

                        const SizedBox(height: 12),

                        RoundedInputField(
                          controller: _passwordController,
                          hintText: 'Contraseña',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Mínimo 8 caracteres, una mayúscula y un número';
                            }
                            if (!value.contains(RegExp(r'[A-Z]'))) {
                              return 'Mínimo 8 caracteres, una mayúscula y un número';
                            }
                            if (!value.contains(RegExp(r'[0-9]'))) {
                              return 'Mínimo 8 caracteres, una mayúscula y un número';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        RoundedInputField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirmar contraseña',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) => (value != _passwordController.text)
                              ? 'Las contraseñas no coinciden'
                              : null,
                        ),

                        const SizedBox(height: 24),

                        PrimaryButton(
                          label: 'REGISTRARSE',
                          onPressed: _handleRegister,
                        ),

                        const SizedBox(height: 12),

                        // Enlace para volver al login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿Ya tienes cuenta? ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            LinkTextButton(
                              label: 'Iniciar sesión',
                              onPressed: () => Navigator.pop(context),
                              textColor: const Color(0xFF1E88E5),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, complete todos los campos correctamente')),
      );
      return;
    }

    final userService = context.read<UserService>();

    final Map<String, dynamic> userData = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
      'name': _nameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    if (_emergencyPhoneController.text.trim().isNotEmpty) {
      userData['emergencyPhone'] = _emergencyPhoneController.text.trim();
    }

    final String? errorMessage = await userService.createUser(userData);

    if (errorMessage == null) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('¡Registro exitoso! Por favor, inicia sesión.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }
}

/// Header específico de la pantalla de registro.
/// Reutiliza AppLogoHeader y añade el subtítulo "Crear cuenta".
class _RegistrationHeader extends StatelessWidget {
  const _RegistrationHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppLogoHeader(avatarRadius: 70),
        const SizedBox(height: 8),
        const Text(
          'Crear cuenta',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5A7A96),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
