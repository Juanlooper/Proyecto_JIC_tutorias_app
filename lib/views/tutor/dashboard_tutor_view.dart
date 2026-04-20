import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Implemented Realtime Listener

import '../../providers/autenticacion_provider.dart';
import '../../providers/tutorias_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tutoria_model.dart';
import 'detalle_clase_view.dart';
import 'aceptar_solicitud_view.dart';


class DashboardTutorView extends StatefulWidget {
  const DashboardTutorView({super.key});

  @override
  State<DashboardTutorView> createState() => _DashboardTutorViewState();
}

class _DashboardTutorViewState extends State<DashboardTutorView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idActual = context.read<AutenticacionProvider>().usuarioActual?.identificadorUnico;
      if (idActual != null) {
        context.read<TutoriasProvider>().cargarTutoriasSuscritasDelUsuario(idActual);
        context.read<TutoriasProvider>().cargarListadoDeTutoriasPendientes();
      }
    });
  }

  // Se encarga de conectarse al socket de nube para reflejar instantáneamente (StreamBuilder) cuando un alumno pide una clase nueva.
  Widget _construirTabBolsaEnVivo() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tutorias')
          .where('estadoDeLaSolicitud', isEqualTo: 'solicitada') // Filtro Nativo #1
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primarioAzul));
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error conectando con la bolsa de solicitudes."));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _construirLista([], 0); // Re-utilizamos el constructor de estado vacío natural
        }

        final documentosNube = snapshot.data!.docs;
        final filtrados = documentosNube.map((doc) {
          return TutoriaModel.fromMap(doc.data() as Map<String, dynamic>);
        }).where((t) => t.identificadorDelTutor.isEmpty).toList(); // Filtro Restrictivo #2

        return _construirLista(filtrados, 0); 
      },
    );
  }

  // tipo: 0 (Bolsa Libre), 1 (Pendientes en curso), 2 (Formatos finalizados)
  Widget _construirTarjeta(TutoriaModel tutoria, int tipo) {
    final fecha = '${tutoria.fechaHoraSugerida.day.toString().padLeft(2, '0')}/${tutoria.fechaHoraSugerida.month.toString().padLeft(2, '0')} - ${tutoria.fechaHoraSugerida.hour.toString().padLeft(2, '0')}:${tutoria.fechaHoraSugerida.minute.toString().padLeft(2, '0')} Hrs';
    
    Color colorChip = Colors.grey;
    String textoChip = tutoria.estadoDeLaSolicitud.toUpperCase();
    if (tutoria.estadoDeLaSolicitud == 'aprobada') {
      colorChip = AppTheme.primarioAzul;
    } else if (tutoria.estadoDeLaSolicitud == 'en_revision') {
      colorChip = Colors.orange;
    } else if (tutoria.estadoDeLaSolicitud == 'finalizada') {
      colorChip = AppTheme.primarioVerde;
    } else if (tutoria.estadoDeLaSolicitud == 'cancelada') {
      colorChip = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
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
                    tutoria.materiaOAsignatura,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textoOscuro),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorChip.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorChip.withValues(alpha: 0.5)),
                  ),
                  child: Text(textoChip, style: TextStyle(color: colorChip, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(fecha, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            
            // Requisito: Motivos del alumno (solo se destaca si es tipo bolsa u otro)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Motivos: ${tutoria.temaEspecifico}',
                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Requisito: Indicador visual Chip destacado de Alumnos Interesados
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.groups_rounded, size: 18, color: Colors.white),
                label: Text(
                  tipo == 0 
                      ? 'Estudiantes apoyando: ${tutoria.estudiantesApoyando.length}'
                      : 'Alumnos inscritos: ${tutoria.listaDeEstudiantesInscritos.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                backgroundColor: AppTheme.primarioVerde, // O un color vibrante como Naranja
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
            
            // Botonera de Acción Condicionada
            if (tipo == 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AceptarSolicitudView(tutoria: tutoria)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primarioAzul,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Ver detalles y Aceptar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ] 
            else if (tipo == 1) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleClaseView(tutoria: tutoria)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primarioVerde, // Diferenciador visual
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Iniciar pase de lista', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ] 
            else ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleClaseView(tutoria: tutoria)));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text('Ver detalle archivado'),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _construirLista(List<TutoriaModel> lista, int tipo) {
    if (lista.isEmpty) {
      String msj;
      if (tipo == 0) msj = "No hay solicitudes pendientes en bolsa";
      else if (tipo == 1) msj = "No tienes clases agendadas en curso";
      else msj = "No tienes clases archivadas en el historial";
      
      return Center(
        child: Text(msj, style: const TextStyle(color: Colors.grey, fontSize: 16), textAlign: TextAlign.center),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        return _construirTarjeta(lista[index], tipo);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final motorAuth = context.watch<AutenticacionProvider>();
    final usuario = motorAuth.usuarioActual;

    if (usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Quitar retroceso
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72.0),
            child: Builder(
              builder: (context) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () {
                        final controller = DefaultTabController.of(context);
                        if (controller.index > 0) controller.animateTo(controller.index - 1);
                      },
                    ),
                    const Expanded(
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        indicatorColor: Colors.white,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        tabs: [
                          Tab(text: "Bolsa de Solicitudes", icon: Icon(Icons.work_outline)),
                          Tab(text: "Mis Pendientes", icon: Icon(Icons.schedule)),
                          Tab(text: "Finalizadas", icon: Icon(Icons.history)),
                        ],
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                        onPressed: () {
                          final controller = DefaultTabController.of(context);
                          if (controller.index < controller.length - 1) controller.animateTo(controller.index + 1);
                        },
                    ),
                  ],
                );
              }
            ),
          ),
          title: const Text('Mi Panel de Desempeño', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: AppTheme.primarioVerde,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: AppTheme.fondoClaro,
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('tutorias').where('identificadorDelTutor', isEqualTo: usuario.identificadorUnico).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primarioVerde));
            }
            if (snapshot.hasError) {
              return const Center(child: Text("Error obteniendo datos del panel en la nube."));
            }

            final docsNube = snapshot.data?.docs ?? [];
            final misTutoriasDictando = docsNube.map((doc) => TutoriaModel.fromMap(doc.data() as Map<String, dynamic>)).toList();

            final pendientes = misTutoriasDictando.where((t) {
              return t.estadoDeLaSolicitud != 'finalizada' && t.estadoDeLaSolicitud != 'cancelada';
            }).toList();

            final finalizadas = misTutoriasDictando.where((t) {
              return t.estadoDeLaSolicitud == 'finalizada' || t.estadoDeLaSolicitud == 'cancelada';
            }).toList();

            return TabBarView(
              children: [
                _construirTabBolsaEnVivo(),
                _construirLista(pendientes, 1),
                _construirLista(finalizadas, 2),
              ],
            );
          },
        ),
      ),
    );
  }
}
