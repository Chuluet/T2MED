import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Nombre
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Juan',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Credenciales inválidas' : null,
              ),
              const SizedBox(height: 20),

              // Apellido
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  hintText: 'Pérez',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Credenciales inválidas' : null,
              ),
              const SizedBox(height: 20),

              // Correo
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'ejemplo@gmail.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  String pattern =
                      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                  RegExp regExp = RegExp(pattern);
                  return regExp.hasMatch(value ?? '')
                      ? null
                      : 'Credenciales inválidas';
                },
              ),
              const SizedBox(height: 20),

              // Contraseña
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _passwordController,
                textInputAction: TextInputAction.next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  hintText: '********',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  String pattern = r'^(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{8,}$';
                  RegExp regExp = RegExp(pattern);
                  if (!regExp.hasMatch(value ?? '')) {
                    return 'Credenciales inválidas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirmar contraseña
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _confirmPasswordController,
                textInputAction: TextInputAction.next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  hintText: '********',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Credenciales inválidas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Teléfono
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de contacto',
                  hintText: '3001234567',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  String pattern = r'^[0-9]{10}$'; // 10 dígitos exactos
                  RegExp regExp = RegExp(pattern);
                  return regExp.hasMatch(value ?? '')
                      ? null
                      : 'Credenciales inválidas';
                },
              ),
              const SizedBox(height: 20),

              // Teléfono de emergencia
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de emergencia (opcional)',
                  hintText: '3009876543',
                  prefixIcon: Icon(Icons.phone_in_talk),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return null; // opcional
                  String pattern = r'^[0-9]{10}$';
                  RegExp regExp = RegExp(pattern);
                  return regExp.hasMatch(value)
                      ? null
                      : 'Credenciales inválidas';
                },
              ),
              const SizedBox(height: 30),

              // Botón de registro
              MaterialButton(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                disabledColor: Colors.grey,
                elevation: 0,
                color: Colors.deepPurple,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Registro válido')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Credenciales inválidas')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
