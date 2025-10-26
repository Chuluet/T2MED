import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:t2med/pages/home_page.dart';
import 'package:t2med/pages/login_page.dart';
import 'package:t2med/pages/registration_page.dart';
import 'package:t2med/services/user_service.dart';
import 'firebase_options.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

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
  );

  // Solicitar permisos para notificaciones
  await AwesomeNotifications().requestPermissionToSendNotifications();

  // Listener para acciones de notificación
  AwesomeNotifications().actionStream.listen((ReceivedAction receivedAction) {
    print('Got an action: ${receivedAction.buttonKeyPressed}');
    // Aquí puedes agregar la lógica para manejar la confirmación u omisión de la toma del medicamento.
    // Por ejemplo, actualizar una base de datos o enviar una confirmación a un servidor.
  });

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