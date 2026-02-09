import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:t2med/services/notification_service.dart';

class AddMedService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Inicializar el servicio de notificaciones
  Future<void> initializeNotifications() async {
    await _notificationService.initNotification();
  }

  /// Guarda un nuevo medicamento y programa notificaciones
  Future<String?> addMedicine({
    required String nombre,
    required String dosis,
    required String nota,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String hora,
    required int colorIndex,
    int tiempoGraciaMinutos = 15, // Nuevo: Recibe el tiempo configurable
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'No hay un usuario autenticado.';
      }

      await initializeNotifications();

      // Guardar en Firestore incluyendo el tiempo de gracia
      final docRef = await _firestore
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
        'tiempoGraciaMinutos': tiempoGraciaMinutos, // REQUISITO: Configurable
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Programar notificaciones locales
      await _scheduleNotifications(
        medId: docRef.id,
        nombre: nombre,
        dosis: dosis,
        nota: nota,
        hora: hora,
      );

      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error al guardar medicamento: $e');
      return 'Ocurrió un error al guardar el medicamento.';
    }
  }

  /// Programa las notificaciones locales para el teléfono del paciente
  Future<void> _scheduleNotifications({
    required String medId,
    required String nombre,
    required String dosis,
    required String nota,
    required String hora,
  }) async {
    try {
      final timeParts = hora.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final notificationId = medId.hashCode.abs();

      String body = 'Es hora de tomar $nombre - Dosis: $dosis';
      if (nota.isNotEmpty) {
        body += ' - $nota';
      }

      await _notificationService.scheduleDailyNotification(
        id: notificationId,
        title: '💊 Recordatorio de Medicamento',
        body: body,
        hour: hour,
        minute: minute,
      );

      debugPrint('Notificación programada para $nombre a las $hora');
    } catch (e) {
      debugPrint('Error al programar notificaciones: $e');
    }
  }

  /// Actualiza un medicamento y reprograma notificaciones
  Future<String?> updateMedicine({
    required String id,
    required String nombre,
    required String dosis,
    required String nota,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String hora,
    required int colorIndex,
    int tiempoGraciaMinutos = 15, // Nuevo
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No hay un usuario autenticado.';

      await _cancelScheduledNotifications(id);

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
        'tiempoGraciaMinutos': tiempoGraciaMinutos, // Actualización del tiempo
      });

      await _scheduleNotifications(
        medId: id,
        nombre: nombre,
        dosis: dosis,
        nota: nota,
        hora: hora,
      );

      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error al actualizar medicamento: $e');
      return 'Ocurrió un error al actualizar el medicamento.';
    }
  }

  /// Elimina un medicamento y cancela sus notificaciones
  Future<String?> deleteMedicine(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No hay un usuario autenticado.';

      await _cancelScheduledNotifications(id);

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

  Future<void> _cancelScheduledNotifications(String medId) async {
    try {
      final notificationId = medId.hashCode.abs();
      await _notificationService.cancelMedicationNotifications(notificationId);
    } catch (e) {
      debugPrint('Error al cancelar notificaciones: $e');
    }
  }

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
}