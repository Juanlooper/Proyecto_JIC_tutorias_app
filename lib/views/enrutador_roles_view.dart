import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/autenticacion_provider.dart';

// (Asumimos que la clase de navegación de los estudiantes se llama así, ajusta si es necesario)
import 'main_navigation_view.dart';

// Importa aquí tu UsuarioModel para que reconozca los roles si es necesario
import '../models/usuario_model.dart';

class EnrutadorRolesView extends StatelessWidget {
  const EnrutadorRolesView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AutenticacionProvider>();
    final usuario = auth.usuarioActual;

    if (usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // EL SWITCHBOARD LÓGICO (El policía de tránsito usando la función correcta)
    if (usuario.tieneRol(RolSistema.admin)) {
      // Pantalla temporal mientras Maiky la diseña
      return _pantallaTemporal('Panel de Administrador', AppTheme.primarioAzul);
    } else if (usuario.tieneRol(RolSistema.tutor)) {
      // Pantalla temporal mientras Maiky la diseña
      return _pantallaTemporal('Panel de Tutor', AppTheme.primarioVerde);
    } else {
      // Si es estudiante normal
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
