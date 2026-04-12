import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/autenticacion_provider.dart';
import '../../providers/tutorias_provider.dart';
import '../../models/tutoria_model.dart';
import '../../models/usuario_model.dart';

class MisTutoriasView extends StatefulWidget {
  const MisTutoriasView({super.key});

  @override
  State<MisTutoriasView> createState() => _MisTutoriasViewState();
}

class _MisTutoriasViewState extends State<MisTutoriasView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final proveedorIdentidad = context.read<AutenticacionProvider>();
      final uid = proveedorIdentidad.usuarioActual?.identificadorUnico;
      if (uid != null) {
        context.read<TutoriasProvider>().cargarTutoriasSuscritasDelUsuario(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Compromisos Vigentes'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.class_), text: 'Asistiendo'),
              Tab(icon: Icon(Icons.co_present), text: 'Dictando'),
            ],
          ),
        ),
        body: Consumer2<AutenticacionProvider, TutoriasProvider>(
          builder: (context, authProv, tutProv, child) {
            final UsuarioModel? usuarioEnSesion = authProv.usuarioActual;
            
            if (usuarioEnSesion == null || tutProv.estaCargandoPeticionEnNube) {
              return const Center(child: CircularProgressIndicator());
            }

            final String uid = usuarioEnSesion.identificadorUnico;
            final List<TutoriaModel> universoTutorias = tutProv.tutoriasSuscritasDelUsuario;

            // Filtro dinámico en tiempo de ejecución
            final listadoAsistiendo = universoTutorias.where((tuto) => tuto.listaDeEstudiantesInscritos.contains(uid)).toList();
            final listadoDictando = universoTutorias.where((tuto) => tuto.identificadorDelTutor == uid).toList();

            return TabBarView(
              children: [
                _ModuloListaDeTutorias(
                  loteEspecifico: listadoAsistiendo,
                  esModoDictando: false,
                ),
                _ModuloListaDeTutorias(
                  loteEspecifico: listadoDictando,
                  esModoDictando: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModuloListaDeTutorias extends StatelessWidget {
  final List<TutoriaModel> loteEspecifico;
  final bool esModoDictando;

  const _ModuloListaDeTutorias({
    required this.loteEspecifico,
    required this.esModoDictando,
  });

  @override
  Widget build(BuildContext context) {
    if (loteEspecifico.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                esModoDictando ? Icons.draw : Icons.auto_stories,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Aún no tienes compromisos en esta sección.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: loteEspecifico.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _TarjetaDeCompromiso(
          datos: loteEspecifico[index],
          esSeccionDictando: esModoDictando,
        );
      },
    );
  }
}

class _TarjetaDeCompromiso extends StatelessWidget {
  final TutoriaModel datos;
  final bool esSeccionDictando;

  const _TarjetaDeCompromiso({
    required this.datos,
    required this.esSeccionDictando,
  });

  Future<void> _abrirEnlaceGenuino(BuildContext context) async {
    if (datos.enlaceOReunion == null || datos.enlaceOReunion!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El profesor aún no ha provisto un enlace para esta materia.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Aquí idealmente vendría un url_launcher general, pero respetamos la regla de negocio
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando a: ${datos.enlaceOReunion}'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Future<void> _culminarTutoriaDada(BuildContext context) async {
    final confirmarFin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Tutoría'),
        content: const Text('¿Estás seguro que deseas dar por culminada la clase? Esta acción generará el cierre de horas oficiales en tu récord.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirmarFin == true && context.mounted) {
      final proveedorNotificador = context.read<TutoriasProvider>();
      final uId = context.read<AutenticacionProvider>().usuarioActual?.identificadorUnico;

      try {
        await FirebaseFirestore.instance.collection('tutorias').doc(datos.identificadorDeTutoria).update({
          'estadoDeLaSolicitud': 'finalizada',
          'horaFinReal': DateTime.now().toIso8601String(),
        });
        
        if (uId != null && context.mounted) {
          // Refrescamos Provider para que los contadores visuales cambien y lea la BD actualizada
          await proveedorNotificador.cargarTutoriasSuscritasDelUsuario(uId);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Tutoría finalizada! Horas oficiales dictadas actualizadas.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sucedió un error reportando la hora de fin a la Base de Datos.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Color _extraerColorPorEstadoBase() {
    final estado = datos.estadoDeLaSolicitud.toLowerCase();
    if (estado == 'pendiente') return Colors.orangeAccent;
    if (estado == 'aceptada' || estado == 'abierta') return Colors.blueAccent;
    if (estado == 'finalizada') return Colors.greenAccent;
    if (estado == 'cancelada') return Colors.redAccent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final fecha = datos.fechaHoraSugerida;
    final colorDeEstado = _extraerColorPorEstadoBase();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    datos.materiaOAsignatura,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorDeEstado.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorDeEstado, width: 1.5),
                  ),
                  child: Text(
                    datos.estadoDeLaSolicitud.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorDeEstado,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              datos.temaEspecifico,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.event, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} - ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Acciones Principal y Condicional
            Align(
              alignment: Alignment.centerRight,
              child: Builder(
                builder: (ctx) {
                  if (!esSeccionDictando && datos.enlaceOReunion != null) {
                    return FilledButton.icon(
                      onPressed: () => _abrirEnlaceGenuino(ctx),
                      style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primaryContainer, foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer),
                      icon: const Icon(Icons.link),
                      label: const Text('Ver enlace/aula'),
                    );
                  }
                  
                  if (esSeccionDictando && (datos.estadoDeLaSolicitud.toLowerCase() == 'aceptada' || datos.estadoDeLaSolicitud.toLowerCase() == 'abierta')) {
                    return FilledButton.icon(
                      onPressed: () => _culminarTutoriaDada(ctx),
                      style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Finalizar Tutoría'),
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
