import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtiene el stream de tomas para un medicamento en una fecha específica
  Stream<QuerySnapshot> getTomaStream(String medId, DateTime fecha) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    final fechaISO = DateTime(fecha.year, fecha.month, fecha.day).toIso8601String();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicamentos')
        .doc(medId)
        .collection('tomas')
        .where('fecha', isEqualTo: fechaISO)
        .limit(1) // Solo debería haber una toma por día
        .snapshots();
  }

  // Obtiene los medicamentos con tomas pasadas y no confirmadas para hoy
  Future<List<Map<String, dynamic>>> getMedicamentosPendientes() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .get();

      final List<Map<String, dynamic>> pendientes = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final horaTomaParts = data['hora'].split(':');
        final horaToma = DateTime(
          hoy.year,
          hoy.month,
          hoy.day,
          int.parse(horaTomaParts[0]),
          int.parse(horaTomaParts[1]),
        );

        // Si la hora de la toma ya pasó hoy
        if (horaToma.isBefore(now)) {
          final tomaSnapshot = await doc.reference
              .collection('tomas')
              .where('fecha', isEqualTo: hoy.toIso8601String().split('T').first)
              .limit(1)
              .get();

          // Si no existe un registro de toma para hoy, está pendiente
          if (tomaSnapshot.docs.isEmpty) {
            pendientes.add({
              'id': doc.id,
              ...data,
            });
          }
        }
      }
      return pendientes;
    } catch (e) {
      debugPrint('Error al obtener medicamentos pendientes: $e');
      return [];
    }
  }

  // Actualiza el estado de una toma (confirmada u omitida)
  Future<void> actualizarEstadoToma(
      String medId, String fechaTomaISO, bool confirmada) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final tomaRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .doc(medId)
          .collection('tomas');

      // Buscar si ya existe una toma para esa fecha
      final existingToma = await tomaRef.where('fecha', isEqualTo: fechaTomaISO).limit(1).get();

      final newState = {
        'fecha': fechaTomaISO,
        'estado': confirmada ? 'confirmada' : 'omitida',
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (existingToma.docs.isNotEmpty) {
        // Si ya existe, la actualiza
        await existingToma.docs.first.reference.update(newState);
      } else {
        // Si no existe, la crea
        await tomaRef.add(newState);
      }
    } catch (e) {
      debugPrint('Error al actualizar estado de toma: $e');
    }
  }
}
