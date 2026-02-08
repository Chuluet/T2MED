import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'user_service.dart';

class MedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // HELPERS
  // =========================
  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  // =========================
  // STREAM DE TOMA POR DÍA
  // =========================
  Stream<QuerySnapshot> getTomaStream(String medId, DateTime fecha) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    final fechaDia = Timestamp.fromDate(_startOfDay(fecha));

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicamentos')
        .doc(medId)
        .collection('tomas')
        .where('fecha', isEqualTo: fechaDia)
        .limit(1)
        .snapshots();
  }

  // =========================
  // HISTORIAL DE TOMAS
  // =========================
Stream<List<QueryDocumentSnapshot>> getTomasHistorial() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collectionGroup('tomas')
      .orderBy('fecha', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
}


  // =========================
  // MEDICAMENTOS PENDIENTES
  // =========================
  Future<List<Map<String, dynamic>>> getMedicamentosPendientes() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final hoy = _startOfDay(now);
    final hoyTimestamp = Timestamp.fromDate(hoy);

    final medsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicamentos')
        .get();

    final List<Map<String, dynamic>> pendientes = [];

    for (final doc in medsSnapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('hora')) continue;

      final horaParts = data['hora'].split(':');
      final horaToma = DateTime(
        hoy.year,
        hoy.month,
        hoy.day,
        int.parse(horaParts[0]),
        int.parse(horaParts[1]),
      );

      if (horaToma.isBefore(now)) {
        final tomaSnapshot = await doc.reference
            .collection('tomas')
            .where('fecha', isEqualTo: hoyTimestamp)
            .limit(1)
            .get();

        if (tomaSnapshot.docs.isEmpty) {
          pendientes.add({
            'id': doc.id,
            ...data,
          });
        }
      }
    }

    return pendientes;
  }

  // =========================
  // CONFIRMAR / OMITIR TOMA
  // =========================
  Future<void> actualizarEstadoToma(
    String medId,
    DateTime fechaToma,
    bool confirmada,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final fechaKey =
        '${fechaToma.year}-${fechaToma.month.toString().padLeft(2, '0')}-${fechaToma.day.toString().padLeft(2, '0')}';

    final fechaTimestamp = Timestamp.fromDate(
      DateTime(fechaToma.year, fechaToma.month, fechaToma.day),
    );

    try {
      final medRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .doc(medId);

      final tomasRef = medRef.collection('tomas');
      final historialRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tomasHistorial');

      // =====================
      // TOMA DEL DÍA
      // =====================
      final tomaQuery = await tomasRef
          .where('fechaKey', isEqualTo: fechaKey)
          .limit(1)
          .get();

      if (tomaQuery.docs.isNotEmpty) {
        await tomaQuery.docs.first.reference.update({
          'estado': confirmada ? 'confirmada' : 'omitida',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await tomasRef.add({
          'fecha': fechaTimestamp,
          'fechaKey': fechaKey,
          'estado': confirmada ? 'confirmada' : 'omitida',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // =====================
      // HISTORIAL (SIEMPRE)
      // =====================
      final medDoc = await medRef.get();

      await historialRef.add({
        'medId': medId,
        'fecha': fechaTimestamp,
        'fechaKey': fechaKey,
        'hora':
            '${fechaToma.hour.toString().padLeft(2, '0')}:${fechaToma.minute.toString().padLeft(2, '0')}',
        'nombreMedicamento': medDoc['nombre'] ?? 'Medicamento',
        'estado': confirmada ? 'Completada' : 'Omitida',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(' Error historial: $e');
    }
  }

  // =========================
  // VERIFICAR NO CONFIRMADA
  // =========================
  Future<void> scheduleMedicationCheck({
    required String medId,
    required String medicationName,
    required DateTime scheduledTime,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final medDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicamentos')
        .doc(medId)
        .get();

    final horaParts = (medDoc.data()?['hora'] ?? '00:00').split(':');

    final horaToma = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      int.parse(horaParts[0]),
      int.parse(horaParts[1]),
    );

    final delay =
        horaToma.add(const Duration(minutes: 1)).difference(DateTime.now());

    if (delay.isNegative) {
      await _checkAndNotify(medId, medicationName, horaToma, user.uid);
    } else {
      Timer(delay, () async {
        await _checkAndNotify(medId, medicationName, horaToma, user.uid);
      });
    }
  }

  Future<void> _checkAndNotify(
    String medId,
    String medicationName,
    DateTime scheduledTime,
    String userId,
  ) async {
    try {
      final fechaDia = Timestamp.fromDate(_startOfDay(scheduledTime));

      final tomaSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medicamentos')
          .doc(medId)
          .collection('tomas')
          .where('fecha', isEqualTo: fechaDia)
          .limit(1)
          .get();

      if (tomaSnapshot.docs.isEmpty ||
          tomaSnapshot.docs.first['estado'] != 'confirmada') {
        final userService = UserService();
        await userService.notifyEmergencyContact(
          userId: userId,
          medicationName: medicationName,
          scheduledTime: scheduledTime,
        );
      }
    } catch (e) {
      debugPrint('Error al verificar toma: $e');
    }
  }
}
