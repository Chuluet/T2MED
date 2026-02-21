import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final userService = Provider.of<UserService>(context, listen: false);
    final email = _emailController.text.trim();
    final result = await userService.sendPasswordReset(email);
    setState(() => _loading = false);

    if (result == null) {
      // Éxito: mostrar diálogo y redirigir al login al aceptar
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Correo enviado'),
          content: Text('Se ha enviado un correo a $email con instrucciones para restablecer la contraseña.'),
          actions: [
            TextButton(
              onPressed: () {
                // Cerrar diálogo
                Navigator.of(context).pop();
                // Redirigir al login y limpiar la pila de rutas, pasando un mensaje para mostrar al usuario
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  'login',
                  (route) => false,
                  arguments: 'Se ha enviado un correo para restablecer la contraseña. Revisa tu bandeja.'
                );
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } else {
      // Error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Olvidé mi contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Introduce tu correo electrónico y te enviaremos un enlace para restablecer la contraseña.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Introduce un correo.';
                  final email = value.trim();
                  final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
                  if (!emailRegex.hasMatch(email)) return 'Introduce un correo válido.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : const Text('Enviar enlace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
