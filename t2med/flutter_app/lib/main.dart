import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:t2med/pages/home_page.dart';
import 'package:t2med/pages/login_page.dart';
import 'package:t2med/pages/registration_page.dart';
import 'package:t2med/services/user_service.dart';
import 'package:t2med/services/med_service.dart';
import 'package:t2med/services/notification_service.dart';
import 'package:t2med/services/pdf_service.dart';
import 'firebase_options.dart';
import 'package:t2med/services/appointment_service.dart';

///  *********************************************
///     NOTIFICATION CONTROLLER
///  *********************************************

class NotificationController {
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {}

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {}

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('Got an action: ${receivedAction.buttonKeyPressed}');

    if (receivedAction.buttonKeyPressed == 'CONFIRM') {
      debugPrint('Confirmed');
    } else if (receivedAction.buttonKeyPressed == 'OMIT') {
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
    null,
    [
      NotificationChannel(
        channelKey: 'medication_channel',
        channelName: 'Recordatorios de Medicamentos',
        channelDescription: 'Recordatorios para tomar medicamentos',
        defaultColor: const Color(0xFF2196F3),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
      )
    ],
    debug: true,
  );

  // Listeners de notificaciones
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationCreatedMethod:
        NotificationController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod:
        NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod:
        NotificationController.onDismissActionReceivedMethod,
  );

  // Permisos de notificaciones
  await AwesomeNotifications().requestPermissionToSendNotifications();

  // Formato de fechas en español
  await initializeDateFormatting('es_ES', null);

  runApp(const AppState());
}

class AppState extends StatelessWidget {
  const AppState({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicationService()),
        ChangeNotifierProvider(create: (_) => AppointmentService()),
        Provider(create: (_) => NotificationService()),
        Provider(create: (_) => PdfService()),
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          primary: const Color(0xFF2196F3),
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F5F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
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