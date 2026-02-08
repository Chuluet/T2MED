import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// OBTENER PERFIL
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('GetUserProfile error: $e');
      return null;
    }
  }

  /// ACTUALIZAR PERFIL (SIN CONTRASEÑA)
  Future<String?> updateUserProfile({
    required String email,
    required String name,
    required String lastName,
    required String phone,
    required String emergencyPhone,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Usuario no autenticado';

      // 🔐 Actualizar email en Auth (requiere verificación)
      if (email.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(email.trim());
      }

      // 👤 Actualizar nombre visible en Auth
      await user.updateDisplayName('$name $lastName');

      // 🗂️ Actualizar Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'emergencyPhone':
            emergencyPhone.isNotEmpty ? emergencyPhone : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return null; // ✅ Éxito
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Debes volver a iniciar sesión para actualizar tu perfil.';
      }
      return e.message ?? 'Error al actualizar perfil.';
    } catch (e) {
      debugPrint('UpdateProfile error: $e');
      return 'Error inesperado al actualizar perfil.';
    }
  }

  /// REGISTRO
  Future<String?> createUser(
    String email,
    String password,
    String name,
    String lastName,
    String phone,
    String emergencyPhone,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'emergencyPhone':
            emergencyPhone.isNotEmpty ? emergencyPhone : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _auth.signOut();

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'La contraseña es demasiado débil.';
        case 'email-already-in-use':
          return 'El correo electrónico ya está en uso.';
        case 'invalid-email':
          return 'El correo electrónico no es válido.';
        default:
          return e.message ?? 'Error al crear la cuenta.';
      }
    } catch (e) {
      debugPrint('CreateUser error: $e');
      return 'Ocurrió un error inesperado.';
    }
  }

  /// LOGIN
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No existe una cuenta con este correo.';
        case 'wrong-password':
          return 'Contraseña incorrecta.';
        case 'invalid-email':
          return 'Correo inválido.';
        default:
          return e.message ?? 'Error al iniciar sesión.';
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return 'Ocurrió un error inesperado.';
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  /// RESET PASSWORD
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No existe una cuenta con ese correo.';
        case 'invalid-email':
          return 'El correo no es válido.';
        default:
          return e.message ?? 'Error al enviar el correo.';
      }
    } catch (e) {
      debugPrint('Reset error: $e');
      return 'Ocurrió un error inesperado.';
    }
  }

  /// NOTIFICAR CONTACTO DE EMERGENCIA
  Future<String?> notifyEmergencyContact({
    required String userId,
    required String medicationName,
    required DateTime scheduledTime,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return 'Usuario no encontrado.';

      final data = userDoc.data()!;
      final emergencyPhone = data['emergencyPhone'] as String?;

      if (emergencyPhone == null || emergencyPhone.isEmpty) {
        return 'No hay contacto de emergencia registrado.';
      }

      final elapsed =
          DateTime.now().difference(scheduledTime).inMinutes;

      if (elapsed <= 30) {
        return 'Aún no ha pasado el tiempo para notificar.';
      }

      final fullName =
          '${data['name']} ${data['lastName'] ?? ''}';

      final time =
          '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

      final message =
          'El usuario $fullName no ha confirmado la toma del medicamento '
          '$medicationName a las $time.';

      await _firestore.collection('messages').add({
        'to': emergencyPhone,
        'body': message,
        'type': 'sms',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      debugPrint('Notify error: $e');
      return 'Error al enviar la notificación.';
    }
  }
}
