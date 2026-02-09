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

  String _obtenerDia(int weekday) {
    final List<String> diasSemana = [
      'Domingo', 'Lunes', 'Martes', 'Miércoles', 
      'Jueves', 'Viernes', 'Sábado'
    ];
    return diasSemana[weekday - 1];
  }

  // =========================
  // STREAM DE TOMA POR DÍA
  // =========================
 Stream<QuerySnapshot> getTomaStream(String medId, DateTime fecha) {
  final user = _auth.currentUser;
  if (user == null) return const Stream.empty();

  final fechaKey =
      '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

  print('🔍 getTomaStream llamado:');
  print('   - Med ID: $medId');
  print('   - Fecha: $fecha');
  print('   - FechaKey: $fechaKey');

  return _firestore
      .collection('users')
      .doc(user.uid)
      .collection('medicamentos')
      .doc(medId)
      .collection('tomas')
      .where('fechaKey', isEqualTo: fechaKey)
      .limit(1)
      .snapshots()
      .handleError((error) {
        print('❌ Error en getTomaStream: $error');
      });
}

  // =========================
  // CONFIRMAR / OMITIR TOMA - VERSIÓN CORREGIDA
  // =========================
  Future<void> actualizarEstadoToma(
    String medId,
    DateTime fechaTomaReal,  // Hora REAL de la toma
    bool confirmada,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final medRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicamentos')
          .doc(medId);

      final tomasRef = medRef.collection('tomas');
      
      // Obtener datos del medicamento
      final medDoc = await medRef.get();
      if (!medDoc.exists) {
        print('❌ Medicamento no encontrado: $medId');
        return;
      }

      final medData = medDoc.data() ?? {};
      final nombreMedicamento = medData['nombre'] ?? 'Medicamento';

      // Crear fechaKey basada en la fecha REAL
      final fechaKey =
          '${fechaTomaReal.year}-${fechaTomaReal.month.toString().padLeft(2, '0')}-${fechaTomaReal.day.toString().padLeft(2, '0')}';

      // Obtener la hora programada COMPLETA (ej: "19:30")
      final horaProgramada = medData['hora'] ?? '00:00';
      
      // Asegurarse de que la hora programada tenga formato correcto HH:mm
      String horaProgramadaFormateada = horaProgramada;
      if (!horaProgramada.contains(':')) {
        // Si solo tiene la hora sin minutos, agregar ":00"
        horaProgramadaFormateada = '${horaProgramada.padLeft(2, '0')}:00';
      }

      print('🕒 Hora programada del medicamento: $horaProgramadaFormateada');

      // Datos para la toma en medicamentos/tomas
      final tomaData = {
        'userId': user.uid,
        'medId': medId,
        'fecha': Timestamp.fromDate(fechaTomaReal),
        'fechaKey': fechaKey,
        'dia': _obtenerDia(fechaTomaReal.weekday),
        'horaReal': fechaTomaReal.hour,
        'minutoReal': fechaTomaReal.minute,
        'horaProgramada': horaProgramadaFormateada, // Guardar como STRING completo
        'horaFormatoReal': '${fechaTomaReal.hour.toString().padLeft(2, '0')}:${fechaTomaReal.minute.toString().padLeft(2, '0')}',
        'horaFormatoProgramada': horaProgramadaFormateada,
        'nombreMedicamento': nombreMedicamento,
        'estado': confirmada ? 'Completada' : 'Omitida',
        'timestamp': FieldValue.serverTimestamp(),
      };

      print('💾 Guardando toma con hora programada: $horaProgramadaFormateada');

      // 1. Guardar en medicamentos/tomas (para pantalla principal)
      try {
        final query = await tomasRef
            .where('fechaKey', isEqualTo: fechaKey)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update(tomaData);
          print('✅ Toma actualizada en medicamentos/tomas');
        } else {
          await tomasRef.add(tomaData);
          print('✅ Toma guardada en medicamentos/tomas');
        }
      } catch (e) {
        print('❌ Error guardando en medicamentos/tomas: $e');
      }

      // 2. Guardar en tomasHistorial (para historial)
      try {
        final historialRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('tomasHistorial');
        
        final historialData = {
          'medId': medId,
          'fecha': Timestamp.fromDate(fechaTomaReal),
          'fechaKey': fechaKey,
          'dia': _obtenerDia(fechaTomaReal.weekday),
          'hora': fechaTomaReal.hour,
          'minuto': fechaTomaReal.minute,
          'horaFormato': '${fechaTomaReal.hour.toString().padLeft(2, '0')}:${fechaTomaReal.minute.toString().padLeft(2, '0')}',
          'horaProgramada': horaProgramadaFormateada, // Guardar como STRING completo
          'nombreMedicamento': nombreMedicamento,
          'estado': confirmada ? 'Completada' : 'Omitida',
          'timestamp': FieldValue.serverTimestamp(),
        };

        await historialRef.add(historialData);
        print('✅ Registro guardado en historial');
        print('   - Hora real: ${historialData['horaFormato']}');
        print('   - Hora programada: ${historialData['horaProgramada']}');

      } catch (e) {
        print('⚠️ Advertencia: No se pudo guardar en tomasHistorial');
        print('   Error: $e');
      }

    } catch (e) {
      print('❌ Error general en actualizarEstadoToma: $e');
      rethrow;
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
          tomaSnapshot.docs.first['estado'] != 'Completada') {
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