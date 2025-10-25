import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initNotification() async {
    if (_initialized) return;

    await AwesomeNotifications().initialize(
      null, // Use default app icon
      [
        NotificationChannel(
          channelKey: 'medication_channel',
          channelName: 'Recordatorios de Medicamentos',
          channelDescription: 'Recordatorios para tomar medicamentos',
          defaultColor: Colors.indigo,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        )
      ],
    );

    _initialized = true;
  }

  // Programar notificación diaria - MUCHO MÁS SIMPLE
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_initialized) {
      await initNotification();
    }

    // Programar notificación recurrente diaria
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'medication_channel',
        title: title,
        body: body,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        repeats: true, // Se repite diariamente
        allowWhileIdle: true,
      ),
    );

    print('Notificación programada diariamente a las $hour:$minute');
  }

  // Cancelar notificaciones de un medicamento
  Future<void> cancelMedicationNotifications(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  // Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  // Mostrar notificación inmediata (para testing)
  Future<void> showNotification(int id, String title, String body) async {
    if (!_initialized) {
      await initNotification();
    }
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'medication_channel',
        title: title,
        body: body,
      ),
    );
  }
}