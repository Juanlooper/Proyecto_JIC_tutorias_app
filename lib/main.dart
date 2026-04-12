import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// Importación de Nuestros Providers
import 'providers/autenticacion_provider.dart';
import 'providers/tutorias_provider.dart';

// Importación de Nuestras Vistas
import 'views/auth/login_view.dart';

void main() async {
  // Aseguramos que los componentes de Flutter estén vinculados antes de iniciar procesos nativos como Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos la conexión principal con Firebase utilizando las plataformas correctas (Android/iOS).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TutoriasApp());
}

class TutoriasApp extends StatelessWidget {
  const TutoriasApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Al envolver la MaterialApp en un MultiProvider, aseguramos que AutenticacionProvider 
    // y TutoriasProvider actúen de manera globalizada para todas las vistas.
    return MultiProvider(
      providers: [
        // Proveedor central de Identidad. Validamos al inicio la sesión usando 'inicializarSesionAlAbrirApp'.
        ChangeNotifierProvider(
          create: (_) => AutenticacionProvider()..inicializarSesionAlAbrirApp(),
        ),
        // Proveedor central del Tablero de Tutorías.
        ChangeNotifierProvider(
          create: (_) => TutoriasProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Tutorías JIC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark, // Modo oscuro por defecto
          useMaterial3: true,
        ),
        // La propiedad 'home' utiliza un Consumer para leer continuamente la validación activa del usuario.
        home: Consumer<AutenticacionProvider>(
          builder: (context, motorDeIdentidad, child) {
            // Mostramos un círculo de progreso mientras el sistema intenta leer si existe rastro
            // de una sesión en el teléfono, bloqueando el parpadeo de interfaces irreales.
            if (motorDeIdentidad.estaCargando && motorDeIdentidad.usuarioActual == null) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Si se afirma que hay sesión, lo escoltamos hasta el área de Operaciones del Sistema (HogarTemporal)
            if (motorDeIdentidad.usuarioActual != null) {
              return const PantallaHogarTemporal();
            }

            // Si verdaderamente no hay sesión, deberá de enfrentarse al muro inicial de credenciales.
            return const LoginView();
          },
        ),
      ),
    );
  }
}