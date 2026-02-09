import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'user_service.dart';

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
        .limit(1)
        .snapshots();
  }

  // Obtiene el historial de tomas
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

  // Actualiza el estado de una toma y gestiona la cancelación del SMS
  Future<void> actualizarEstadoToma(
      String medId, String fechaTomaISO, bool confirmada) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final medRef = userRef.collection('medicamentos').doc(medId);

      // 1. Registro en Historial
      final medDoc = await medRef.get();
      final nombreMedicamento = medDoc.data()?['nombre'] ?? 'Desconocido';

      await medRef.collection('tomasHistorial').add({
        'fecha': fechaTomaISO,
        'hora': DateTime.now().toLocal().toIso8601String().split('T')[1].split('.')[0],
        'nombreMedicamento': nombreMedicamento,
        'estado': confirmada ? 'Completada' : 'Omitida',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Actualizar estado actual de la toma
      final existingTomaActual = await medRef.collection('tomas')
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
        await medRef.collection('tomas').add(newState);
      }

      // 3. LOGICA SMS: Si confirma, cancelamos cualquier alerta pendiente (Criterio No Duplicidad)
      if (confirmada) {
        try {
          // 1. Buscamos todas las alertas 'pending' del usuario
          final alertaQuery = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('alertas_sms_pendientes')
              .where('status', isEqualTo: 'pending')
              .get();

          debugPrint("🔍 Buscando alertas... Encontradas: ${alertaQuery.docs.length}");

          for (var doc in alertaQuery.docs) {
            final data = doc.data();

            // Comparamos si el medId coincide o si el nombre del medicamento está en el cuerpo
            // Esto es más seguro por si los IDs (medicationId) tienen formatos distintos
            bool esMismoMed = data['medicationId'] == medId ||
                data['body'].toString().contains(nombreMedicamento);

            if (esMismoMed) {
              await doc.reference.update({
                'status': 'cancelled',
                'confirmado': true,
                'canceladoAt': FieldValue.serverTimestamp(),
              });
              debugPrint("✅ SMS CANCELADO para: $nombreMedicamento");
            }
          }
        } catch (e) {
          debugPrint("❌ Error al intentar cancelar: $e");
        }
      }
    } catch (e) {
      debugPrint('Error al actualizar estado de toma: $e');
    }
  }

  // Programa la verificación (Timer local mientras la app está abierta)
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

    final horaTomaParts = (medDoc.data()?['hora'] ?? '00:00').split(':');
    final horaToma = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      int.parse(horaTomaParts[0]),
      int.parse(horaTomaParts[1]),
    );

    final timeUntilCheck = horaToma.add(const Duration(seconds: 10)).difference(DateTime.now());

    if (timeUntilCheck.isNegative) {
      await _checkAndNotifyIfUnconfirmed(medId, medicationName, horaToma, user.uid);
    } else {
      Timer(timeUntilCheck, () async {
        await _checkAndNotifyIfUnconfirmed(medId, medicationName, horaToma, user.uid);
      });
    }
  }

  // Verifica y crea el registro de alerta para el SMS (Criterio Múltiples Medicamentos)
  Future<void> _checkAndNotifyIfUnconfirmed(
      String medId, String medicationName, DateTime scheduledTime, String userId) async {
    try {
      // Obtener detalles para el mensaje (Criterio Contenido: Nombre y Dosis)
      final medDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medicamentos')
          .doc(medId)
          .get();

      final data = medDoc.data();
      final String dosis = data?['dosis'] ?? '';
      final int minutosGracia = data?['tiempoGraciaMinutos'] ?? 10; // Configurable

      final tomaSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medicamentos')
          .doc(medId)
          .collection('tomas')
          .get(); // Traemos las tomas para filtrar manualmente y evitar errores de formato ISO

      bool yaEstaConfirmada = tomaSnapshot.docs.any((doc) {
        final fechaDoc = doc.data()['fecha'].toString();
        final estadoDoc = doc.data()['estado'].toString();
        // Verificamos si la fecha del documento empieza igual que la que buscamos
        return fechaDoc.contains(scheduledTime.toIso8601String().split('T').first) &&
            estadoDoc == 'confirmada';
      });

      if (!yaEstaConfirmada) {
        // Solo si NO encontramos la confirmación, enviamos el SMS
        final userService = UserService();
        await userService.notifyEmergencyContact(
          userId: userId,
          medicationName: medicationName,
          dosis: dosis,
          scheduledTime: scheduledTime,
          minutosGracia: minutosGracia,
        );
      }

    } catch (e) {
      debugPrint('Error en verificación de SMS: $e');
    }
  }
}