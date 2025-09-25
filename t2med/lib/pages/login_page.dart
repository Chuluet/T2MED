import 'package:flutter/material.dart';
import 'package:t2med/widgets/input_decorations.dart';
import 'package:t2med/pages/registration_page.dart';
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [cajamorada(size), loginform(context)],
        ),
      ),
    );
  }

  SingleChildScrollView loginform(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 250),
          Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.symmetric(horizontal: 30),
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
                SizedBox(height: 10),
                Text('Login', style: Theme.of(context).textTheme.headlineLarge),
                SizedBox(height: 60),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecorations.inputDecorations(
                          hintText: 'ejemplo@gmail.com',
                          labelText: 'Correo electronico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          String pattern =
                              r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                          RegExp regExp = new RegExp(pattern);
                          return regExp.hasMatch(value ?? '')
                              ? null
                              : 'Credenciales invalidas';
                        },
                      ),
                      SizedBox(height: 50),
                      TextFormField(
                        autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                        autocorrect: false,
                        obscureText: true,
                        decoration: InputDecorations.inputDecorations(
                          hintText: '********',
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          String pattern =
                              r'^(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{8,}$';
                          RegExp regExp = RegExp(pattern);
                
                          if (!regExp.hasMatch(value ?? '')) {
                            return 'Credenciales inválidas';
                          }
                
                          return null;
                        },
                      ),
                      SizedBox(height: 50),
                      MaterialButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        disabledColor: Colors.grey,
                        elevation: 0,
                        color: Colors.deepPurple,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 80,
                            vertical: 15,
                          ),
                          child: Text(
                            'Ingresar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            print('Login correcto ✅');
                            // Aquí iría tu lógica de login real
                          } else {
                            print('Credenciales inválidas');
                          }
                        },
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 100),
          TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistrationPage(),
      ),
    );
  },
  child: const Text(
    "Crear una nueva cuenta",
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
  ),
),

        ],
      ),
    );
  }

  SafeArea iconopersona() {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(top: 30),
        width: double.infinity,
        child: Icon(Icons.person_pin, color: Colors.white, size: 100),
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
      color: Color.fromRGBO(255, 255, 255, 0.05),
    ),
  );
}
