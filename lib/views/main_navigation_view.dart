import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/autenticacion_provider.dart';
import '../models/usuario_model.dart';
import 'home/home_view.dart';
import 'explore/explorar_view.dart';
import 'profile/perfil_view.dart';
import 'tutorias/mis_tutorias_view.dart';

// Importamos tu nueva pantalla diseñada hoy
import 'admin/admin_dashboard_view.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _indiceActual = 0;

  void _seleccionarVista(int indice) {
    setState(() {
      _indiceActual = indice;
    });
  }

  @override
  Widget build(BuildContext context) {
    final motorDeIdentidad = context.watch<AutenticacionProvider>();
    final usuarioActual = motorDeIdentidad.usuarioActual;

    if (usuarioActual == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool esAdmin = usuarioActual.tieneRol(RolSistema.admin);

    // Listado modular de vistas
    final List<Widget> vistasSistema = [
      const HomeView(),
      const ExplorarView(),
      const MisTutoriasView(),
      const PerfilView(),
    ];

    // Items del menú inferior
    final List<BottomNavigationBarItem> itemsNavegacion = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Explorar',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.groups_outlined),
        activeIcon: Icon(Icons.groups),
        label: 'Comunidad',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_outlined),
        activeIcon: Icon(Icons.calendar_month),
        label: 'Mis Tutorías',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

    // REGLA DE NEGOCIO Y HCI: Acceso basado en roles.
    // Solo si es administrador, inyectamos dinámicamente el Dashboard en la lista.
    if (esAdmin) {
      vistasSistema.add(const AdminDashboardView());
      itemsNavegacion.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Métricas',
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _indiceActual, children: vistasSistema),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: _seleccionarVista,
        items: itemsNavegacion,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
