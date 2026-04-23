// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';


import '../../providers/autenticacion_provider.dart';
import 'main_navigation_view.dart';
import '../widgets/tutorial_vecta_widget.dart';

/// Este widget actúa como el cerebro de tráfico de la aplicación.
/// Decide qué pantalla mostrar basándose exclusivamente en el rol del usuario.
class EnrutadorRolesView extends StatefulWidget {
  const EnrutadorRolesView({super.key});

  @override
  State<EnrutadorRolesView> createState() => _EnrutadorRolesViewState();
}

class _EnrutadorRolesViewState extends State<EnrutadorRolesView> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarYMostrarTutorial();
    });
  }

  Future<void> _verificarYMostrarTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool visto = prefs.getBool('tutorial_visto') ?? false;
    
    if (!visto && mounted) {
      await prefs.setBool('tutorial_visto', true);
      
      final auth = context.read<AutenticacionProvider>();
      final usuario = auth.usuarioActual;
      if (usuario != null && mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => TutorialVectaWidget(rol: usuario.rolEnElSistema),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escucha fluida y reactiva nivel motor para evadir pantallas blancas
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final auth = context.watch<AutenticacionProvider>();
        final usuario = auth.usuarioActual;

        // Si Firebase dice que sí, pero el provider aún no ha bajado los datos, seguimos esperando
        if (snapshot.hasData && usuario == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Flujo normal de distribución
        if (snapshot.hasData && usuario != null) {
          return const MainNavigationView();
        }

        // Si se nos cae la pantalla aquí y desautenticamos, evadimos crashes devolviendo espera
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

}
