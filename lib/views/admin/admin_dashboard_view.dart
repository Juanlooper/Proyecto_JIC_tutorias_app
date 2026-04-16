import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';

/// Vista del Panel de Administración.
/// Diseñada por Alejandra para visualizar el estado global de la plataforma JIC.
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  @override
  void initState() {
    super.initState();
    // Disparamos la carga de datos al iniciar la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarEstadisticasDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoClaro,
      body: SafeArea(
        child: Consumer<AdminProvider>(
          builder: (context, adminProv, child) {
            if (adminProv.estaCargando) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MÉTRICAS GLOBALES',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppTheme.textoOscuro,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Cuadrícula de métricas (HCI: Agrupamiento perceptual para facilitar la lectura)
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _TarjetaMetrica(
                          titulo: 'Estudiantes activos',
                          valor: adminProv.estudiantesActivos.toString(),
                          icono: Icons.school,
                        ),
                        _TarjetaMetrica(
                          titulo: 'Clases programadas',
                          valor: adminProv.clasesProgramadas.toString(),
                          icono: Icons.calendar_month,
                        ),
                        _TarjetaMetrica(
                          titulo: 'Tutorías finalizadas',
                          valor: adminProv.tutoriasFinalizadas.toString(),
                          icono: Icons.done_all,
                        ),
                        _TarjetaMetrica(
                          titulo: 'Inscripciones totales',
                          valor: adminProv.inscripcionesTotales.toString(),
                          icono: Icons.assessment,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Widget interno para representar cada métrica individual.
class _TarjetaMetrica extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;

  const _TarjetaMetrica({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icono, color: AppTheme.primarioVerde, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.grisTexto,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primarioVerde,
              ),
            ),
          ),
        ],
      ),
    );
  }
}