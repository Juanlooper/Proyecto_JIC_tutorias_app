// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/tutorias_provider.dart';
import '../../models/tutoria_model.dart';
import '../../core/utils/moderacion_servicio.dart';

class SugerirTutoriaView extends StatefulWidget {
  const SugerirTutoriaView({super.key});

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

  bool _estaCargando = false;
  String? _archivoSubidoUrl;
  String? _archivoSubidoNombre;

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
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
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
    if (hora != null && hora != _horaSeleccionada) {
      setState(() {
        _horaSeleccionada = hora;
      });
    }
  }

  // --- LOGICA DE ENVIO AL BACKEND ---

  Future<void> _enviarSugerencia() async {
    if (!_formKey.currentState!.validate()) return;

    if (ModeracionServicio.contieneLenguajeToxico(_materiaController.text) || 
        ModeracionServicio.contieneLenguajeToxico(_motivosController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El texto ingresado contiene lenguaje inapropiado u ofensivo. Por favor, corrígelo antes de enviar."),
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

    setState(() {
      _estaCargando = true;
    });

    // Combinar Date y Time en un solo DateTime consolidado
    final DateTime fechaHoraFinal = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );

    final uidLocal = FirebaseAuth.instance.currentUser?.uid ?? 'anonimo';
    final enlacesOpcionales = _archivoSubidoUrl != null
        ? {
            uidLocal: [_archivoSubidoUrl!],
          }
        : null;
    final nombresOpcionales = _archivoSubidoNombre != null
        ? {
            uidLocal: [_archivoSubidoNombre!],
          }
        : null;

    final materiaFinal = _materiaSeleccionada == 'Otros'
        ? _materiaController.text.trim()
        : _materiaSeleccionada;

    // Creamos el cascarón de la sugerencia (la id la inyectará el Provider o Firebase)
    TutoriaModel sugerenciaCruda = TutoriaModel(
      identificadorDeTutoria: '',
      materiaOAsignatura: materiaFinal,
      temaEspecifico: _motivosController.text.trim(),
      carrera: 'General / No Especificada', // Ajustable según necesidad futuura
      identificadorDelTutor: '', // CRÍTICO: Regla fundamental de la bolsa
      listaDeEstudiantesInscritos: [], // El provider ingresará el UID propio
      modalidadDeClase: _modalidadSeleccionada,
      estadoDeLaSolicitud: 'solicitada',
      fechaHoraSugerida: fechaHoraFinal,
      cupoMaximo: 1, // El tutor determinará el cupo al aceptarla
      duracionMinutos: 60,
      esGrupal: false,
      enlaces_adjuntos: enlacesOpcionales,
      nombres_adjuntos: nombresOpcionales,
    );

    final provider = Provider.of<TutoriasProvider>(context, listen: false);
    bool exito = await provider.crearSolicitudHuerfana(sugerenciaCruda);

    setState(() {
      _estaCargando = false;
    });

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Solicitud enviada a la bolsa exitosamente."),
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
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFF6C63FF),
                        size: 36,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "¿No encuentras lo que buscas?\nSugiere un tema y dejaremos que la bolsa busque un profesor por ti.",
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
