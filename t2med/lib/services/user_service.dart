import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> createUser(
    String email,
    String password,
    String name,
    String lastName, // Nuevo
    String phone, // Nuevo
    String emergencyPhone, // Nuevo
  ) async {
    try {
      // 1. Crear el usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Guardar la información adicional en Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'lastName': lastName, // Nuevo
        'email': email,
        'phone': phone, // Nuevo
        'emergencyPhone': emergencyPhone.isNotEmpty ? emergencyPhone : null, // Guarda null si está vacío
      });

      // 3. Cerrar la sesión del usuario inmediatamente después del registro
      await _auth.signOut();

      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'La contraseña es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        return 'El correo electrónico ya está en uso.';
      }
      return 'Ocurrió un error durante el registro.';
    } catch (e) {
      return 'Ocurrió un error inesperado.';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Sin errores, el inicio de sesión fue exitoso
    } on FirebaseAuthException catch (e) {
      // No devuelvas un mensaje genérico, podría ser un problema de red, etc.
      // Firebase ya provee mensajes localizados para errores comunes.
      return e.message; 
    } catch (e) {
      return 'Ocurrió un error inesperado.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }
}
