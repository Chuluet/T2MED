import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/user_service.dart';
import 'package:t2med/widgets/input_decorations.dart';

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
    final size = MediaQuery.of(context).size;
    final userService = Provider.of<UserService>(context);

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            cajamorada(size),
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 250),
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Text('Login', style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 60),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                autocorrect: false,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecorations.inputDecorations(
                                  hintText: 'ejemplo@gmail.com',
                                  labelText: 'Correo electronico',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                validator: (value) {
                                  String pattern =
                                      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                                  RegExp regExp = RegExp(pattern);
                                  return regExp.hasMatch(value ?? '')
                                      ? null
                                      : 'El formato del correo no es válido';
                                },
                              ),
                              const SizedBox(height: 50),
                              TextFormField(
                                controller: _passwordController,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                autocorrect: false,
                                obscureText: true,
                                decoration: InputDecorations.inputDecorations(
                                  hintText: '********',
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                ),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) return null;
                                  return "La contraseña es obligatoria";
                                },
                              ),
                              const SizedBox(height: 50),
                              MaterialButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                disabledColor: Colors.grey,
                                elevation: 0,
                                color: Colors.deepPurple,
                                onPressed: () async {
                                  // Ocultar teclado
                                  FocusScope.of(context).unfocus();

                                  if (!_formKey.currentState!.validate()) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Por favor, revise los campos')),
                                    );
                                    return;
                                  }

                                  final String? errorMessage = await userService.login(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                  );

                                  if (errorMessage == null) {
                                    // Navegar a la página de inicio sin poder volver atrás
                                    Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
                                  } else {
                                    // Mostrar error
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(errorMessage)),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 80,
                                    vertical: 15,
                                  ),
                                  child: const Text(
                                    'Ingresar',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, 'register'),
                    child: const Text(
                      "Crear una nueva cuenta",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container cajamorada(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(63, 63, 156, 1),
            Color.fromRGBO(90, 70, 178, 1),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(child: _burbuja(), top: 90, left: 30),
          Positioned(child: _burbuja(), top: -40, left: -30),
          Positioned(child: _burbuja(), top: -50, right: -20),
          Positioned(child: _burbuja(), bottom: -50, left: 10),
          Positioned(child: _burbuja(), bottom: 120, right: 20),
          Positioned(child: _burbuja(), bottom: 50, right: 150),
        ],
      ),
    );
  }
}

_burbuja() {
  return Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(100),
      color: const Color.fromRGBO(255, 255, 255, 0.05),
    ),
  );
}