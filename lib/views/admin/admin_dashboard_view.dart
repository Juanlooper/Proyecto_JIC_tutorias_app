import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/autenticacion_provider.dart';
import '../auth/login_view.dart';
import 'tribunal_baneos_view.dart';
import 'buzon_postulaciones_view.dart';
import 'metricas_view.dart';
import 'quejas_view.dart';
import 'lista_estudiantes_view.dart';
import 'historial_tutorias_view.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {

  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro que deseas desconectarte del Panel de Administración?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sí, Desconectar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await context.read<AutenticacionProvider>().salirDeLaSesionActual();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (ruta) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoClaro,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo_vecta.png',
            height: 40,
            errorBuilder: (context, error, stackTrace) => const Center(child: Text("VECTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
          ),
        ),
        title: const Text('Panel de Administración - VECTA'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CENTRO DE MANDO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppTheme.textoOscuro,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.8,
                  ),
                  children: [
                    _TarjetaMenu(
                      titulo: 'Tribunal de Baneos',
                      icono: Icons.warning_amber_rounded,
                      colorRef: Colors.red,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TribunalBaneosView()));
                      },
                    ),
                    _TarjetaMenu(
                      titulo: 'Postulaciones de Tutores',
                      icono: Icons.school,
                      colorRef: Colors.blueAccent,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BuzonPostulacionesView()));
                      },
                    ),
                    _TarjetaMenu(
                      titulo: 'Métricas, Moderación y Gráficas',
                      icono: Icons.bar_chart,
                      colorRef: AppTheme.primarioVerde,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MetricasView()));
                      },
                    ),
                    _TarjetaMenu(
                      titulo: 'Estudiantes Activos',
                      icono: Icons.people,
                      colorRef: Colors.teal,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ListaEstudiantesView()));
                      },
                    ),
                    _TarjetaMenu(
                      titulo: 'Historial de Tutorías',
                      icono: Icons.history,
                      colorRef: Colors.deepPurple,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialTutoriasView()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaMenu extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color colorRef;
  final VoidCallback onTap;

  const _TarjetaMenu({
    required this.titulo,
    required this.icono,
    required this.colorRef,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: colorRef.withValues(alpha: 0.2),
        highlightColor: colorRef.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: colorRef.withValues(alpha: 0.2),
                child: Icon(icono, color: colorRef, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textoOscuro)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}