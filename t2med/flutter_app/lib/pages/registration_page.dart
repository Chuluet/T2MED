import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/user_service.dart';
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
  final TextEditingController _emergencyPhoneController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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
                  const _RegistrationHeader(),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: RoundedInputField(
                                controller: _nameController,
                                hintText: 'Nombre',
                                prefixIcon: Icons.person_outline,
                                // Solo valida que no esté vacío — el formato
                                // lo valida NestJS y devuelve el mensaje
                                validator: (value) =>
                                    (value == null || value.isEmpty)
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
                                validator: (value) =>
                                    (value == null || value.isEmpty)
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
                            if (value == null || value.isEmpty) {
                              return 'El correo es obligatorio';
                            }
                            if (!value.contains('@')) {
                              return 'Ingrese un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        RoundedInputField(
                          controller: _phoneController,
                          hintText: 'Teléfono de contacto (+57...)',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'El teléfono es obligatorio'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        RoundedInputField(
                          controller: _emergencyPhoneController,
                          hintText: 'Tel. emergencia (opcional)',
                          prefixIcon: Icons.phone_in_talk_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        RoundedInputField(
                          controller: _passwordController,
                          hintText: 'Contraseña',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La contraseña es obligatoria';
                            }
                            if (value.length < 8) {
                              return 'Mínimo 8 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // Esta validación se queda en Flutter porque es una
                        // comparación local entre dos campos — NestJS no puede saberlo
                        RoundedInputField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirmar contraseña',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) =>
                              (value != _passwordController.text)
                              ? 'Las contraseñas no coinciden'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'REGISTRARSE',
                          onPressed: _handleRegister,
                        ),
                        const SizedBox(height: 12),
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

  // Solo arma el mapa y delega — sin validaciones de formato ni lógica
  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

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

    final error = await userService.createUser(userData);

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Registro exitoso! Por favor, inicia sesión.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _RegistrationHeader extends StatelessWidget {
  const _RegistrationHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppLogoHeader(avatarRadius: 70),
        SizedBox(height: 8),
        Text(
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
