// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/autenticacion_provider.dart';
import '../../providers/tutorias_provider.dart';
import '../../models/tutoria_model.dart';
import '../../core/utils/moderacion_servicio.dart';
import '../../services/pdf_servicio.dart';
import '../../models/usuario_model.dart';
import '../../core/theme/app_theme.dart';
import '../tutorias/chat_tutoria_view.dart';
import 'package:table_calendar/table_calendar.dart';

class MisTutoriasView extends StatefulWidget {
  final int initialIndex;
  final bool esSubpantalla;

  const MisTutoriasView({
    super.key,
    this.initialIndex = 0,
    this.esSubpantalla = false,
  });

  @override
  State<MisTutoriasView> createState() => _MisTutoriasViewState();
}

class _MisTutoriasViewState extends State<MisTutoriasView> {
  DateTime _diaSeleccionado = DateTime.now();
  DateTime _diaFocal = DateTime.now();
  CalendarFormat _formatoCalendario = CalendarFormat.month;

  List<TutoriaModel> _obtenerEventosParaElDia(
    DateTime dia,
    List<TutoriaModel> todas,
  ) {
    return todas
        .where(
          (t) =>
              t.fechaHoraSugerida.year == dia.year &&
              t.fechaHoraSugerida.month == dia.month &&
              t.fechaHoraSugerida.day == dia.day,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AutenticacionProvider>();
    final UsuarioModel? usuarioEnSesion = authProv.usuarioActual;

    if (usuarioEnSesion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String uid = usuarioEnSesion.identificadorUnico;

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialIndex,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: widget.esSubpantalla
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Volver',
                )
              : null,
          elevation: 0,

          foregroundColor: AppTheme.grisTexto,
          title: Text(
            'Comunidad de Aprendizaje',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  color: Color(0xFF1CA887),
                ),
                labelColor: Colors.white,
                unselectedLabelColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Calendario"),
                  Tab(text: "Próximas"),
                  Tab(text: "Historial"),
                ],
              ),
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('tutorias').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Error cargando historial de compromisos'),
              );
            }

            final universeDocs = snapshot.data?.docs ?? [];
            final universoTutorias = universeDocs
                .map(
                  (doc) =>
                      TutoriaModel.fromMap(doc.data() as Map<String, dynamic>),
                )
                .toList();

            // Filtrar tutorías del usuario donde ESTÁ INSCRITO COMO ALUMNO (o es su misma clase pero aquí importa el asistente base)
            // Ya que el panel del tutor administra las "Dictando", aquí daremos prioridad visual del asistente.
            final misTutoriasGlobales = universoTutorias
                .where(
                  (tuto) =>
                      tuto.listaDeEstudiantesInscritos.contains(uid) ||
                      tuto.identificadorDelTutor == uid,
                )
                .toList();

            // Clasificación
            final eventosDelDia = _obtenerEventosParaElDia(
              _diaSeleccionado,
              misTutoriasGlobales,
            );
            final proximasTutorias = misTutoriasGlobales
                .where(
                  (t) =>
                      t.estadoDeLaSolicitud != 'finalizada' &&
                      t.estadoDeLaSolicitud != 'cancelada',
                )
                .toList();
            final historialTutorias = misTutoriasGlobales
                .where(
                  (t) =>
                      t.estadoDeLaSolicitud == 'finalizada' ||
                      t.estadoDeLaSolicitud == 'cancelada',
                )
                .toList();

            return TabBarView(
              children: [
                // Tab 1: Calendario
                Column(
                  children: [
                    TableCalendar<TutoriaModel>(
                      firstDay: DateTime.utc(2023, 1, 1),
                      lastDay: DateTime.utc(2030, 31),
                      focusedDay: _diaFocal,
                      calendarFormat: _formatoCalendario,
                      selectedDayPredicate: (day) =>
                          isSameDay(_diaSeleccionado, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _diaSeleccionado = selectedDay;
                          _diaFocal = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        if (_formatoCalendario != format) {
                          setState(() {
                            _formatoCalendario = format;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _diaFocal = focusedDay;
                      },
                      eventLoader: (day) =>
                          _obtenerEventosParaElDia(day, misTutoriasGlobales),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.shade200,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: AppTheme.primarioAzul,
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: const BoxDecoration(
                          color: AppTheme.primarioVerde,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    Expanded(
                      child: _ModuloListaDeTutorias(
                        loteEspecifico: eventosDelDia,
                        uidActual: uid,
                        mensajeVacio:
                            'No hay tutorías agendadas para el día de este calendario.',
                      ),
                    ),
                  ],
                ),

                // Tab 2: Próximas Tutorías
                _ModuloListaDeTutorias(
                  loteEspecifico: proximasTutorias,
                  uidActual: uid,
                  mensajeVacio: 'No tienes nuevas tutorías activas por ahora.',
                ),

                // Tab 3: Historial y Evaluación
                _ModuloListaDeTutorias(
                  loteEspecifico: historialTutorias,
                  uidActual: uid,
                  mensajeVacio:
                      'No has asistido a ninguna tutoría en el pasado.',
                ),
              ],
            );
          },
        ),
        floatingActionButton:
            authProv.usuarioActual?.rolEnElSistema.toString() ==
                "RolSistema.tutor"
            ? FloatingActionButton.extended(
                heroTag: 'fab_mis_tutorias',
                onPressed: () => _mostrarDialogoCrearClaseFija(context, uid),
                icon: const Icon(Icons.add),
                label: const Text('Crear Clase Fija'),
                backgroundColor: AppTheme.primarioAzul,
                foregroundColor: Colors.white,
              )
            : null,
      ),
    );
  }

  Future<void> _mostrarDialogoCrearClaseFija(
    BuildContext context,
    String uidTutor,
  ) async {
    final formKey = GlobalKey<FormState>();
    final materiaController = TextEditingController();
    final temaController = TextEditingController();
    final cupoController = TextEditingController(text: "10");
    DateTime? fecha;
    TimeOfDay? hora;
    String modalidad = "Virtual";
    int semanasRepeticion = 1;

    final exito = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text(
            "Crear Clase Fija",
            style: TextStyle(color: AppTheme.primarioAzul),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: materiaController,
                    decoration: const InputDecoration(
                      labelText: "Materia",
                      filled: true,
                    ),
                    validator: (v) => v!.isEmpty ? "Requerido" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: temaController,
                    decoration: const InputDecoration(
                      labelText: "Tema",
                      filled: true,
                    ),
                    validator: (v) => v!.isEmpty ? "Requerido" : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: modalidad,
                    decoration: const InputDecoration(
                      labelText: "Modalidad",
                      filled: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Virtual",
                        child: Text("Virtual"),
                      ),
                      DropdownMenuItem(
                        value: "Presencial",
                        child: Text("Presencial"),
                      ),
                    ],
                    onChanged: (v) => setStateDialog(() => modalidad = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cupoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Cupo (Min 10)",
                      filled: true,
                    ),
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) < 1 ? "Error" : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 30),
                              ),
                            );
                            if (d != null) setStateDialog(() => fecha = d);
                          },
                          child: Text(
                            fecha == null
                                ? "Fecha"
                                : "${fecha!.day}/${fecha!.month}",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.now(),
                            );
                            if (t != null) setStateDialog(() => hora = t);
                          },
                          child: Text(
                            hora == null ? "Hora" : hora!.format(ctx),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: semanasRepeticion,
                    decoration: const InputDecoration(
                      labelText: "Repetición Semanal",
                      filled: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text("Solo 1 clase (Sin repetir)"),
                      ),
                      DropdownMenuItem(
                        value: 4,
                        child: Text("Mensual (4 semanas)"),
                      ),
                      DropdownMenuItem(
                        value: 8,
                        child: Text("Bimestral (8 semanas)"),
                      ),
                      DropdownMenuItem(
                        value: 16,
                        child: Text("Todo el Semestre (16 semanas)"),
                      ),
                    ],
                    onChanged: (v) =>
                        setStateDialog(() => semanasRepeticion = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: AppTheme.grisTexto),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primarioAzul,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate() &&
                    fecha != null &&
                    hora != null) {
                  final fechaFinal = DateTime(
                    fecha!.year,
                    fecha!.month,
                    fecha!.day,
                    hora!.hour,
                    hora!.minute,
                  );

                  int creadas = 0;
                  final prove = context.read<TutoriasProvider>();

                  for (int i = 0; i < semanasRepeticion; i++) {
                    final fechaIteracion = fechaFinal.add(
                      Duration(days: 7 * i),
                    );
                    final clasePlano = TutoriaModel(
                      identificadorDeTutoria: '',
                      materiaOAsignatura: materiaController.text,
                      temaEspecifico: temaController.text,
                      carrera: 'General',
                      identificadorDelTutor: uidTutor,
                      listaDeEstudiantesInscritos: [],
                      modalidadDeClase: modalidad,
                      estadoDeLaSolicitud: 'pendiente',
                      fechaHoraSugerida: fechaIteracion,
                      duracionMinutos: 60,
                      cupoMaximo: int.tryParse(cupoController.text) ?? 10,
                      esGrupal: true,
                    );

                    final ok = await prove.crearClaseFijaTutor(clasePlano);
                    if (ok) creadas++;
                  }

                  Navigator.pop(ctx, creadas > 0);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text("Completa y elige fecha/hora"),
                    ),
                  );
                }
              },
              child: const Text("Crear"),
            ),
          ],
        ),
      ),
    );

    if (exito == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Clase fija creada con éxito!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _ModuloListaDeTutorias extends StatelessWidget {
  final List<TutoriaModel> loteEspecifico;
  final String uidActual;
  final String mensajeVacio;

  const _ModuloListaDeTutorias({
    required this.loteEspecifico,
    required this.uidActual,
    this.mensajeVacio = 'No hay tutorías agendadas.',
  });

  @override
  Widget build(BuildContext context) {
    if (loteEspecifico.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_busy,
                  size: 64,
                  color: AppTheme.grisTexto,
                ),
                const SizedBox(height: 16),
                Text(
                  mensajeVacio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.grisTexto,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: loteEspecifico.length,
      itemBuilder: (context, index) {
        return _TarjetaDeCompromisoFlat(
          datos: loteEspecifico[index],
          uidActual: uidActual,
        );
      },
    );
  }
}

class _TarjetaDeCompromisoFlat extends StatelessWidget {
  final TutoriaModel datos;
  final String uidActual;

  const _TarjetaDeCompromisoFlat({
    required this.datos,
    required this.uidActual,
  });

  Color _extraerColorPorEstadoBase() {
    final estado = datos.estadoDeLaSolicitud.toLowerCase();
    if (estado == 'pendiente') return Colors.orangeAccent;
    if (estado == 'aceptada' || estado == 'abierta') return Colors.blueAccent;
    if (estado == 'finalizada') return Colors.greenAccent;
    if (estado == 'cancelada') return Colors.redAccent;
    return Colors.grey;
  }

  Future<void> _abrirEnlaceGenuino(BuildContext context) async {
    if (datos.enlaceOReunion == null || datos.enlaceOReunion!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El profesor aún no ha provisto un enlace para esta materia.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
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
        content: const Text(
          '¿Estás seguro que deseas dar por culminada la clase? Esta acción generará el cierre de horas oficiales en tu récord.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmarFin == true && context.mounted) {
      final proveedorNotificador = context.read<TutoriasProvider>();
      try {
        await FirebaseFirestore.instance
            .collection('tutorias')
            .doc(datos.identificadorDeTutoria)
            .update({
              'estadoDeLaSolicitud': 'finalizada',
              'horaFinReal': DateTime.now().toIso8601String(),
            });

        if (context.mounted) {
          await proveedorNotificador.cargarTutoriasSuscritasDelUsuario(
            uidActual,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '¡Tutoría finalizada! Horas oficiales dictadas actualizadas.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sucedió un error reportando la hora de fin a la Base de Datos.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelarTutoriaTutor(BuildContext context) async {
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
              if (ModeracionServicio.contieneLenguajeToxico(
                motivoCtrl.text.trim(),
              )) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Por favor, redacta un motivo sin lenguaje ofensivo.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Confirmar Cancelación'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      final proveedor = context.read<TutoriasProvider>();
      final autProvider = context.read<AutenticacionProvider>();
      final uidActual = autProvider.usuarioActual?.identificadorUnico;
      if (uidActual == null) return;

      bool exito = await proveedor.cancelarTutoriaComoTutor(
        datos.identificadorDeTutoria,
        motivoCtrl.text.trim(),
      );

      if (exito && context.mounted) {
        await proveedor.cargarTutoriasSuscritasDelUsuario(uidActual);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutoría cancelada exitosamente.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(proveedor.mensajeDeErrorDelSistema),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _abandonarTutoriaEstudiante(BuildContext context) async {
    final horasRestantes = datos.fechaHoraSugerida
        .difference(DateTime.now())
        .inHours;
    final esTarde = horasRestantes < 12;
    final excusaCtrl = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          esTarde ? 'Cancelación Tardía (< 12h)' : '¿Seguro que deseas salir?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: esTarde ? Colors.red : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              esTarde
                  ? 'Estás cancelando con menos de 12 horas de anticipación. Esto es una falta al reglamento. Debes proveer una justificación válida para el Tribunal de Disciplina o recibirás un Strike.'
                  : 'Perderás tu cupo en esta tutoría y la comunidad tendrá uno libre disponible.',
            ),
            if (esTarde) ...[
              const SizedBox(height: 16),
              TextField(
                controller: excusaCtrl,
                decoration: const InputDecoration(
                  labelText: "Motivo de fuerza mayor",
                  border: OutlineInputBorder(),
                  hintText: "Ej. Emergencia médica...",
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Conservar cupo',
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (esTarde && excusaCtrl.text.trim().isEmpty) {
                return; // Requiere texto
              }
              if (esTarde &&
                  ModeracionServicio.contieneLenguajeToxico(
                    excusaCtrl.text.trim(),
                  )) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Lenguaje inapropiado detectado. Por favor, sé respetuoso.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Sí, abandonar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      final proveedor = context.read<TutoriasProvider>();
      final excusa = esTarde ? excusaCtrl.text.trim() : null;

      bool exito = await proveedor.abandonarTutoria(
        datos.identificadorDeTutoria,
        excusa: excusa,
      );

      if (exito && context.mounted) {
        await proveedor.cargarTutoriasSuscritasDelUsuario(uidActual);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              esTarde
                  ? 'Has sido dado de baja. Tu excusa fue enviada al Tribunal.'
                  : 'Te has dado de baja exitosamente.',
            ),
            backgroundColor: esTarde ? Colors.orange.shade800 : Colors.black87,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(proveedor.mensajeDeErrorDelSistema),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _construirSelectorEstrellas(
    BuildContext context,
    Function(int) alTocar,
    int valorActual,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          return IconButton(
            icon: Icon(
              index < valorActual ? Icons.star : Icons.star_border,
              color: index < valorActual
                  ? AppTheme.primarioAzul
                  : Colors.grey.shade400,
              size: 32,
            ),
            onPressed: () => alTocar(index + 1),
          );
        }),
      ),
    );
  }

  Future<void> _mostrarDialogoDeEvaluacion(BuildContext context) async {
    int puntualidad = 0;
    int dominio = 0;
    int empatia = 0;
    List<String> etiquetasSeleccionadas = [];
    final TextEditingController ctrlComentario = TextEditingController();
    final TextEditingController ctrlComentarioPublico = TextEditingController();

    final List<String> etiquetasPositivas = [
      'Explica claro',
      'Paciente',
      'Buen material',
      'Dinámico',
    ];
    final List<String> etiquetasNegativas = [
      'Llegó tarde',
      'Poco preparado',
      'Difícil de entender',
      'Se desvió del tema',
    ];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (contextDialogo) {
        return StatefulBuilder(
          builder: (context, setEstadoInterno) {
            return Dialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Evaluar Tutoría',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Puntualidad y Compromiso',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _construirSelectorEstrellas(
                      context,
                      (v) => setEstadoInterno(() => puntualidad = v),
                      puntualidad,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Dominio del Tema',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _construirSelectorEstrellas(
                      context,
                      (v) => setEstadoInterno(() => dominio = v),
                      dominio,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Empatía y Paciencia',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _construirSelectorEstrellas(
                      context,
                      (v) => setEstadoInterno(() => empatia = v),
                      empatia,
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Etiquetas Rápidas',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...etiquetasPositivas.map(
                          (t) => FilterChip(
                            label: Text(
                              t,
                              style: TextStyle(
                                fontSize: 12,
                                color: etiquetasSeleccionadas.contains(t)
                                    ? Colors.white
                                    : Colors.green[800],
                              ),
                            ),
                            selected: etiquetasSeleccionadas.contains(t),
                            selectedColor: Colors.green,
                            backgroundColor: Colors.green.withValues(
                              alpha: 0.1,
                            ),
                            onSelected: (val) {
                              setEstadoInterno(() {
                                val
                                    ? etiquetasSeleccionadas.add(t)
                                    : etiquetasSeleccionadas.remove(t);
                              });
                            },
                          ),
                        ),
                        ...etiquetasNegativas.map(
                          (t) => FilterChip(
                            label: Text(
                              t,
                              style: TextStyle(
                                fontSize: 12,
                                color: etiquetasSeleccionadas.contains(t)
                                    ? Colors.white
                                    : Colors.red[800],
                              ),
                            ),
                            selected: etiquetasSeleccionadas.contains(t),
                            selectedColor: Colors.red,
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                            onSelected: (val) {
                              setEstadoInterno(() {
                                val
                                    ? etiquetasSeleccionadas.add(t)
                                    : etiquetasSeleccionadas.remove(t);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Comentario Confidencial para Admin:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      '(El tutor nunca verá este mensaje)',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctrlComentario,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Opcional. ¿Hubo algún problema grave?',
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Comentario para la Comunidad:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      '(Visible públicamente en el perfil del tutor)',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctrlComentarioPublico,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Opcional. Deja un comentario de agradecimiento.',
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(contextDialogo),
                          child: const Text(
                            'CANCELAR',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primarioAzul,
                          ),
                          onPressed:
                              (puntualidad == 0 || dominio == 0 || empatia == 0)
                              ? null
                              : () async {
                                  final double dPunt = puntualidad.toDouble();
                                  final double dDom = dominio.toDouble();
                                  final double dEmp = empatia.toDouble();

                                  final proveedorRef = context
                                      .read<TutoriasProvider>();
                                  bool exito = await proveedorRef
                                      .enviarEvaluacionTutoria(
                                        datos.identificadorDeTutoria,
                                        datos.identificadorDelTutor,
                                        dPunt,
                                        dDom,
                                        dEmp,
                                        etiquetasSeleccionadas,
                                        ctrlComentario.text.trim(),
                                        ctrlComentarioPublico.text.trim(),
                                      );

                                  if (contextDialogo.mounted) {
                                    Navigator.pop(contextDialogo);
                                  }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          exito
                                              ? '¡Evaluación dimensional guardada!'
                                              : proveedorRef
                                                    .mensajeDeErrorDelSistema,
                                        ),
                                        backgroundColor: exito
                                            ? Colors.green
                                            : Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                          child: const Text('ENVIAR'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    // Se remueven los dispose() para evitar la aserción de _dependents.isEmpty
  }

  void _abrirDetallesTutoria(BuildContext contextoPadre, bool esDictando) {
    showModalBottomSheet(
      context: contextoPadre,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    datos.materiaOAsignatura,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    datos.temaEspecifico,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(datos.lugar ?? "Lugar por definir"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(
                      datos.nombre_tutor ??
                          (datos.identificadorDelTutor.isEmpty
                              ? "Tutor por asignar"
                              : "Tutor Asignado"),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(datos.contacto_tutor ?? "Contacto no provisto"),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons inside bottom sheet
                  if (datos.estadoDeLaSolicitud.toLowerCase() != 'finalizada' &&
                      datos.estadoDeLaSolicitud.toLowerCase() != 'cancelada')
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1CA887),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          contextoPadre,
                          MaterialPageRoute(
                            builder: (_) => ChatTutoriaView(
                              tutoriaId: datos.identificadorDeTutoria,
                              materia: datos.materiaOAsignatura,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.forum),
                      label: const Text('Ingresar al Micro-Foro (Chat)'),
                    ),
                  const SizedBox(height: 8),

                  if (!esDictando &&
                      datos.enlaceOReunion != null &&
                      datos.estadoDeLaSolicitud.toLowerCase() != 'finalizada' &&
                      datos.estadoDeLaSolicitud.toLowerCase() != 'cancelada')
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _abrirEnlaceGenuino(contextoPadre);
                      },
                      icon: const Icon(Icons.link),
                      label: const Text(
                        'Entrar a la clase virtual / Ver enlace',
                      ),
                    ),

                  if (!esDictando &&
                      datos.estadoDeLaSolicitud.toLowerCase() == 'finalizada')
                    (datos.registro_asistencia != null &&
                            datos.registro_asistencia![uidActual] == false)
                        ? const Center(
                            child: Text(
                              'No asisiste a esta sesión. Sin evaluación ni constancia.',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Botón de Constancia (Solo si la asistencia está explícitamente en true)
                              if (datos.registro_asistencia != null &&
                                  datos.registro_asistencia![uidActual] == true)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                    ),
                                    onPressed: () async {
                                      final proveedorUsuarios = contextoPadre
                                          .read<AutenticacionProvider>();
                                      final tutorSnapshot =
                                          await FirebaseFirestore.instance
                                              .collection('usuarios')
                                              .doc(datos.identificadorDelTutor)
                                              .get();
                                      String nombreTutor =
                                          tutorSnapshot
                                              .data()?['nombreCompleto'] ??
                                          'Tutor';

                                      await PdfServicio.generarCertificadoAsistencia(
                                        estudiante:
                                            proveedorUsuarios.usuarioActual!,
                                        tutoria: datos,
                                        tutorNombre: nombreTutor,
                                      );
                                    },
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text(
                                      'Descargar Certificado PDF',
                                    ),
                                  ),
                                ),

                              // Botón de Evaluar
                              datos.alumnosQueYaEvaluaron.contains(uidActual)
                                  ? const Center(
                                      child: Text(
                                        'Ya evaluaste esta sesión.',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : FilledButton.icon(
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                        _mostrarDialogoDeEvaluacion(
                                          contextoPadre,
                                        );
                                      },
                                      icon: const Icon(Icons.rate_review),
                                      label: const Text('Evaluar Sesión'),
                                    ),
                            ],
                          ),

                  if (esDictando &&
                      (datos.estadoDeLaSolicitud.toLowerCase() == 'aceptada' ||
                          datos.estadoDeLaSolicitud.toLowerCase() == 'abierta'))
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _culminarTutoriaDada(contextoPadre);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Dar por Culminada'),
                    ),

                  if (esDictando &&
                      datos.estadoDeLaSolicitud.toLowerCase() != 'finalizada' &&
                      datos.estadoDeLaSolicitud.toLowerCase() != 'cancelada')
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _cancelarTutoriaTutor(contextoPadre);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar Tutoría'),
                    ),

                  if (!esDictando &&
                      datos.estadoDeLaSolicitud.toLowerCase() != 'finalizada' &&
                      datos.estadoDeLaSolicitud.toLowerCase() != 'cancelada')
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _abandonarTutoriaEstudiante(contextoPadre);
                      },
                      child: const Text('Abandonar Clase'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final esDictando = datos.identificadorDelTutor == uidActual;
    final colorDeEstado = _extraerColorPorEstadoBase();
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    final colorSubtexto = esOscuro ? Colors.grey[400] : Colors.grey.shade600;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: esOscuro ? Colors.grey[700]! : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  esDictando ? Icons.co_present : Icons.videocam,
                  color: const Color(0xFF1CA887),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    datos.materiaOAsignatura.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorTexto,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorDeEstado.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    datos.estadoDeLaSolicitud.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorDeEstado,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              datos.temaEspecifico,
              style: TextStyle(color: colorSubtexto),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${datos.fechaHoraSugerida.hour.toString().padLeft(2, '0')}:${datos.fechaHoraSugerida.minute.toString().padLeft(2, '0')} Hrs - ${datos.fechaHoraSugerida.day.toString().padLeft(2, '0')}/${datos.fechaHoraSugerida.month.toString().padLeft(2, '0')}',
                    style: TextStyle(color: colorTexto),
                  ),
                ),
                const Icon(
                  Icons.hourglass_bottom,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${datos.duracionMinutos} min',
                  style: TextStyle(
                    color: colorTexto,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (datos.estadoDeLaSolicitud.toLowerCase() != 'finalizada' &&
                datos.estadoDeLaSolicitud.toLowerCase() != 'cancelada') ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    datos.lugar ?? datos.modalidadDeClase,
                    style: TextStyle(color: colorTexto),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Contacto: ${datos.contacto_tutor ?? 'No provisto'}',
                    style: TextStyle(color: colorTexto),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _abrirDetallesTutoria(context, esDictando),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1CA887),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Ver Detalles'),
                  ),
                ),
                if (!esDictando &&
                    datos.estadoDeLaSolicitud.toLowerCase() != 'finalizada' &&
                    datos.estadoDeLaSolicitud.toLowerCase() != 'cancelada') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _abandonarTutoriaEstudiante(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: esOscuro ? Colors.grey[800] : Colors.grey.shade200,
                        foregroundColor: colorTexto,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              ],
            ),
            if (!esDictando &&
                datos.estadoDeLaSolicitud.toLowerCase() == 'finalizada' &&
                !datos.alumnosQueYaEvaluaron.contains(uidActual) &&
                (datos.registro_asistencia == null ||
                    datos.registro_asistencia![uidActual] != false))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _mostrarDialogoDeEvaluacion(context),
                    icon: const Icon(Icons.star_rate, size: 16),
                    label: const Text(
                      'Calificar Tutoría',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
