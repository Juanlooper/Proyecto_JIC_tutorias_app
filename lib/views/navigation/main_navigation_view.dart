import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

import '../../providers/autenticacion_provider.dart';
import '../../models/usuario_model.dart';
import '../widgets/tutorial_vecta_widget.dart';
import '../home/home_view.dart';
import '../explore/explorar_view.dart';
import '../profile/perfil_view.dart';
import '../tutorias/mis_tutorias_view.dart';
import '../estudiante/sugerir_tutoria_view.dart';
import '../estudiante/mis_sugerencias_view.dart';

// Importamos tu nueva pantalla diseñada hoy
import '../tutor/dashboard_tutor_view.dart';
import '../admin/admin_dashboard_view.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _indiceActual = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarYMostrarTutorial();
    });
  }

  Future<void> _verificarYMostrarTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool visto = prefs.getBool('tutorial_visto_main') ?? false; // Clave diferenciada preventiva
    
    if (!visto && mounted) {
      await prefs.setBool('tutorial_visto_main', true);
      
      final auth = context.read<AutenticacionProvider>();
      final usuario = auth.usuarioActual;
      
      // Si tutorial_visto principal fue llamado pero este no...
      // En realidad para no fastidiar si ya vieron el tutorial_visto base:
      final bool vistoGlobal = prefs.getBool('tutorial_visto') ?? false;
      
      if (!vistoGlobal && usuario != null && mounted) {
         await prefs.setBool('tutorial_visto', true);
         await showModalBottomSheet(
           context: context,
           isScrollControlled: true,
           backgroundColor: Colors.transparent,
           builder: (context) => TutorialVectaWidget(rol: usuario.rolEnElSistema),
         );
      }
    }
  }

  void _seleccionarVista(int indice) {
    setState(() {
      _indiceActual = indice;
    });
  }

  Widget _crearBotonSuperior(int index, String texto, IconData icono) {
    final act = _indiceActual == index;
    return TextButton.icon(
      onPressed: () => _seleccionarVista(index),
      icon: Icon(icono, color: act ? Colors.white : Colors.white70, size: 20),
      label: Text(
        texto, 
        style: TextStyle(
          color: act ? Colors.white : Colors.white70, 
          fontWeight: act ? FontWeight.bold : FontWeight.normal
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motorDeIdentidad = context.watch<AutenticacionProvider>();
    final usuarioActual = motorDeIdentidad.usuarioActual;

    if (usuarioActual == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool esAdmin = usuarioActual.tieneRol(RolSistema.admin);

    final List<Map<String, dynamic>> modulosUI = [
      {'titulo': 'Cartelera', 'icono': Icons.dashboard_outlined, 'vista': const HomeView()},
      {'titulo': 'Mis Tutorias', 'icono': Icons.book_outlined, 'vista': const MisTutoriasView()},
      {'titulo': 'Sugerencias', 'icono': Icons.lightbulb_outline_rounded, 'vista': const MisSugerenciasView()},
      {'titulo': 'Comunidad', 'icono': Icons.people_outline, 'vista': const ExplorarView()},
    ];

    if (usuarioActual.tieneRol(RolSistema.tutor)) {
      modulosUI.insert(0, {'titulo': 'Tablero Tutor', 'icono': Icons.admin_panel_settings, 'vista': const DashboardTutorView()});
    }

    if (esAdmin) {
      modulosUI.add({'titulo': 'Metricas', 'icono': Icons.analytics_outlined, 'vista': const AdminDashboardView()});
    }

    // HCI Defensive: Si el estado se corrompe por un logout y _indiceActual es mayor
    if (_indiceActual >= modulosUI.length) {
      _indiceActual = 0;
    }

    final List<Widget> vistasSistema = modulosUI.map((e) => e['vista'] as Widget).toList();

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo_vecta.png',
            height: 40,
            errorBuilder: (context, error, stackTrace) => const Center(child: Text("VECTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
          ),
        ),
        title: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(modulosUI.length, (index) {
                final obj = modulosUI[index];
                return _crearBotonSuperior(index, obj['titulo'] as String, obj['icono'] as IconData);
              }),
            ),
          )
        ),
        centerTitle: true,
        actions: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 4.0),
             child: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilView()));
                },
             )
           )
        ],
        backgroundColor: AppTheme.primarioVerde,
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(index: _indiceActual, children: vistasSistema),
      floatingActionButton: esAdmin 
          ? null 
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SugerirTutoriaView()));
              },
              backgroundColor: const Color(0xFF6C63FF),
              elevation: 4,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Sugerir Clase", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
    );
  }
}

