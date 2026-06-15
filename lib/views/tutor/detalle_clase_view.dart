import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/tutoria_model.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/tutorias_provider.dart';
import '../tutorias/chat_tutoria_view.dart';

class DetalleClaseView extends StatefulWidget {
  final TutoriaModel tutoria;

  const DetalleClaseView({super.key, required this.tutoria});

  @override
  State<DetalleClaseView> createState() => _DetalleClaseViewState();
}

class _DetalleClaseViewState extends State<DetalleClaseView> {
  bool _modoPaseDeLista = false;
  final Map<String, bool> _asistenciaMapa = {};
  final Map<String, TextEditingController> _feedbackMapa = {};

  @override
  void initState() {
    super.initState();
    // Por defecto marcamos a todos los estudiantes inscritos como presentes (true)
    for (var uid in widget.tutoria.listaDeEstudiantesInscritos) {
      _asistenciaMapa[uid] = true;
      _feedbackMapa[uid] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var ctrl in _feedbackMapa.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _finalizarClase() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contextDialogo) => AlertDialog(
        title: const Text(
          'Confirmar Cierre',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Estás seguro? Esta acción cerrará la clase y aplicará faltas a los ausentes de forma irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextDialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(contextDialogo, true),
            child: const Text('Sí, Finalizar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final proveedor = context.read<TutoriasProvider>();

      Map<String, Map<String, dynamic>> payload = {};
      for (var uid in widget.tutoria.listaDeEstudiantesInscritos) {
        payload[uid] = {
          'asistio': _asistenciaMapa[uid] ?? false,
          'feedback': _feedbackMapa[uid]?.text.trim() ?? '',
        };
      }

      final exito = await proveedor.registrarAsistenciaClase(
        widget.tutoria.identificadorDeTutoria,
        payload,
      );

      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clase finalizada con éxito.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Volvemos al Dashboard
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(proveedor.mensajeDeErrorDelSistema),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelarTutoria() async {
    final TextEditingController motivoCtrl = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Cancelar Tutoría',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Esta acción cancelará la clase y notificará a los estudiantes inscritos. Por favor, indica el motivo:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                labelText: "Motivo de cancelación",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (motivoCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Confirmar Cancelación'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final proveedor = context.read<TutoriasProvider>();
      bool exito = await proveedor.cancelarTutoriaComoTutor(
        widget.tutoria.identificadorDeTutoria,
        motivoCtrl.text.trim(),
      );

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutoría cancelada exitosamente.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context); // Volvemos al Dashboard
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(proveedor.mensajeDeErrorDelSistema),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _mostrarDialogoEvaluacion(String uidAlumno) async {
    double estrellas = 5;
    final comentarioCtrl = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text(
                "Evaluar Estudiante",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Califica el desempeño del estudiante. Esta información es de uso administrativo y no será visible para el alumno.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < estrellas ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateSB(() {
                            estrellas = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: comentarioCtrl,
                    decoration: const InputDecoration(
                      labelText: "Comentario privado",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancelar"),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Guardar Reporte"),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmar == true && mounted) {
      final proveedor = context.read<TutoriasProvider>();
      final exito = await proveedor.enviarEvaluacionEstudiante(
        widget.tutoria.identificadorDeTutoria,
        uidAlumno,
        estrellas,
        comentarioCtrl.text.trim(),
      );

      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evaluación interna enviada con éxito.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Volver al dashboard para refrescar
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(proveedor.mensajeDeErrorDelSistema),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutoria = widget.tutoria;
    final fecha =
        '${tutoria.fechaHoraSugerida.day.toString().padLeft(2, '0')}/${tutoria.fechaHoraSugerida.month.toString().padLeft(2, '0')} a las ${tutoria.fechaHoraSugerida.hour.toString().padLeft(2, '0')}:${tutoria.fechaHoraSugerida.minute.toString().padLeft(2, '0')} Hrs';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la Sesión'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Panel Superior: Información de la clase
            Card(
              elevation: 0,
              color: AppTheme.primarioAzul.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppTheme.primarioAzul.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutoria.materiaOAsignatura,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primarioAzul,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.topic, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tema: ${tutoria.temaEspecifico}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fecha pautada: $fecha',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.meeting_room,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Modalidad: ${tutoria.modalidadDeClase}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt, color: AppTheme.primarioVerde),
                    const SizedBox(width: 8),
                    Text(
                      'Estudiantes (${tutoria.listaDeEstudiantesInscritos.length}/${tutoria.cupoMaximo})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tutoria.estadoDeLaSolicitud != 'finalizada' &&
                        tutoria.estadoDeLaSolicitud != 'cancelada')
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.grey,
                        ),
                        tooltip: "Editar Cupo",
                        onPressed: () async {
                          final tc = TextEditingController(
                            text: tutoria.cupoMaximo.toString(),
                          );
                          final nav = Navigator.of(context);
                          final scaffoldMsg = ScaffoldMessenger.of(context);
                          final provider = context.read<TutoriasProvider>();
                          final res = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Editar Cupo"),
                              content: TextField(
                                controller: tc,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Nuevo Cupo Máximo",
                                  hintText: "Ej. 15",
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Cancelar"),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, tc.text),
                                  child: const Text("Guardar"),
                                ),
                              ],
                            ),
                          );
                          if (res != null && res.trim().isNotEmpty) {
                            final val = int.tryParse(res.trim());
                            if (val != null) {
                              bool ok = await provider.editarCupoMaximo(
                                tutoria.identificadorDeTutoria,
                                val,
                              );
                              if (ok) {
                                scaffoldMsg.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Cupo actualizado exitosamente.",
                                    ),
                                  ),
                                );
                                nav.pop(); // Go back to refresh
                              } else {
                                scaffoldMsg.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      provider.mensajeDeErrorDelSistema,
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                  ],
                ),
                if (tutoria.estadoDeLaSolicitud != 'finalizada' &&
                    tutoria.estadoDeLaSolicitud != 'cancelada')
                  if (!_modoPaseDeLista)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1CA887),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatTutoriaView(
                                  tutoriaId: tutoria.identificadorDeTutoria,
                                  materia: tutoria.materiaOAsignatura,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.forum),
                          label: const Text('Micro-Foro (Chat)'),
                        ),
                        const SizedBox(height: 8),
                        if (tutoria.listaDeEstudiantesInscritos.isNotEmpty)
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                            ),
                            onPressed: () {
                              setState(() {
                                _modoPaseDeLista = true;
                              });
                            },
                            icon: const Icon(Icons.fact_check),
                            label: const Text('Iniciar Pase de Lista'),
                          ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: _cancelarTutoria,
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar Tutoría'),
                        ),
                      ],
                    ),
              ],
            ),
            const Divider(),

            // Panel Inferior: Lista de alumnos inscritos
            if (tutoria.listaDeEstudiantesInscritos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'Aún no hay estudiantes inscritos a tu clase.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tutoria.listaDeEstudiantesInscritos.length,
                itemBuilder: (context, index) {
                  final uidAlumno = tutoria.listaDeEstudiantesInscritos[index];

                  final mapaMotivos = tutoria.motivos_alumnos ?? {};
                  final mapaEnlaces = tutoria.enlaces_adjuntos ?? {};

                  final motivo =
                      mapaMotivos[uidAlumno] ?? 'Sin comentarios del alumno.';
                  final List<String> enlaces = mapaEnlaces[uidAlumno] ?? [];

                  // Leer la bandera local del mapa stateful
                  final presente = _asistenciaMapa[uidAlumno] ?? true;

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _modoPaseDeLista && !presente
                            ? Colors.red.shade200
                            : Colors.grey.shade200,
                      ),
                    ),
                    color: _modoPaseDeLista && !presente
                        ? Colors.red.shade50
                        : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: _modoPaseDeLista && !presente
                                    ? Colors.red.shade300
                                    : Colors.grey.shade300,
                                child: const Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('usuarios')
                                      .doc(uidAlumno)
                                      .get(),
                                  builder: (context, docSnap) {
                                    if (docSnap.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Text(
                                        "Cargando...",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      );
                                    }
                                    if (docSnap.hasData &&
                                        docSnap.data!.exists) {
                                      final map =
                                          docSnap.data!.data()
                                              as Map<String, dynamic>;
                                      final nombre =
                                          map['nombreCompleto'] ?? 'Sin nombre';
                                      return Text(
                                        nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      );
                                    }
                                    return Text(
                                      uidAlumno.length > 8
                                          ? 'Alumno ID: ${uidAlumno.substring(0, 8)}...'
                                          : 'Alumno ID: $uidAlumno',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (_modoPaseDeLista)
                                Row(
                                  children: [
                                    Text(
                                      presente ? 'Presente' : 'Ausente',
                                      style: TextStyle(
                                        color: presente
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Switch(
                                      value: presente,
                                      activeThumbColor: Colors.green,
                                      inactiveThumbColor: Colors.red,
                                      inactiveTrackColor: Colors.red.shade100,
                                      onChanged: (val) {
                                        setState(() {
                                          _asistenciaMapa[uidAlumno] = val;
                                        });
                                      },
                                    ),
                                  ],
                                )
                              else if (tutoria.estadoDeLaSolicitud ==
                                      'finalizada' &&
                                  !tutoria.alumnosEvaluadosPorTutor.contains(
                                    uidAlumno,
                                  ))
                                TextButton.icon(
                                  icon: const Icon(Icons.star_rate, size: 16),
                                  label: const Text('Evaluar Desempeño'),
                                  onPressed: () =>
                                      _mostrarDialogoEvaluacion(uidAlumno),
                                )
                              else if (tutoria.estadoDeLaSolicitud ==
                                      'finalizada' &&
                                  tutoria.alumnosEvaluadosPorTutor.contains(
                                    uidAlumno,
                                  ))
                                const Text(
                                  'Evaluado ✅',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),

                          if (_modoPaseDeLista && presente) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Expediente Clínico (Receta Académica):',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _feedbackMapa[uidAlumno],
                              decoration: InputDecoration(
                                hintText:
                                    'Opcional. Deja recomendaciones de estudio, temas a reforzar...',
                                hintStyle: const TextStyle(fontSize: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.blue.withValues(alpha: 0.05),
                              ),
                              maxLines: 2,
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                            'Motivo para asistir:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,

                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _modoPaseDeLista && !presente
                                  ? Colors.white
                                  : AppTheme.fondoClaro,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              motivo,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ),

                          if (enlaces.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Material Adjuntado:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primarioAzul,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...enlaces.map((link) {
                              bool esUrlLarga = link.contains(
                                'firebasestorage',
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: InkWell(
                                  onTap: () async {
                                    final uri = Uri.parse(link);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No se puede abrir este enlace.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withValues(
                                        alpha: 0.05,
                                      ),
                                      border: Border.all(
                                        color: Colors.blueAccent.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.attach_file,
                                          size: 18,
                                          color: Colors.blueAccent,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            esUrlLarga
                                                ? 'Ver archivo adjunto (PDF/Imagen)'
                                                : link,
                                            style: const TextStyle(
                                              color: Colors.blueAccent,
                                              decoration:
                                                  TextDecoration.underline,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.open_in_new,
                                          size: 14,
                                          color: Colors.blueAccent,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: _modoPaseDeLista
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: _finalizarClase,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primarioVerde,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Finalizar Clase y Enviar Reporte',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }
}
