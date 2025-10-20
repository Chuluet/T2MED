import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddMedService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guarda un nuevo medicamento asociado al usuario actual.
  Future<String?> addMedicine({
    required String nombre,
    required String dosis,
    required String nota,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String hora,
    required int colorIndex,
  }) async {
    try {
      // 1️⃣ Verifica que haya un usuario autenticado
      final user = _auth.currentUser;
      if (user == null) {
        return 'No hay un usuario autenticado.';
      }

      // 2️⃣ Crea un nuevo documento en la colección "medicamentos"
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .add({
        'nombre': nombre,
        'dosis': dosis,
        'nota': nota.isNotEmpty ? nota : null,
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
        'hora': hora,
        'colorIndex': colorIndex,
        'createdAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return null; // Éxito
    } catch (e) {
      debugPrint('Error al guardar medicamento: $e');
      return 'Ocurrió un error al guardar el medicamento.';
    }
  }

  /// Obtiene todos los medicamentos del usuario autenticado.
  Future<List<Map<String, dynamic>>> getMedicines() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error al obtener medicamentos: $e');
      return [];
    }
  }

  /// Elimina un medicamento por ID
  Future<String?> deleteMedicine(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No hay un usuario autenticado.';

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .doc(id)
          .delete();

      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error al eliminar medicamento: $e');
      return 'No se pudo eliminar el medicamento.';
    }
  }

  /// Actualiza un medicamento existente.
  Future<String?> updateMedicine({
    required String id,
    required String nombre,
    required String dosis,
    required String nota,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String hora,
    required int colorIndex,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'No hay un usuario autenticado.';
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .doc(id)
          .update({
        'nombre': nombre,
        'dosis': dosis,
        'nota': nota.isNotEmpty ? nota : null,
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
        'hora': hora,
        'colorIndex': colorIndex,
      });

      notifyListeners();
      return null; // Éxito
    } catch (e) {
      debugPrint('Error al actualizar medicamento: $e');
      return 'Ocurrió un error al actualizar el medicamento.';
    }
  }
}