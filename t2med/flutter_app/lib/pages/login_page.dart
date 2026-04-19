import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/user_service.dart';
import 'package:t2med/pages/forgot_password_page.dart';
import 'package:t2med/widgets/login/app_logo_header.dart';
import 'package:t2med/widgets/login/rounded_input_field.dart';
import 'package:t2med/widgets/login/auth_buttons.dart';
import 'package:t2med/widgets/login/decorative_background.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(args)),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFEAEFF5),
      body: Stack(
        children: [
          const DecorativeBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Expanded(flex: 4, child: Center(child: AppLogoHeader())),
                  Expanded(
                    flex: 5,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Solo muestra el campo — validación de formato
                          // la hace NestJS y el error llega como String
                          RoundedInputField(
                            controller: _emailController,
                            hintText: 'Correo electrónico',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'El correo es obligatorio'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          RoundedInputField(
                            controller: _passwordController,
                            hintText: 'Contraseña',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? 'La contraseña es obligatoria'
                                    : null,
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'INICIAR SESIÓN',
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: 12),
                          OutlinedActionButton(
                            label: 'CREAR CUENTA',
                            onPressed: () =>
                                Navigator.pushNamed(context, 'register'),
                          ),
                          const SizedBox(height: 10),
                          LinkTextButton(
                            label: '¿Olvidaste tu contraseña?',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordPage()),
                            ),
                            textColor: const Color(0xFF2C3E50),
                            fontSize: 13,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Expanded(flex: 1, child: SizedBox()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Solo orquesta: valida que no estén vacíos, llama al service,
  // muestra el resultado — sin tocar Firebase ni lógica de negocio
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final userService = context.read<UserService>();
    final error = await userService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
}