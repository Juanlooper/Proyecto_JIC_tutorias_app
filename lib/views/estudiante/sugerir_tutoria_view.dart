// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tutorias_provider.dart';
import '../../models/tutoria_model.dart';
import '../../core/utils/moderacion_servicio.dart';
import '../widgets/overlay_loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/usuario_model.dart';

class SugerirTutoriaView extends StatefulWidget {
  final String? tutorDestino;
  const SugerirTutoriaView({super.key, this.tutorDestino});

  @override
  State<SugerirTutoriaView> createState() => _SugerirTutoriaViewState();
}

class _SugerirTutoriaViewState extends State<SugerirTutoriaView> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto para capturar los datos
  final TextEditingController _materiaController = TextEditingController();
  final TextEditingController _motivosController = TextEditingController();

  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  String _modalidadSeleccionada = 'Virtual';

  final List<String> _materiasPredeterminadas = [
    'CÁLCULO I',
    'CÁLCULO II',
    'CÁLCULO III',
    'QUÍMICA I',
    'DIBUJO I',
    'DESARROLLO LÓGICO Y ALGORÍTMOS',
    'FÍSICA I (MECÁNICA)',
    'FÍSICA II (ELECTRICIDAD Y MAGNETISMO)',
    'ESTÁTICA',
    'DINÁMICA',
    'Otros',
  ];
  String _materiaSeleccionada = 'CÁLCULO I';

  final bool _estaCargando = false;

  // --- VARIABLES PARA SELECCIÓN OPCIONAL DE TUTOR ---
  /// Lista que almacenará a los tutores descargados de Firestore.
  List<UsuarioModel> tutoresDisponiblesRegistrados = [];

  /// Objeto que contendrá al tutor si el usuario decide seleccionarlo.
  UsuarioModel? tutorSeleccionadoOpcionalmente;

  @override
  void initState() {
    super.initState();
    // Invocamos la consulta asíncrona solo si no hay un tutor destino predefinido
    if (widget.tutorDestino == null || widget.tutorDestino!.isEmpty) {
      cargarListadoDeTutoresDesdeFirestore();
    }
  }

  /// Consulta asíncrona a Firestore para listar usuarios con el rol específico.
  Future<void> cargarListadoDeTutoresDesdeFirestore() async {
    try {
      // Realizamos la consulta a la colección usuarios filtrando por el rol 'tutor'
      final snapshotTutores = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rolEnElSistema', isEqualTo: 'tutor')
          .get();

      // Mapeamos los documentos utilizando el constructor de fábrica a objetos fuertemente tipados
      final tutoresExtraidos = snapshotTutores.docs
          .map((doc) => UsuarioModel.fromMap(doc.data()))
          .toList();

      // Actualizamos el estado de manera segura para reflejar los datos en la UI (Dropdown)
      if (mounted) {
        setState(() {
          tutoresDisponiblesRegistrados = tutoresExtraidos;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar tutores: $e");
    }
  }

  @override
  void dispose() {
    _materiaController.dispose();
    _motivosController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE SELECTORES ---

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF), // Color temático acento
            ),
          ),
          child: child!,
        );
      },
    );
    if (fecha != null && fecha != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _seleccionarHora(BuildContext context) async {
    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, selecciona una fecha primero."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final diasMap = {
      1: 'Lunes',
      2: 'Martes',
      3: 'Miércoles',
      4: 'Jueves',
      5: 'Viernes',
      6: 'Sábado',
      7: 'Domingo',
    };
    final String diaSugerido = diasMap[_fechaSeleccionada!.weekday]!;

    OverlayLoader.mostrar(context, mensaje: "Consultando disponibilidad...");

    List<String> horasDisponiblesDelTutor = [];
    List<String> horasOcupadas = [];

    try {
      final String idTutorAConsultar =
          (widget.tutorDestino != null && widget.tutorDestino!.isNotEmpty)
          ? widget.tutorDestino!
          : tutorSeleccionadoOpcionalmente?.identificadorUnico ?? '';

      if (idTutorAConsultar.isNotEmpty) {
        // 1. Obtener el horario del tutor seleccionado
        final tutorDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(idTutorAConsultar)
            .get();

        if (tutorDoc.exists) {
          final data = tutorDoc.data()!;
          final horarioDisponibilidad =
              data['horarioDisponibilidad'] as Map<String, dynamic>?;
          if (horarioDisponibilidad != null &&
              horarioDisponibilidad[diaSugerido] != null) {
            horasDisponiblesDelTutor = List<String>.from(
              horarioDisponibilidad[diaSugerido],
            );
          } else {
            // El tutor no trabaja este día
            OverlayLoader.ocultar(context);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "El tutor seleccionado no ofrece tutorías los $diaSugerido.",
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
            return;
          }
        }

        // 2. Obtener clases que ya estén ocupadas en esa fecha exacta para evitar superposiciones
        final tutoriasSnapshot = await FirebaseFirestore.instance
            .collection('tutorias')
            .where('identificadorDelTutor', isEqualTo: idTutorAConsultar)
            .get();

        final inicioDia = DateTime(
          _fechaSeleccionada!.year,
          _fechaSeleccionada!.month,
          _fechaSeleccionada!.day,
        );
        final finDia = inicioDia.add(const Duration(days: 1));

        for (var doc in tutoriasSnapshot.docs) {
          final data = doc.data();
          final estado = data['estadoDeLaSolicitud'] as String?;
          if (estado == 'aceptada' ||
              estado == 'pendiente' ||
              estado == 'sugerida_directa') {
            final fechaClase = (data['fechaHoraSugerida'] as Timestamp)
                .toDate();
            // Filtro de fecha local
            if (fechaClase.isAfter(
                  inicioDia.subtract(const Duration(seconds: 1)),
                ) &&
                fechaClase.isBefore(finDia)) {
              final String horaString =
                  '${fechaClase.hour.toString().padLeft(2, '0')}:00';
              horasOcupadas.add(horaString);
            }
          }
        }
      } else {
        // Si no es un tutor en específico, mostramos todas las horas desde las 07:00 a 21:00
        horasDisponiblesDelTutor = List.generate(
          15,
          (index) => '${(index + 7).toString().padLeft(2, '0')}:00',
        );
      }
    } catch (e) {
      // Error de red o base de datos
      OverlayLoader.ocultar(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al consultar disponibilidad: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    OverlayLoader.ocultar(context);

    if (mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (contextBottomSheet) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Seleccionar Hora',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.tutorDestino != null
                      ? 'Disponibilidad del tutor para el $diaSugerido'
                      : 'Selecciona una hora en punto',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: horasDisponiblesDelTutor.map((horaString) {
                    final bool ocupada = horasOcupadas.contains(horaString);
                    return InkWell(
                      onTap: ocupada
                          ? null
                          : () {
                              final partes = horaString.split(':');
                              setState(() {
                                _horaSeleccionada = TimeOfDay(
                                  hour: int.parse(partes[0]),
                                  minute: int.parse(partes[1]),
                                );
                              });
                              Navigator.pop(contextBottomSheet);
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: ocupada
                              ? Colors.grey.shade200
                              : const Color(0xFF6C63FF).withValues(alpha: 0.1),
                          border: Border.all(
                            color: ocupada
                                ? Colors.grey.shade400
                                : const Color(0xFF6C63FF),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          horaString,
                          style: TextStyle(
                            color: ocupada
                                ? Colors.grey.shade500
                                : const Color(0xFF6C63FF),
                            fontWeight: FontWeight.bold,
                            decoration: ocupada
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  // --- LOGICA DE ENVIO AL BACKEND ---

  Future<void> _enviarSugerencia() async {
    if (!_formKey.currentState!.validate()) return;

    if (ModeracionServicio.contieneLenguajeToxico(_materiaController.text) ||
        ModeracionServicio.contieneLenguajeToxico(_motivosController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "El texto ingresado contiene lenguaje inapropiado u ofensivo. Por favor, corrígelo antes de enviar.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_fechaSeleccionada == null || _horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, selecciona una fecha y una hora."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    OverlayLoader.mostrar(context, mensaje: 'Procesando tu solicitud...');

    // Combinar Date y Time en un solo DateTime consolidado
    final DateTime fechaHoraFinal = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );

    final materiaFinal = _materiaSeleccionada == 'Otros'
        ? _materiaController.text.trim()
        : _materiaSeleccionada;

    // Creamos el cascarón de la sugerencia (la id la inyectará el Provider o Firebase)
    // Evaluamos dinámicamente si es una sugerencia directa basándonos en si hay tutor
    bool esDirecta =
        widget.tutorDestino != null || tutorSeleccionadoOpcionalmente != null;

    // Evaluamos el identificador del tutor cumpliendo las instrucciones estrictas
    final String idTutorFinal =
        (widget.tutorDestino != null && widget.tutorDestino!.isNotEmpty)
        ? widget.tutorDestino!
        : tutorSeleccionadoOpcionalmente?.identificadorUnico ?? '';

    TutoriaModel sugerenciaCruda = TutoriaModel(
      identificadorDeTutoria: '',
      materiaOAsignatura: materiaFinal,
      temaEspecifico: _motivosController.text.trim(),
      carrera: 'General / No Especificada', // Ajustable según necesidad futura
      identificadorDelTutor:
          idTutorFinal, // CRÍTICO: Utiliza el id dinámico evaluado arriba
      listaDeEstudiantesInscritos: [], // El provider ingresará el UID propio
      modalidadDeClase: _modalidadSeleccionada,
      estadoDeLaSolicitud: esDirecta ? 'sugerida_directa' : 'solicitada',
      fechaHoraSugerida: fechaHoraFinal,
      cupoMaximo: 1, // El tutor determinará el cupo al aceptarla
      duracionMinutos: 60,
      esGrupal: false,
    );

    final provider = Provider.of<TutoriasProvider>(context, listen: false);
    bool exito = await provider.crearSolicitudHuerfana(sugerenciaCruda);

    OverlayLoader.ocultar(context);

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esDirecta
                ? "✅ Sugerencia directa enviada."
                : "✅ Solicitud enviada a la bolsa exitosamente.",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${provider.mensajeDeErrorDelSistema}"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- INTERFAZ GRÁFICA (UI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(),
        centerTitle: true,
        title: const Text(
          "Sugerir Tutoría",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera Descriptiva Elegante
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFF6C63FF),
                        size: 36,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.tutorDestino != null
                              ? "Estás sugiriendo una clase directa a un tutor específico. Él podrá aceptarla o rechazarla."
                              : "¿No encuentras lo que buscas?\nSugiere un tema y dejaremos que la bolsa busque un profesor por ti.",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Campo: Materia
                _construirLabel("Asignatura para la cual solicita tutoría"),
                DropdownButtonFormField<String>(
                  initialValue: _materiaSeleccionada,
                  isExpanded: true,
                  decoration: _estiloCajaFluida(
                    hint: "",
                    icono: Icons.book_rounded,
                  ),
                  items: _materiasPredeterminadas.map((String materia) {
                    return DropdownMenuItem<String>(
                      value: materia,
                      child: Text(
                        materia,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _materiaSeleccionada = val;
                        if (val != 'Otros') {
                          _materiaController.clear();
                        }
                      });
                    }
                  },
                ),
                if (_materiaSeleccionada == 'Otros') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _materiaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _estiloCajaFluida(
                      hint: "Escribe el nombre de la materia...",
                      icono: Icons.edit_rounded,
                    ),
                    validator: (value) =>
                        _materiaSeleccionada == 'Otros' &&
                            (value == null || value.trim().isEmpty)
                        ? "Debes escribir la materia."
                        : null,
                  ),
                ],
                const SizedBox(height: 24),

                // Campo: Modalidad
                _construirLabel("Modalidad preferida"),
                DropdownButtonFormField<String>(
                  initialValue: _modalidadSeleccionada,
                  decoration: _estiloCajaFluida(
                    hint: "",
                    icono: Icons.location_on_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Virtual', child: Text('Virtual')),
                    DropdownMenuItem(
                      value: 'Presencial',
                      child: Text('Presencial'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _modalidadSeleccionada = val);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Campo Inyectado: Asignación Opcional de Tutor
                if (widget.tutorDestino == null ||
                    widget.tutorDestino!.isEmpty) ...[
                  _construirLabel("Asignar un Tutor específico (Opcional)"),
                  DropdownButtonFormField<UsuarioModel>(
                    initialValue: tutorSeleccionadoOpcionalmente,
                    decoration: _estiloCajaFluida(
                      hint: "Cualquiera (Bolsa pública)",
                      icono: Icons.person_search_rounded,
                    ),
                    items: [
                      // Elemento nulo que representa la bolsa abierta (Cualquier tutor)
                      const DropdownMenuItem<UsuarioModel>(
                        value: null,
                        child: Text(
                          "Cualquier tutor disponible (Recomendado)",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Iteramos la lista asíncrona para construir las opciones
                      ...tutoresDisponiblesRegistrados.map((
                        UsuarioModel tutor,
                      ) {
                        return DropdownMenuItem<UsuarioModel>(
                          value: tutor,
                          child: Text(
                            tutor.nombreCompleto,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (UsuarioModel? seleccionado) {
                      setState(() {
                        tutorSeleccionadoOpcionalmente = seleccionado;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Fila: Día y Hora (Widgets Clickables)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _construirLabel("Día sugerido"),
                          GestureDetector(
                            onTap: () => _seleccionarFecha(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 16,
                              ),
                              decoration: _decoracionSimuladaCaja(),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    color: Color(0xFF6C63FF),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _fechaSeleccionada == null
                                          ? "Seleccionar"
                                          : "${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaSeleccionada!.month.toString().padLeft(2, '0')}/${_fechaSeleccionada!.year}",
                                      style: TextStyle(
                                        color: _fechaSeleccionada == null
                                            ? Colors.grey[500]
                                            : Colors.black87,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _construirLabel("Hora sugerida"),
                          GestureDetector(
                            onTap: () => _seleccionarHora(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 16,
                              ),
                              decoration: _decoracionSimuladaCaja(),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: Color(0xFF6C63FF),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _horaSeleccionada == null
                                          ? "Seleccionar"
                                          : _horaSeleccionada!.format(context),
                                      style: TextStyle(
                                        color: _horaSeleccionada == null
                                            ? Colors.grey[500]
                                            : Colors.black87,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Campo: Motivos / Tema Específico
                _construirLabel("¿Qué tema específico necesitas repasar?"),
                TextFormField(
                  controller: _motivosController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _estiloCajaFluida(
                    hint:
                        "Ej. Necesito comprender la regla de la cadena para el parcial del viernes...",
                  ),
                  validator: (value) => value == null || value.trim().length < 5
                      ? "Debes detallar un poco más lo que necesitas."
                      : null,
                ),
                const SizedBox(height: 24),

                const SizedBox(height: 32),

                // Botón Gigante (Call to Action)
                ElevatedButton(
                  onPressed: _estaCargando ? null : _enviarSugerencia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 5,
                    shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _estaCargando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          "Sugerir Tutoría a la Bolsa",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Botón de Cancelar / Descartar (HCI: Control y Libertad)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  label: const Text(
                    "Descartar Solicitud",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- COMPONENTES AUXILIARES DE ESTILIZADO ---

  Widget _construirLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  InputDecoration _estiloCajaFluida({required String hint, IconData? icono}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: icono != null
          ? Icon(icono, color: const Color(0xFF6C63FF), size: 22)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  BoxDecoration _decoracionSimuladaCaja() {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
    );
  }
}
