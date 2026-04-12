import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/autenticacion_provider.dart';
import '../models/usuario_model.dart';
import 'home/home_view.dart';
import 'explore/explorar_view.dart';
import 'profile/perfil_view.dart';

import 'tutorias/mis_tutorias_view.dart';

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
    // Al usar context.watch, la vista esta a la escucha de la informacion
    // del usuario actual en tiempo real.
    final motorDeIdentidad = context.watch<AutenticacionProvider>();
    final usuarioActual = motorDeIdentidad.usuarioActual;

    // Manejo de nulls en caso de que tarde milisegundos en cargar o refrescar
    if (usuarioActual == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bool esAdmin = usuarioActual.tieneRol(RolSistema.admin);

    // Listado modular de las vistas a mostrar en el flujo principal.
    final List<Widget> vistasSistema = [
      const HomeView(),
      const ExplorarView(),
      const MisTutoriasView(),
      const PerfilView(),
    ];

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

    // Regla: Si el usuario tiene RolSistema.admin, agregamos el area de metricas
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

    // Prevencion de errores en caso de cambio de roles dinamico
    if (_indiceActual >= vistasSistema.length) {
      _indiceActual = 0;
    }

    /*
     * Proposito del IndexedStack:
     * El IndexedStack es un widget asombroso que inicializa todas las vistas hijas
     * simultaneamente y simplemente corta o activa su opacidad y presencia en el lienzo
     * en base al indice proveido. A diferencia de redibujar condicionalmente, esto preserva
     * el estado de cada vista (ejemplo: preservar a que altura ibamos haciendo scroll)
     * optimizando bastante el rendimiento y mejorando la fluidez visual al cambiar las pestanas.
     */
    return Scaffold(
      body: IndexedStack(
        index: _indiceActual,
        children: vistasSistema,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: _seleccionarVista,
        items: itemsNavegacion,
        type: BottomNavigationBarType.fixed, // Asegura que persistan los colores
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Coherencia Dark Mode
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}




class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Vista: Metricas del Sistema (Admin)'));
  }
}
