import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/tema_provider.dart';

// Importación del ADN visual
import 'core/theme/app_theme.dart';

// Importación de todos los Providers de lógica
import 'providers/autenticacion_provider.dart';
import 'providers/tutorias_provider.dart';
import 'providers/admin_provider.dart';

// Vistas principales (Con la ruta corregida a la carpeta auth)
import 'views/view/landing_screen.dart';
import 'views/navigation/main_navigation_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Activación de Firebase App Check para seguridad estricta en producción
  await FirebaseAppCheck.instance.activate(
    // ignore: deprecated_member_use
    androidProvider: AndroidProvider.playIntegrity, // Producción Android
    // ignore: deprecated_member_use
    webProvider: ReCaptchaV3Provider(
      '6LdyttEsAAAAABqlMu_KYIZOUgG0AfSUjoI5inkx',
    ), // reCAPTCHA v3 invisible (Web)
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const TutoriasApp());
}

class TutoriasApp extends StatelessWidget {
  const TutoriasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Manejo de Identidad
        // Mantenemos tu inicialización por si cargas datos extra de Firestore al abrir la app.
        ChangeNotifierProvider(
          create: (_) => AutenticacionProvider()..inicializarSesionAlAbrirApp(),
        ),
        ChangeNotifierProvider(create: (_) => TutoriasProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        // 4. Inyección del manejador de Tema
        ChangeNotifierProvider(create: (_) => TemaProvider()),
      ],
      child: Consumer2<TemaProvider, AutenticacionProvider>(
        builder: (context, proveedorDeTema, authProv, hijo) {
          return MaterialApp(
            title: 'Vecta Tutorías',
            debugShowCheckedModeBanner: false,
            // Aquí evaluamos el estado lógico para decidir qué tema inyectar
            theme: proveedorDeTema.esModoOscuro
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            home: authProv.estaInicializando
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : (authProv.usuarioActual != null
                      ? const MainNavigationView()
                      : const LandingScreen()),
          );
        },
      ),
    );
  }
}
