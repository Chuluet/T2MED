import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:t2med/pages/forgot_password_page.dart';

// Widgets reutilizables
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
    // Mostrar mensaje opcional enviado por otras pantallas
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
          // Fondo limpio
          const DecorativeBackground(),

          // Contenido distribuido verticalmente en toda la pantalla
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // Sección superior: logo + avatar (ocupa ~40% del espacio)
                  Expanded(
                    flex: 4,
                    child: Center(child: const AppLogoHeader()),
                  ),

                  // Sección central: formulario
                  Expanded(
                    flex: 5,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Campo correo
                          RoundedInputField(
                            controller: _emailController,
                            hintText: 'Correo electrónico',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El correo es obligatorio';
                              }
                              const pattern =
                                  r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@'
                                  r'((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|'
                                  r'(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                              final regExp = RegExp(pattern);
                              return regExp.hasMatch(value)
                                  ? null
                                  : 'El formato del correo no es válido';
                            },
                          ),

                          const SizedBox(height: 14),

                          // Campo contraseña
                          RoundedInputField(
                            controller: _passwordController,
                            hintText: 'Contraseña',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La contraseña es obligatoria';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Botón primario
                          PrimaryButton(
                            label: 'INICIAR SESIÓN',
                            onPressed: _handleLogin,
                          ),

                          const SizedBox(height: 12),

                          // Botón secundario
                          OutlinedActionButton(
                            label: 'CREAR CUENTA',
                            onPressed: () =>
                                Navigator.pushNamed(context, 'register'),
                          ),

                          const SizedBox(height: 10),

                          // Enlace olvidé contraseña
                          LinkTextButton(
                            label: '¿Olvidaste tu contraseña?',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordPage()),
                              );
                            },
                            textColor: const Color(0xFF2C3E50),
                            fontSize: 13,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Espacio inferior para respirar
                  const Expanded(flex: 1, child: SizedBox()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al iniciar sesión';
      if (e.code == 'user-not-found') {
        errorMessage = 'No existe una cuenta con este correo';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Correo inválido';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Esta cuenta ha sido deshabilitada';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}
