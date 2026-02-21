import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:http/http.dart' as http;

/// Manejador para notificaciones en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Solo lógica rápida, sin UI ni prints
}

class NotificationService {
  static const String baseUrl = 'http://10.0.2.2:3000';
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initNotification() async {
    if (_initialized) return;

    await FirebaseMessaging.instance.requestPermission();

    final fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken != null) {
      await _registerFcmToken(fcmToken);
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationOpenedApp,
    );

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpenedApp(initialMessage);
    }

    _initialized = true;
  }

  Future<void> _registerFcmToken(String fcmToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final idToken = await user.getIdToken();

    try {
      await http.post(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );
    } catch (_) {
      // Silencioso
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final payload = message.data
        .map((key, value) => MapEntry(key, value.toString()));

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: message.hashCode,
        channelKey: 'medication_channel',
        title: message.notification?.title ?? 'Recordatorio',
        body: message.notification?.body ?? '',
        payload: payload,
      ),
    );
  }

  void _handleNotificationOpenedApp(RemoteMessage message) {
    // Lógica futura si deseas navegar según payload
  }
}