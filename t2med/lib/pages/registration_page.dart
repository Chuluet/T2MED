import 'package:flutter/material.dart';
import 'package:t2med/services/user_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController(); // Nuevo
  final TextEditingController _phoneController = TextEditingController(); // Nuevo
  final TextEditingController _emergencyPhoneController = TextEditingController(); // Nuevo

  final userService = UserService();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _lastNameController.dispose(); // Nuevo
    _phoneController.dispose(); // Nuevo
    _emergencyPhoneController.dispose(); // Nuevo
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
                controller: _nameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Juan', prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => (value == null || value.isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 20),

              // Apellido (Nuevo)
              TextFormField(
                controller: _lastNameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Apellido', hintText: 'Pérez', prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => (value == null || value.isEmpty) ? 'El apellido es obligatorio' : null,
              ),
              const SizedBox(height: 20),

              // Correo
              TextFormField(
                controller: _emailController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo electrónico', hintText: 'ejemplo@gmail.com', prefixIcon: Icon(Icons.email_outlined)),
                validator: (value) {
                  String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                  RegExp regExp = RegExp(pattern);
                  return regExp.hasMatch(value ?? '') ? null : 'El formato del correo no es válido';
                },
              ),
              const SizedBox(height: 20),

              // Teléfono (Nuevo)
              TextFormField(
                controller: _phoneController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono de contacto', hintText: '+57 3001234567', prefixIcon: Icon(Icons.phone)),
                validator: (value) {
                  String pattern = r'^\+[1-9]\d{0,2}\d{10}$'; // 10 dígitos
                  RegExp regExp = RegExp(pattern);
                  return regExp.hasMatch(value ?? '') ? null : 'Debe ser un número de 10 dígitos';
                },
              ),
              const SizedBox(height: 20),

              // Teléfono de Emergencia (Nuevo)
              TextFormField(
                controller: _emergencyPhoneController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono de emergencia (opcional)', hintText: '+57 3009876543', prefixIcon: Icon(Icons.phone_in_talk)),
                validator: (value) {
                  if (value == null || value.isEmpty) return null; // Opcional
                  String pattern = r'^\+[1-9]\d{0,2}\d{11}$';
                  RegExp regExp = RegExp(pattern);
                  return regExp.hasMatch(value) ? null : 'Debe ser un número de 10 dígitos';
                },
              ),
              const SizedBox(height: 20),

              // Contraseña
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _passwordController,
                textInputAction: TextInputAction.next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña', hintText: '********', prefixIcon: Icon(Icons.lock_outline)),
                validator: (value) {
                  if (value == null || value.length < 8) return 'Debe tener al menos 8 caracteres, una mayúscula y un número';
                  if (!value.contains(RegExp(r'[A-Z]'))) return 'Debe tener al menos 8 caracteres, una mayúscula y un número';
                  if (!value.contains(RegExp(r'[0-9]'))) return 'Debe tener al menos 8 caracteres, una mayúscula y un número';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirmar contraseña
              TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                controller: _confirmPasswordController,
                textInputAction: TextInputAction.done,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar Contraseña', hintText: '********', prefixIcon: Icon(Icons.lock_outline)),
                validator: (value) => (value != _passwordController.text) ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 30),

              // Botón de registro
              MaterialButton(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                disabledColor: Colors.grey,
                elevation: 0,
                color: Colors.deepPurple,
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  if (!_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, complete todos los campos correctamente')));
                    return;
                  }
                  
                  final String? errorMessage = await userService.createUser(
                    _emailController.text.trim(),
                    _passwordController.text.trim(),
                    _nameController.text.trim(),
                    _lastNameController.text.trim(),
                    _phoneController.text.trim(),
                    _emergencyPhoneController.text.trim(),
                  );

                  if (errorMessage == null) {
                    // Registro exitoso, volver a login
                    Navigator.of(context).pop(); // Cierra la pantalla de registro
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ ¡Registro exitoso! Por favor, inicia sesión.')),
                    );
                  } else {
                    // Mostrar error
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  child: const Text('Registrarse', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
