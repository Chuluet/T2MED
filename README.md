# T2MED

Descripción
-----------

T2MED es una aplicación Flutter para gestionar medicaciones (proyecto de ejemplo para la asignatura). Este repositorio contiene el código fuente, configuración de Firebase mínima y los recursos para compilar y ejecutar la aplicación en plataformas soportadas por Flutter (Android, iOS, Web, Windows, Linux, macOS).

Tabla de contenido
------------------

- Descripción
- Requisitos
- Instalación rápida
- Configuración (Firebase y secretos)
- Estructura del proyecto
- Comandos útiles
- Cómo contribuir
- Licencia y autores

Requisitos
----------

Antes de compilar o ejecutar el proyecto necesitas:

- Flutter SDK (recomendado: la versión estable más reciente). Ver: https://flutter.dev/docs/get-started/install
- Dart (incluido con Flutter).
- Git (para clonar y colaborar).
- Para Android: Android SDK / Android Studio o las herramientas de línea de comandos.
- Para iOS (macOS solamente): Xcode.
- Firebase project configurado (opcional si ya incluyes `google-services.json` y `GoogleService-Info.plist`).

Instalación rápida
------------------

Estas instrucciones asumen Windows PowerShell como terminal (ajusta según tu OS):

1. Clona el repositorio (si no lo hiciste):

```powershell
git clone <url-del-repositorio>
cd T2MED/t2med
```

2. Instala dependencias de Dart/Flutter:

```powershell
flutter pub get
```

3. Ejecuta la aplicación en un dispositivo/emulador conectado:

```powershell
flutter run
```

4. Construir una APK (Android):

```powershell
flutter build apk --release
```

Configuración (Firebase y secretos)
----------------------------------

Este proyecto usa Firebase. Archivos importantes que debes conocer:

- `android/app/google-services.json`: configuración de Firebase para Android.
- `ios/Runner/GoogleService-Info.plist`: configuración de Firebase para iOS (si existe).
- `lib/firebase_options.dart`: archivo generado por el asistente de FlutterFire (`flutterfire configure`) que contiene la configuración para inicializar Firebase desde Dart.

Si trabajas con tu propio proyecto Firebase:

1. Crea un proyecto en Firebase Console.
2. Registra las aplicaciones (Android/iOS/web) y descarga `google-services.json` y `GoogleService-Info.plist`.
3. Si usas FlutterFire CLI, ejecuta desde la carpeta del proyecto:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

Nota de seguridad: no subas credenciales sensibles ni claves privadas al repositorio público. Los archivos de configuración de Firebase (por ejemplo `google-services.json`) no contienen secretos de servidor, pero si tu flujo incluye certificados o claves, mantenlas fuera del control de versiones y usa variables de entorno o servicios de secretos.

Estructura del proyecto
------------------------

Descripción corta de las carpetas relevantes:

