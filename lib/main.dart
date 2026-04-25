import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Importación del ADN visual
import 'core/theme/app_theme.dart';

// Importación de todos los Providers de lógica
import 'providers/autenticacion_provider.dart';
import 'providers/tutorias_provider.dart';
import 'providers/admin_provider.dart';

// Vistas principales (Con la ruta corregida a la carpeta auth)
import 'views/auth/login_view.dart';
import 'views/navigation/enrutador_roles_view.dart';
import 'views/view/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        // 1. Manejo de Identidad (Iniciamos la sesión automáticamente si ya existía)
        ChangeNotifierProvider(
          create: (_) => AutenticacionProvider()..inicializarSesionAlAbrirApp(),
        ),

        // 2. Manejo de Tutorías
        ChangeNotifierProvider(create: (_) => TutoriasProvider()),

        // 3. Panel Administrativo para métricas
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: 'Vecta Tutorías',
        debugShowCheckedModeBanner: false,

        // ¡Aquí inyectamos el Tema Global de Vecta!
        theme: AppTheme.lightTheme,

        home: const LandingScreen(),
      ),
    );
  }
}
