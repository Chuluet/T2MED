import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'user_service.dart'; // Asegúrate de importar UserService

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

  // Obtiene el historial de tomas para un medicamento específico o todos
  Stream<List<QueryDocumentSnapshot>> getTomasHistorial({String? medId}) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    if (medId != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .doc(medId)
          .collection('tomasHistorial')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs);
    } else {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .snapshots()
          .asyncMap((medsSnapshot) async {
        final medIds = medsSnapshot.docs.map((doc) => doc.id).toList();
        final futures = medIds.map((id) => _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medicamentos')
            .doc(id)
            .collection('tomasHistorial')
            .orderBy('timestamp', descending: true)
            .get());
        final snapshots = await Future.wait(futures);
        return snapshots.expand((snapshot) => snapshot.docs).toList();
      });
    }
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
        final data = doc.data() as Map<String, dynamic>;
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

  // Actualiza el estado de una toma y registra en el historial
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

      final historialRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .doc(medId)
          .collection('tomasHistorial');

      // Verificar duplicidad en el historial por fecha
      final existingTomaHistorial = await historialRef
          .where('fecha', isEqualTo: fechaTomaISO)
          .limit(1)
          .get();

      if (existingTomaHistorial.docs.isEmpty) {
        // Obtener el nombre del medicamento
        final medDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medicamentos')
            .doc(medId)
            .get();
        final nombreMedicamento = medDoc.data()?['nombre'] ?? 'Desconocido';

        // Registrar en el historial
        await historialRef.add({
          'fecha': fechaTomaISO,
          'hora': DateTime.now().toLocal().toIso8601String().split('T')[1].split('.')[0], // HH:MM:SS
          'nombreMedicamento': nombreMedicamento,
          'estado': confirmada ? 'Completada' : 'Omitida',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Actualizar o crear la toma actual
      final existingTomaActual = await tomaRef
          .where('fecha', isEqualTo: fechaTomaISO)
          .limit(1)
          .get();

      final newState = {
        'fecha': fechaTomaISO,
        'estado': confirmada ? 'confirmada' : 'omitida',
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (existingTomaActual.docs.isNotEmpty) {
        await existingTomaActual.docs.first.reference.update(newState);
      } else {
        await tomaRef.add(newState);
      }
    } catch (e) {
      debugPrint('Error al actualizar estado de toma: $e');
    }
  }

  // Programa la verificación de confirmación y notificación
  Future<void> scheduleMedicationCheck({
    required String medId,
    required String medicationName,
    required DateTime scheduledTime,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Obtener la hora del medicamento desde Firestore
    final medDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicamentos')
        .doc(medId)
        .get();
    final horaTomaParts = (medDoc.data()?['hora'] ?? '00:00').split(':');
    final horaToma = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      int.parse(horaTomaParts[0]),
      int.parse(horaTomaParts[1]),
    );

    // Programar un timer para verificar después de 1 minuto (ajustable para pruebas)
    final timeUntilCheck = horaToma.add(const Duration(minutes: 1)).difference(DateTime.now());
    if (timeUntilCheck.isNegative) {
      // Si ya pasó el tiempo, verifica inmediatamente
      await _checkAndNotifyIfUnconfirmed(medId, medicationName, horaToma, user.uid);
    } else {
      Timer(timeUntilCheck, () async {
        await _checkAndNotifyIfUnconfirmed(medId, medicationName, horaToma, user.uid);
      });
    }
  }

  // Método auxiliar para verificar y notificar si no se confirmó
  Future<void> _checkAndNotifyIfUnconfirmed(String medId, String medicationName, DateTime scheduledTime, String userId) async {
    try {
      final tomaSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medicamentos')
          .doc(medId)
          .collection('tomas')
          .where('fecha', isEqualTo: scheduledTime.toIso8601String().split('T').first)
          .limit(1)
          .get();

      if (tomaSnapshot.docs.isEmpty || tomaSnapshot.docs.first['estado'] != 'confirmada') {
        // Si no está confirmada, notificar al contacto de emergencia
        final userService = UserService(); // Instancia de UserService (puedes inyectarla con Provider)
        await userService.notifyEmergencyContact(
          userId: userId,
          medicationName: medicationName,
          scheduledTime: scheduledTime,
        );
      }
    } catch (e) {
      debugPrint('Error al verificar confirmación: $e');
    }
  }
}