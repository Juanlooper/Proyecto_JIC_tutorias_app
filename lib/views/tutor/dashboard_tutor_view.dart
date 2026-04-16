import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/autenticacion_provider.dart';
import '../../providers/tutorias_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tutoria_model.dart';
import 'detalle_clase_view.dart';
import 'aceptar_solicitud_view.dart';
import '../profile/perfil_view.dart';

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
            Row(
              children: [
                const Icon(Icons.group, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Alumnos inscritos: ${tutoria.listaDeEstudiantesInscritos.length}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
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
                  child: const Text('Ver y Aceptar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final proveedorTutorias = context.watch<TutoriasProvider>();
    final usuario = motorAuth.usuarioActual;

    if (usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bolsaUber = proveedorTutorias.tutoriasPendientesGenerales.where((t) {
      return t.identificadorDelTutor.trim().isEmpty &&
             t.estadoDeLaSolicitud != 'finalizada' &&
             t.estadoDeLaSolicitud != 'cancelada';
    }).toList();

    final pendientes = proveedorTutorias.tutoriasSuscritasDelUsuario.where((t) {
      return t.identificadorDelTutor == usuario.identificadorUnico &&
             t.estadoDeLaSolicitud != 'finalizada' &&
             t.estadoDeLaSolicitud != 'cancelada';
    }).toList();

    final finalizadas = proveedorTutorias.tutoriasSuscritasDelUsuario.where((t) {
      return t.identificadorDelTutor == usuario.identificadorUnico &&
             (t.estadoDeLaSolicitud == 'finalizada' || t.estadoDeLaSolicitud == 'cancelada');
    }).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/logo_vecta.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) => const Center(child: Text("VECTA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))),
            ),
          ),
          bottom: const TabBar(
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
          title: const Text('Mi Panel de Desempeño'),
          centerTitle: true,
          actions: [
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
        backgroundColor: AppTheme.fondoClaro,
        body: RefreshIndicator(
          onRefresh: () async {
            await proveedorTutorias.cargarTutoriasSuscritasDelUsuario(usuario.identificadorUnico);
          },
          child: proveedorTutorias.estaCargandoPeticionEnNube && pendientes.isEmpty && finalizadas.isEmpty && bolsaUber.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _construirLista(bolsaUber, 0),
                    _construirLista(pendientes, 1),
                    _construirLista(finalizadas, 2),
                  ],
                ),
        ),
      ),
    );
  }
}
