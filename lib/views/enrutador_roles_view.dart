import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/autenticacion_provider.dart';
import '../models/usuario_model.dart';
import 'main_navigation_view.dart';

/// Este widget actúa como el cerebro de tráfico de la aplicación.
/// Decide qué pantalla mostrar basándose exclusivamente en el rol del usuario.
class EnrutadorRolesView extends StatelessWidget {
  const EnrutadorRolesView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AutenticacionProvider>();
    final usuario = auth.usuarioActual;

    // Si por alguna razón el usuario es nulo, mostramos carga preventiva.
    if (usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // HCI: Reducción de la carga cognitiva.
    // Al centralizar la navegación aquí, evitamos que el usuario vea pantallas que no le corresponden.
    if (usuario.tieneRol(RolSistema.admin)) {
      // Ahora los administradores van a la navegación principal
      return const MainNavigationView();
    } else if (usuario.tieneRol(RolSistema.tutor)) {
      // Pantalla temporal para tutores (pendiente de diseño por Alejandra)
      return _pantallaTemporal('Panel de Tutor', AppTheme.primarioVerde);
    } else {
      // Estudiantes normales
      return const MainNavigationView();
    }
  }

  Widget _pantallaTemporal(String titulo, Color color) {
    return Scaffold(
      backgroundColor: color,
      body: Center(
        child: Text(
          'Construyendo $titulo...',
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
