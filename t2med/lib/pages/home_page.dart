import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:t2med/services/user_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos el Provider para obtener la instancia correcta del servicio
    final userService = Provider.of<UserService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('T2Med'),
        automaticallyImplyLeading: false, // Oculta el botón de regreso
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async { // Convertido a async
              await userService.logout();
              // Navegamos a la ruta 'login' y eliminamos el historial de navegación
              Navigator.pushNamedAndRemoveUntil(context, 'login', (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
            SizedBox(height: 20),
            Text(
              '¡Inicio de sesión exitoso!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Bienvenido a T2Med.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
