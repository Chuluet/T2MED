import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:t2med/pages/home_page.dart';
import 'package:t2med/pages/login_page.dart';
import 'package:t2med/pages/registration_page.dart';
import 'package:t2med/services/user_service.dart';

import 'firebase_options.dart';

///  *********************************************
///     NOTIFICATION CONTROLLER
///  *********************************************
///
class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Your code goes here
    debugPrint('Got an action: ${receivedAction.buttonKeyPressed}');

    // Navigate to a specific page based on the action button
    // This is just an example, you need to implement the navigation logic
    if (receivedAction.buttonKeyPressed == 'CONFIRM') {
      // Handle confirm action
      debugPrint('Confirmed');
    } else if (receivedAction.buttonKeyPressed == 'OMIT') {
      // Handle omit action
      debugPrint('Omitted');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar Awesome Notifications
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
    debug: true,
  );

  // Set the listener to handle notification actions
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationCreatedMethod:
        NotificationController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod:
        NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod:
        NotificationController.onDismissActionReceivedMethod,
  );

  // Solicitar permisos para notificaciones
  await AwesomeNotifications().requestPermissionToSendNotifications();

  // 👇 Esta línea evita el error de DateFormat.yMMMMd()
  await initializeDateFormatting('es_ES', null);

  runApp(const AppState());
}

class AppState extends StatelessWidget {
  const AppState({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserService()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'T2Med App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      initialRoute: 'login',
      routes: {
        'login': (_) => const LoginPage(),
        'register': (_) => const RegistrationPage(),
        'home': (_) => const HomePage(),
      },
    );
  }
}
