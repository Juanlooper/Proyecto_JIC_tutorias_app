import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../models/usuario_model.dart';
import '../../providers/autenticacion_provider.dart';

class PerfilPublicoTutorView extends StatefulWidget {
  final UsuarioModel mentor;

  const PerfilPublicoTutorView({super.key, required this.mentor});

  @override
  State<PerfilPublicoTutorView> createState() => _PerfilPublicoTutorViewState();
}

class _PerfilPublicoTutorViewState extends State<PerfilPublicoTutorView> {
  // Variables estadísticas
  int _totalTutoriasDictadas = 0;
  double _promedioEstrellas = 0.0;
  int _totalEvaluaciones = 0;
  bool _calculandoStats = true;

  @override
  void initState() {
    super.initState();
    _calcularMetricas();
  }

  Future<void> _calcularMetricas() async {
    try {
      // 1. Obtener la cantidad total de tutorías finalizadas del tutor
      final snapTutorias = await FirebaseFirestore.instance
          .collection('tutorias')
          .where('identificadorDelTutor', isEqualTo: widget.mentor.identificadorUnico)
          .where('estadoDeLaSolicitud', isEqualTo: 'finalizada')
          .get();

      // 2. Obtener las evaluaciones directas para el promedio
      final snapEvaluaciones = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.mentor.identificadorUnico)
          .collection('evaluaciones')
          .get();

      double sumaEstrellas = 0;
      if (snapEvaluaciones.docs.isNotEmpty) {
        for (var doc in snapEvaluaciones.docs) {
          sumaEstrellas += (doc['estrellas'] as num).toDouble();
        }
        _promedioEstrellas = sumaEstrellas / snapEvaluaciones.docs.length;
        _totalEvaluaciones = snapEvaluaciones.docs.length;
      }

      if (mounted) {
        setState(() {
          _totalTutoriasDictadas = snapTutorias.docs.length;
          _calculandoStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _calculandoStats = false;
        });
      }
    }
  }

  Widget _construirMetrica(String valor, String etiqueta, IconData icono) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primarioAzul.withValues(alpha: 0.1),
          child: Icon(icono, color: AppTheme.primarioAzul),
        ),
        const SizedBox(height: 8),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(etiqueta, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final autProvider = context.watch<AutenticacionProvider>();
    final miIdentidad = autProvider.usuarioActual;
    
    // Regla de Negocio: Sólo los tutores y administradores pueden ver perfiles de estudiantes.
    if (miIdentidad?.rolEnElSistema == RolSistema.estudiante && widget.mentor.rolEnElSistema == RolSistema.estudiante) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Restringido'),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textoOscuro,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Perfil Privado',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textoOscuro),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Por políticas de privacidad, los estudiantes no pueden ver el perfil de otros estudiantes. Esta acción está reservada para tutores y administradores.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Verificamos si ya seguimos a este tutor
    final yaSuscrito = miIdentidad?.listaDeTutoresSuscritos.contains(widget.mentor.identificadorUnico) ?? false;
    final esTutor = widget.mentor.rolEnElSistema == RolSistema.tutor;

    return Scaffold(
      backgroundColor: AppTheme.fondoClaro,
      appBar: AppBar(
        title: Text(esTutor ? 'Perfil del Tutor' : 'Perfil del Estudiante'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textoOscuro,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabecera principal
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: esTutor ? AppTheme.primarioVerde.withValues(alpha: 0.2) : Colors.grey.shade200,
                    child: Icon(Icons.person, size: 60, color: esTutor ? AppTheme.primarioVerde : Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.mentor.nombreCompleto,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textoOscuro),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.mentor.carrera ?? widget.mentor.facultad ?? 'Área No Especificada',
                    style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Franja de Estadísticas (Aplica más para Tutores, mostrar 0 para estudiantes)
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                         if (_calculandoStats && esTutor)
                           const CircularProgressIndicator()
                         else ...[
                           _construirMetrica(esTutor ? _promedioEstrellas.toStringAsFixed(1) : '-', 'Estrellas', Icons.star),
                           _construirMetrica(esTutor ? _totalEvaluaciones.toString() : '0', 'Reseñas', Icons.reviews),
                           _construirMetrica(esTutor ? _totalTutoriasDictadas.toString() : '0', 'Tutorías', Icons.history_edu),
                         ]
                      ],
                   ),

                  const SizedBox(height: 24),

                  // Botón de Seguir / Unfollow (Solo si es a un tutor)
                  if (miIdentidad != null && miIdentidad.identificadorUnico != widget.mentor.identificadorUnico && esTutor)
                    SizedBox(
                      width: 250,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yaSuscrito ? Colors.grey.shade300 : AppTheme.primarioAzul,
                          foregroundColor: yaSuscrito ? Colors.black87 : Colors.white,
                          elevation: yaSuscrito ? 0 : 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          await autProvider.gestionarSuscripcionATutor(widget.mentor.identificadorUnico);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(yaSuscrito ? 'Has dejado de seguir a este tutor' : '¡Ahora sigues a este tutor!'),
                                backgroundColor: yaSuscrito ? Colors.black87 : Colors.green,
                              ),
                            );
                          }
                        },
                        icon: Icon(yaSuscrito ? Icons.person_remove : Icons.person_add),
                        label: Text(yaSuscrito ? 'Dejar de seguir' : 'Seguir y Notificarme', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),

            // Sección: Sobre el tutor
            if (esTutor || widget.mentor.descripcionPerfil?.isNotEmpty == true) ...[
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(esTutor ? 'Sobre mí' : 'Sobre el usuario', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textoOscuro)),
                    const SizedBox(height: 12),
                    Text(
                      widget.mentor.descripcionPerfil ?? 'Este perfil no cuenta con una descripción pública aún.',
                      style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Sección: Contacto Directo
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contacto Directo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textoOscuro)),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    horizontalTitleGap: 8,
                    leading: const CircleAvatar(backgroundColor: Color(0xFFE5EFF9), child: Icon(Icons.email, color: AppTheme.primarioAzul)),
                    title: const Text('Correo Institucional', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    subtitle: Text(widget.mentor.correoElectronico, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    horizontalTitleGap: 8,
                    leading: const CircleAvatar(backgroundColor: Color(0xFFE6F6F2), child: Icon(Icons.phone, color: AppTheme.primarioVerde)),
                    title: const Text('Teléfono Personal', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    subtitle: Text(widget.mentor.telefonoPersonal ?? 'No provisto al público', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48), // Padding inferior
          ],
        ),
      ),
    );
  }
}