- `lib/` - código fuente de Dart y Flutter.
	- `lib/main.dart` - punto de entrada de la app.
	- `lib/pages/` - pantallas de la app (añadir/editar medicamentos, lista, ajustes...).
	- `lib/services/` - lógica de acceso a datos y servicios (Firebase, local storage, notificaciones).
	- `lib/widgets/` - widgets reutilizables.
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` - carpetas de plataforma.
- `test/` - pruebas unitarias y de widget (si existen).

Comandos útiles
---------------

- Obtener dependencias: `flutter pub get`
- Ejecutar la app: `flutter run`
- Ejecutar pruebas: `flutter test`
- Formatear código: `flutter format .` o `dart format .`
- Analizar código estático: `flutter analyze` o `dart analyze`
- Generar build para Android: `flutter build apk`

Guía mínima de contribución
---------------------------

Si quieres contribuir a este proyecto sigue estas recomendaciones:

1. Fork y branch: crea un fork y trabaja en una rama con nombre claro (por ejemplo `feature/nueva-pantalla`).
2. Mantén commits pequeños y con mensajes claros.
3. Asegúrate que `flutter analyze` y `flutter test` pasen antes de pedir un pull request.
4. Describe en el PR qué problema resuelve o qué mejora aporta.

Buenas prácticas para mantenibilidad
----------------------------------

- Documenta cualquier configuración adicional en este README.
- Añade pruebas unitarias para lógica crítica (servicios que manipulan datos).
- Añade comentarios en funciones públicas y en widgets complejos.
- Usa un linter y reglas consistentes (analizar con `analysis_options.yaml` incluido).

Licencia
--------

Indica la licencia del proyecto. Si no hay una especificada, añade una (por ejemplo MIT, Apache-2.0, GPL). Para proyectos académicos, especifica si puede ser usado o modificado por terceros.

Autores y contacto
-------------------

- Autor: (nombre del autor o equipo)
- Repositorio: (URL del repo)
- Contacto: (email o medio de contacto)

Problemas frecuentes y resolución
--------------------------------

- "No encuentra Flutter/Dart" - Asegúrate de que Flutter está en tu PATH y reinicia la terminal.
- Errores de Firebase al iniciar - revisa que `google-services.json` y `GoogleService-Info.plist` correspondan al proyecto Firebase correcto y que `lib/firebase_options.dart` esté sincronizado.

Sugerencias y mejoras futuras
-----------------------------

- Añadir badges de CI (GitHub Actions) para análisis y tests.
- Añadir un archivo CONTRIBUTING.md con más detalle para reviewers.
- Automatizar releases y generación de versiones.

Restablecer contraseña ("Olvidé mi contraseña")
---------------------------------------------

Se ha añadido una funcionalidad que permite al usuario solicitar un enlace de restablecimiento de contraseña por correo electrónico.

Archivos principales modificados / añadidos
- `lib/services/user_service.dart` — nuevo método `sendPasswordReset(String email)` que envía el correo de restablecimiento usando Firebase Auth y devuelve mensajes de error amigables.
- `lib/pages/forgot_password_page.dart` — nueva pantalla con formulario para introducir el correo, validación y llamada al servicio. Muestra diálogo de éxito y SnackBar para errores.
- `lib/pages/login_page.dart` — se añadió un enlace "¿Olvidaste tu contraseña?" que abre la pantalla de restablecimiento. También ahora muestra un SnackBar con mensajes opcionales pasados por navegación (por ejemplo: "Revisa tu correo...").

Cómo funciona
- El usuario en la pantalla de login pulsa "¿Olvidaste tu contraseña?".
- Se abre `ForgotPasswordPage` y el usuario introduce su correo.
- Si el correo es válido, el servicio llama a `FirebaseAuth.instance.sendPasswordResetEmail`.
- Si se envía correctamente, se muestra un diálogo de confirmación; al aceptar el diálogo el usuario es redirigido al login y verá un SnackBar indicando que revise su correo.
- Si hay error (correo no registrado, formato inválido, error de red), se muestra un SnackBar con un mensaje adecuado.

Cómo probarlo localmente
1. Asegúrate de tener Firebase configurado y que el método Email/Password esté habilitado en Firebase Console > Authentication > Sign-in method.
2. Ejecuta la app en un emulador o dispositivo:

```powershell
flutter run
```

3. En la pantalla de login pulsa "¿Olvidaste tu contraseña?" y escribe el correo a probar.
4. Casos a verificar:
	- Correo registrado: recibirás un email de Firebase con el enlace para restablecer la contraseña. Tras aceptar el diálogo volverás al login y verás el mensaje.
	- Correo no registrado: verás un SnackBar con el mensaje "No existe una cuenta registrada con ese correo.".
	- Correo inválido: la validación local indicará que el correo no es válido.
	- Error de red: verás un mensaje genérico; comprueba conectividad y configuración de Firebase.

Notas y recomendaciones
- El flujo usa el comportamiento estándar de Firebase para enviar correos; asegúrate de configurar en Firebase la plantilla de correo si deseas personalizar el mensaje.
- Para producción, considera usar medidas anti-abuso (rate limiting) y mostrar mensajes que no revelen si un correo está registrado para mejorar la privacidad.
- Si quieres automatizar pruebas, puedes añadir tests unitarios que simulen errores y respuestas de `FirebaseAuth` (mock).

Documentación técnica breve
- Ruta nombrada de login: `'login'` (definida en `lib/main.dart`). La pantalla de restablecimiento redirige a esta ruta pasando un argumento con un texto para mostrar en el SnackBar.
- Mensajes y validaciones están en español en las pantallas nuevas; si la app usa i18n, migrar estos textos a tus archivos de localización.

FIN - Documentación de la funcionalidad

Cómo ayudar a documentar mejor
------------------------------

Si lees este README y crees que falta algo, abre un issue o PR con la sugerencia. Documentación clara hace el proyecto más fácil de usar y de mantener.

FIN
