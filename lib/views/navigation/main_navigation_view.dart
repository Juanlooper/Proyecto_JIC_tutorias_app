// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'dart:async';
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
import '../estudiante/mis_sugerencias_view.dart';
import '../estudiante/sugerir_tutoria_view.dart';
import '../../services/notificaciones_servicio.dart';
import '../notifications/notificaciones_view.dart';
import '../../providers/tema_provider.dart';
import '../tutor/dashboard_tutor_view.dart';
import '../admin/admin_dashboard_view.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _indiceActual = 0;

  final ScrollController _scrollControllerBarraSuperior = ScrollController();

  StreamSubscription<QuerySnapshot>? _notificacionesSub;
  bool _inicializadoListenerNotificaciones = false;

  @override
  void dispose() {
    _scrollControllerBarraSuperior.dispose(); // Limpieza de memoria obligatoria
    _notificacionesSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarYMostrarTutorial();
    });
  }

  void _iniciarListenerNotificaciones(String uid) {
    if (_inicializadoListenerNotificaciones) return;
    _inicializadoListenerNotificaciones = true;

    // Limpieza de basura (Notificaciones Viejas > 7 días)
    NotificacionesServicio().limpiarNotificacionesViejas(diasAntiguedad: 7);

    _notificacionesSub = FirebaseFirestore.instance
        .collection('notificaciones')
        .where('usuarioId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          // Usamos docChanges para ver únicamente los cambios recientes
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null && data['leida'] == false) {
                // Verificar que la notificación sea reciente (opcional, para no mostrar viejas al iniciar)
                final fechaStr = data['fecha'] as String?;
                if (fechaStr != null) {
                  final fechaNotif = DateTime.tryParse(fechaStr);
                  if (fechaNotif != null &&
                      DateTime.now().difference(fechaNotif).inSeconds < 10) {
                    // Es una notificación recién creada
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.notifications_active,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  data['titulo'] ?? 'Nueva notificación',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF1CA887),
                          duration: const Duration(seconds: 4),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.only(
                            top: 60,
                            left: 20,
                            right: 20,
                          ),
                          dismissDirection: DismissDirection.up,
                        ),
                      );
                    }
                  }
                }
              }
            }
          }
        });
  }

  Future<void> _verificarYMostrarTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool visto =
        prefs.getBool('tutorial_visto_main') ??
        false; // Clave diferenciada preventiva

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

          builder: (context) =>
              TutorialVectaWidget(rol: usuario.rolEnElSistema),
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
          fontWeight: act ? FontWeight.bold : FontWeight.normal,
        ),
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

    // Inicializamos el listener in-app de notificaciones para este usuario.
    _iniciarListenerNotificaciones(usuarioActual.identificadorUnico);

    final bool esAdmin = usuarioActual.tieneRol(RolSistema.admin);

    final List<Map<String, dynamic>> modulosUI = [
      {
        'titulo': 'Cartelera',
        'icono': Icons.dashboard_outlined,
        'vista': const HomeView(),
      },
      {
        'titulo': 'Mis Tutorias',
        'icono': Icons.book_outlined,
        'vista': const MisTutoriasView(),
      },
      {
        'titulo': 'Sugerencias',
        'icono': Icons.lightbulb_outline_rounded,
        'vista': const MisSugerenciasView(),
      },
      {
        'titulo': 'Comunidad',
        'icono': Icons.people_outline,
        'vista': const ExplorarView(),
      },
    ];

    if (usuarioActual.tieneRol(RolSistema.tutor)) {
      modulosUI.insert(0, {
        'titulo': 'Tablero Tutor',
        'icono': Icons.admin_panel_settings,
        'vista': const DashboardTutorView(),
      });
    }

    if (esAdmin) {
      modulosUI.add({
        'titulo': 'Metricas',
        'icono': Icons.analytics_outlined,
        'vista': const AdminDashboardView(),
      });
    }

    // HCI Defensive: Si el estado se corrompe por un logout y _indiceActual es mayor
    if (_indiceActual >= modulosUI.length) {
      _indiceActual = 0;
    }

    final List<Widget> vistasSistema = modulosUI
        .map((e) => e['vista'] as Widget)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

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
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text(
                        "VECTA",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                if (!isMobile)
                  // Bloque Central: Opciones de Navegación (Sin flechas, Hallazgo Heurístico #6)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SingleChildScrollView(
                        controller: _scrollControllerBarraSuperior,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(modulosUI.length, (
                            index,
                          ) {
                            final obj = modulosUI[index];
                            return _crearBotonSuperior(
                              index,
                              obj['titulo'] as String,
                              obj['icono'] as IconData,
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                if (isMobile)
                  Expanded(
                    child: Center(
                      child: Text(
                        modulosUI[_indiceActual]['titulo'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                // [Campanita de Notificaciones]
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notificaciones')
                        .where(
                          'usuarioId',
                          isEqualTo: usuarioActual.identificadorUnico,
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      int noLeidas = 0;
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>?;
                          if (data != null && data['leida'] == false) {
                            noLeidas++;
                          }
                        }
                      }
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Ver notificaciones',
                            icon: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificacionesView(),
                                ),
                              );
                            },
                          ),
                          if (noLeidas > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  noLeidas > 9 ? '9+' : noLeidas.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                // [Icono de Perfil Desplegable]
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: PopupMenuButton<String>(
                    tooltip: 'Opciones de cuenta y perfil',
                    // Icono visual del botón (el mismo que teníamos antes)
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    offset: const Offset(
                      0,
                      45,
                    ), // Desplazamiento hacia abajo para que no tape el AppBar
                    onSelected: (String valor) {
                      if (valor == 'perfil') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PerfilView()),
                        );
                      }
                    },
                    // Lógica de construcción de las opciones del menú delegada a un método
                    itemBuilder: _construirMenuDeOpciones,
                  ),
                ),
              ],
            ),
          ),
          body: IndexedStack(index: _indiceActual, children: vistasSistema),
          bottomNavigationBar: isMobile
              ? BottomNavigationBar(
                  currentIndex: _indiceActual,
                  onTap: _seleccionarVista,
                  selectedItemColor: const Color(0xFF1CA887),
                  unselectedItemColor: Colors.grey,
                  showUnselectedLabels: true,
                  type: BottomNavigationBarType.fixed,
                  items: modulosUI.map((modulo) {
                    return BottomNavigationBarItem(
                      icon: Icon(modulo['icono'] as IconData),
                      label: modulo['titulo'] as String,
                    );
                  }).toList(),
                )
              : null,
          floatingActionButton:
              esAdmin ||
                  [
                    'Mis Tutorias',
                    'Tablero Tutor',
                    'Perfil',
                  ].contains(modulosUI[_indiceActual]['titulo'])
              ? null
              : (isMobile
                    ? FloatingActionButton(
                        heroTag: 'fab_main_nav_mob',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SugerirTutoriaView(),
                            ),
                          );
                        },
                        backgroundColor: Colors.blue,
                        elevation: 4,
                        child: const Icon(Icons.add, color: Colors.white),
                      )
                    : FloatingActionButton.extended(
                        heroTag: 'fab_main_nav',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SugerirTutoriaView(),
                            ),
                          );
                        },
                        backgroundColor: const Color(0xFF6C63FF),
                        elevation: 4,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          "Sugerir Clase",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
        );
      },
    );
  }

  /// [Arquitectura UI]
  /// Método para construir las opciones del menú desplegable del perfil.
  /// Retorna una lista de PopupMenuEntry para inyectar en el PopupMenuButton.
  /// Contiene la lógica visual de las opciones, delegando el estado del
  /// Switch de modo oscuro a un StatefulBuilder interno para aislar la reconstrucción.
  List<PopupMenuEntry<String>> _construirMenuDeOpciones(BuildContext context) {
    return <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'perfil',
        child: Row(
          children: [
            Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            const Text('Perfil'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'tema',
        // Deshabilitamos el tap general para manejar solo el Switch
        enabled: false,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.dark_mode_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Modo oscuro',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Switch(
                  // Leemos el valor global en lugar de una variable local
                  value: context.watch<TemaProvider>().esModoOscuro,
                  onChanged: (bool nuevoValor) {
                    context.read<TemaProvider>().alternarTema(nuevoValor);
                  },
                ),
              ],
            );
          },
        ),
      ),
    ];
  }
}
