import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
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
        ChangeNotifierProvider(
          create: (_) => AutenticacionProvider()..inicializarSesionAlAbrirApp(),
        ),
        ChangeNotifierProvider(create: (_) => TutoriasProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        // 4. Inyección del manejador de Tema
        ChangeNotifierProvider(create: (_) => TemaProvider()),
      ],
      child: Consumer<TemaProvider>(
        builder: (context, proveedorDeTema, hijo) {
          return MaterialApp(
            title: 'Vecta Tutorías',
            debugShowCheckedModeBanner: false,
            // Aquí evaluamos el estado lógico para decidir qué tema inyectar
            theme: proveedorDeTema.esModoOscuro
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            home: const LandingScreen(),
          );
        },
      ),
    );
  }
}
