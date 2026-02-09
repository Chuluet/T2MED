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
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado'
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
  // OBTENER HISTORIAL DE TOMAS (de notificaciones_emergencia)
  // =========================
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

  // =========================
  // CONFIRMAR / OMITIR TOMA - VERSIÓN FUSIONADA
  // =========================
  Future<void> actualizarEstadoToma(
    String medId,
    DateTime fechaTomaReal, // Hora REAL de la toma
    bool confirmada,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final medRef = userRef.collection('medicamentos').doc(medId);

      // Obtener datos del medicamento
      final medDoc = await medRef.get();
      if (!medDoc.exists) {
        print('❌ Medicamento no encontrado: $medId');
        return;
      }

      final medData = medDoc.data() ?? {};
      final nombreMedicamento = medData['nombre'] ?? 'Medicamento';
      final dosis = medData['dosis'] ?? '';
      final minutosGracia = medData['tiempoGraciaMinutos'] ?? 10;

      // Crear fechaKey basada en la fecha REAL
      final fechaKey =
          '${fechaTomaReal.year}-${fechaTomaReal.month.toString().padLeft(2, '0')}-${fechaTomaReal.day.toString().padLeft(2, '0')}';

      // Obtener la hora programada COMPLETA
      final horaProgramada = medData['hora'] ?? '00:00';
      String horaProgramadaFormateada = horaProgramada;
      if (!horaProgramada.contains(':')) {
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
        'horaProgramada': horaProgramadaFormateada,
        'horaFormatoReal':
            '${fechaTomaReal.hour.toString().padLeft(2, '0')}:${fechaTomaReal.minute.toString().padLeft(2, '0')}',
        'horaFormatoProgramada': horaProgramadaFormateada,
        'nombreMedicamento': nombreMedicamento,
        'estado': confirmada ? 'Completada' : 'Omitida',
        'timestamp': FieldValue.serverTimestamp(),
      };

      print('💾 Guardando toma con hora programada: $horaProgramadaFormateada');

      // 1. Guardar en medicamentos/tomas (para pantalla principal)
      try {
        final query = await medRef
            .collection('tomas')
            .where('fechaKey', isEqualTo: fechaKey)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update(tomaData);
          print('✅ Toma actualizada en medicamentos/tomas');
        } else {
          await medRef.collection('tomas').add(tomaData);
          print('✅ Toma guardada en medicamentos/tomas');
        }
      } catch (e) {
        print('❌ Error guardando en medicamentos/tomas: $e');
      }

      // 2. Guardar en tomasHistorial (para historial)
      try {
        final historialData = {
          'medId': medId,
          'fecha': Timestamp.fromDate(fechaTomaReal),
          'fechaKey': fechaKey,
          'dia': _obtenerDia(fechaTomaReal.weekday),
          'hora': fechaTomaReal.hour,
          'minuto': fechaTomaReal.minute,
          'horaFormato':
              '${fechaTomaReal.hour.toString().padLeft(2, '0')}:${fechaTomaReal.minute.toString().padLeft(2, '0')}',
          'horaProgramada': horaProgramadaFormateada,
          'nombreMedicamento': nombreMedicamento,
          'estado': confirmada ? 'Completada' : 'Omitida',
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Guardar en el historial del medicamento específico
        await medRef.collection('tomasHistorial').add(historialData);
        print('✅ Registro guardado en historial del medicamento');
        print('   - Hora real: ${historialData['horaFormato']}');
        print('   - Hora programada: ${historialData['horaProgramada']}');
      } catch (e) {
        print('⚠️ Advertencia: No se pudo guardar en tomasHistorial');
        print('   Error: $e');
      }

      // 3. LOGICA SMS: Si confirma, cancelamos cualquier alerta pendiente
      if (confirmada) {
        try {
          // Buscamos todas las alertas 'pending' del usuario
          final alertaQuery = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('alertas_sms_pendientes')
              .where('status', isEqualTo: 'pending')
              .get();

          debugPrint(
              "🔍 Buscando alertas... Encontradas: ${alertaQuery.docs.length}");

          for (var doc in alertaQuery.docs) {
            final data = doc.data();

            // Comparamos si el medId coincide o si el nombre del medicamento está en el cuerpo
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
          debugPrint("❌ Error al intentar cancelar SMS: $e");
        }
      }

    } catch (e) {
      print('❌ Error general en actualizarEstadoToma: $e');
      rethrow;
    }
  }

  // =========================
  // PROGRAMAR VERIFICACIÓN DE TOMA
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

    final delay = horaToma
        .add(const Duration(minutes: 1))
        .difference(DateTime.now());

    if (delay.isNegative) {
      await _checkAndNotifyIfUnconfirmed(
          medId, medicationName, horaToma, user.uid);
    } else {
      Timer(delay, () async {
        await _checkAndNotifyIfUnconfirmed(
            medId, medicationName, horaToma, user.uid);
      });
    }
  }

  // =========================
  // VERIFICAR Y NOTIFICAR SI NO CONFIRMADA
  // =========================
  Future<void> _checkAndNotifyIfUnconfirmed(String medId,
      String medicationName, DateTime scheduledTime, String userId) async {
    try {
      // Obtener detalles para el mensaje
      final medDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medicamentos')
          .doc(medId)
          .get();

      final data = medDoc.data();
      final String dosis = data?['dosis'] ?? '';
      final int minutosGracia = data?['tiempoGraciaMinutos'] ?? 10;

      // Crear fechaKey para buscar
      final fechaKey =
          '${scheduledTime.year}-${scheduledTime.month.toString().padLeft(2, '0')}-${scheduledTime.day.toString().padLeft(2, '0')}';

      // Verificar si ya está confirmada
      final tomaSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medicamentos')
          .doc(medId)
          .collection('tomas')
          .where('fechaKey', isEqualTo: fechaKey)
          .limit(1)
          .get();

      bool yaEstaConfirmada = tomaSnapshot.docs.isNotEmpty &&
          tomaSnapshot.docs.first['estado'] == 'Completada';

      if (!yaEstaConfirmada) {
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