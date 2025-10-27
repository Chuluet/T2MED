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

  /// Envía un correo para restablecer la contraseña al [email] indicado.
  /// Devuelve `null` si se envió correctamente, o un mensaje de error en caso contrario.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No existe una cuenta registrada con ese correo.';
      } else if (e.code == 'invalid-email') {
        return 'El correo electrónico no tiene un formato válido.';
      }
      return e.message ?? 'Ocurrió un error al intentar enviar el correo.';
    } catch (e) {
      return 'Ocurrió un error inesperado.';
    }
  }
  Future<String?> notifyEmergencyContact({
    required String userId,
    required String medicationName,
    required DateTime scheduledTime,
  }) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return 'Usuario no encontrado.';
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? emergencyPhone = userData['emergencyPhone'] as String?;

      if (emergencyPhone == null || emergencyPhone.isEmpty) {
        return 'No hay contacto de emergencia registrado.';
      }

      Duration timeElapsed = DateTime.now().toLocal().difference(scheduledTime.toLocal());
      if (timeElapsed.inMinutes <= 30) {
        return 'Aún no ha pasado el tiempo para notificar (30 min).';
      }

      String userFullName = '${userData['name']} ${userData['lastName'] ?? ''}';
      String scheduledTimeStr = '${scheduledTime.toLocal().hour.toString().padLeft(2, '0')}:${scheduledTime.toLocal().minute.toString().padLeft(2, '0')}';
      String message = 'El usuario $userFullName no ha confirmado la toma del medicamento $medicationName a las $scheduledTimeStr.';

      await _firestore.collection('messages').add({
        'to': emergencyPhone,
        'body': message,
        'type': 'sms',
      });

      return null; // Éxito
    } catch (e) {
      print('Error en notificación: $e');
      return 'Ocurrió un error inesperado al programar la notificación.';
    }
  }
}
