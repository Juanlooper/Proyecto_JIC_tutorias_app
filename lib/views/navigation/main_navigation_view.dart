// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../notifications/notificaciones_view.dart';

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

  void onTapAnterior() {}

  void onTapSiguiente() {}

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
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        backgroundColor: AppTheme.primarioVerde,
        foregroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // [Logo Vecta]
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Image.asset(
                'assets/images/logo_vecta.png',
                height: 40,
                errorBuilder: (context, error, stackTrace) => const Center(child: Text("VECTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
              ),
            ),
            
            // Bloque Central: Flecha - Título - Flecha
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // [Icono Flecha Izquierda]
                  // El tamaño estándar de los botones de acción es generalmente 24.0.
                  // Cálculo de tamaño relativo: 24.0 * 0.75 = 18.0.
                  // Justificación de jerarquía visual: Un tamaño menor evita que estas flechas
                  // de navegación secundaria compitan con la atención de los iconos principales
                  // del menú, así como con el logo y el perfil.
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 18.0),
                    onPressed: onTapAnterior,
                  ),
                  
                  // [Título/Texto Central]
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Padding simétrico
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(modulosUI.length, (index) {
                            final obj = modulosUI[index];
                            return _crearBotonSuperior(index, obj['titulo'] as String, obj['icono'] as IconData);
                          }),
                        ),
                      ),
                    ),
                  ),

                  // [Icono Flecha Derecha]
                  // Tamaño relativo al 75% (24.0 * 0.75 = 18.0) para mantener la jerarquía visual balanceada.
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 18.0),
                    onPressed: onTapSiguiente,
                  ),
                ],
              ),
            ),

            // [Campanita de Notificaciones]
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notificaciones')
                  .where('usuarioId', isEqualTo: usuarioActual.identificadorUnico)
                  .where('leida', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificacionesView()));
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // [Icono de Perfil]
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilView()));
                },
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _indiceActual, children: vistasSistema),
      floatingActionButton: esAdmin || ['Mis Tutorias', 'Tablero Tutor', 'Perfil'].contains(modulosUI[_indiceActual]['titulo'])
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

