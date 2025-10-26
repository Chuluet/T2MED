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

  // Programar notificación diaria simple (sin botones)
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) {
      await initNotification();
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'medication_channel',
        title: title,
        body: body,
        // Al tocar la notificación se abrirá la app
        payload: {'navigate': 'true'},
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
      ),
    );

    print('Notificación simple programada diariamente a las $hour:$minute');
  }

  // Cancelar notificaciones de un medicamento
  Future<void> cancelMedicationNotifications(int id) async {
    await AwesomeNotifications().cancel(id);
  }
}
