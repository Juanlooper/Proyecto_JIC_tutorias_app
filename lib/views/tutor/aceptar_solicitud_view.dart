import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tutoria_model.dart';
import '../../providers/tutorias_provider.dart';
import '../../providers/autenticacion_provider.dart';
import '../../core/theme/app_theme.dart';

class AceptarSolicitudView extends StatefulWidget {
  final TutoriaModel tutoria;

  const AceptarSolicitudView({Key? key, required this.tutoria}) : super(key: key);

  @override
  State<AceptarSolicitudView> createState() => _AceptarSolicitudViewState();
}

class _AceptarSolicitudViewState extends State<AceptarSolicitudView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _materiaController = TextEditingController();
  final TextEditingController _temaController = TextEditingController();
  final TextEditingController _cupoController = TextEditingController();
  final TextEditingController _duracionController = TextEditingController();
  final TextEditingController _lugarController = TextEditingController();
  final TextEditingController _contactoController = TextEditingController();

  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  String _modalidadSeleccionada = 'Virtual';

  bool _estaGuardando = false;

  @override
  void initState() {
    super.initState();
    _materiaController.text = widget.tutoria.materiaOAsignatura;
    _temaController.text = widget.tutoria.temaEspecifico;
    _cupoController.text = widget.tutoria.cupoMaximo.toString();
    _duracionController.text = widget.tutoria.duracionMinutos.toString();
    
    // Si la modalidad era "Por definirse", usar un default válido
    _modalidadSeleccionada = widget.tutoria.modalidadDeClase == 'Por definirse' 
        ? 'Virtual' : widget.tutoria.modalidadDeClase;

    _fechaSeleccionada = widget.tutoria.fechaHoraSugerida;
    _horaSeleccionada = TimeOfDay.fromDateTime(widget.tutoria.fechaHoraSugerida);
  }

  @override
  void dispose() {
    _materiaController.dispose();
    _temaController.dispose();
    _cupoController.dispose();
    _duracionController.dispose();
    _lugarController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (fechaElegida != null) {
      setState(() {
        _fechaSeleccionada = fechaElegida;
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final TimeOfDay? horaElegida = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? TimeOfDay.now(),
    );
    if (horaElegida != null) {
      setState(() {
        _horaSeleccionada = horaElegida;
      });
    }
  }

  Future<void> _aceptarClase() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaSeleccionada == null || _horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fecha y hora'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() {
      _estaGuardando = true;
    });

    final String lugar = _lugarController.text.trim();
    final String contacto = _contactoController.text.trim();
    final int cupo = int.tryParse(_cupoController.text.trim()) ?? 1;
    final int duracion = int.tryParse(_duracionController.text.trim()) ?? 60;
    
    final DateTime fechaHoraFinal = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );

    final proveedor = Provider.of<TutoriasProvider>(context, listen: false);
    final authProv = Provider.of<AutenticacionProvider>(context, listen: false);
    
    final String nombreTutor = authProv.usuarioActual?.nombreCompleto ?? 'Tutor(a) Asignado(a)';

    TutoriaModel modeloAEnviar = widget.tutoria.copyWith(
      materiaOAsignatura: _materiaController.text.trim(),
      temaEspecifico: _temaController.text.trim(),
      fechaHoraSugerida: fechaHoraFinal,
      cupoMaximo: cupo,
      duracionMinutos: duracion,
      modalidadDeClase: _modalidadSeleccionada,
      lugar: lugar,
      contacto_tutor: contacto,
      nombre_tutor: nombreTutor,
    );

    bool exito = await proveedor.aceptarSolicitudSugerida(modeloAEnviar);

    setState(() {
      _estaGuardando = false;
    });

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Has aceptado la tutoría con éxito!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Regresa al Dashboard del Tutor
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(proveedor.mensajeDeErrorDelSistema),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Preparación de datos visuales
    final fecha = widget.tutoria.fechaHoraSugerida;
    final diaFormateado = "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
    final TimeOfDay horaVisual = TimeOfDay(hour: fecha.hour, minute: fecha.minute);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC), // Blanco azulado moderno
      appBar: AppBar(
        title: const Text(
          "Configurar Sesión",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- SECCIÓN 1: DETALLES DE LA SOLICITUD ---
              const Text(
                "Detalles de la Petición",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.class_rounded, color: AppTheme.primarioAzul),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.tutoria.materiaOAsignatura,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        const Icon(Icons.event_outlined, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(diaFormateado, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        const Icon(Icons.access_time_rounded, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(horaVisual.format(context), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text("Apoyan esta clase: ", style: TextStyle(fontSize: 14, color: Colors.black54)),
                        Text("${widget.tutoria.estudiantesApoyando.length}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primarioVerde)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<DocumentSnapshot>(
                      future: widget.tutoria.creador != null && widget.tutoria.creador!.isNotEmpty 
                            ? FirebaseFirestore.instance.collection('usuarios').doc(widget.tutoria.creador).get()
                            : null,
                      builder: (context, snapshot) {
                        String nombreCreador = "Desconocido";
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          nombreCreador = "Cargando...";
                        } else if (snapshot.hasData && snapshot.data!.exists) {
                          nombreCreador = snapshot.data!['nombreCompleto'] ?? "Sin nombre";
                        }
                        
                        return Row(
                          children: [
                            const Icon(Icons.person_pin, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text("Sugerido por: ", style: TextStyle(fontSize: 14, color: Colors.black54)),
                            Expanded(child: Text(nombreCreador, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                          ],
                        );
                      }
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- SECCIÓN NUEVA: EDICIÓN DE FORMULARIO ---
              const Text(
                "Detallar la Sesión",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _materiaController,
                      decoration: _decoracionCampo('Materia', Icons.book),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _temaController,
                      maxLines: 3,
                      decoration: _decoracionCampo('Tema Específico', Icons.subject),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _modalidadSeleccionada,
                      decoration: _decoracionCampo('Modalidad', Icons.computer),
                      items: const [
                        DropdownMenuItem(value: 'Virtual', child: Text('Virtual')),
                        DropdownMenuItem(value: 'Presencial', child: Text('Presencial')),
                      ],
                      onChanged: (val) {
                        setState(() => _modalidadSeleccionada = val!);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cupoController,
                            keyboardType: TextInputType.number,
                            decoration: _decoracionCampo('Cupo Máximo', Icons.group),
                            validator: (v) => v!.isEmpty ? 'Req' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _duracionController,
                            keyboardType: TextInputType.number,
                            decoration: _decoracionCampo('Minutos', Icons.timer),
                            validator: (v) => v!.isEmpty ? 'Req' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300)
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _fechaSeleccionada == null ? 'Sin fecha' : '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}',
                                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300)
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _horaSeleccionada == null ? 'Sin hora' : _horaSeleccionada!.format(context),
                                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Lugar y Contacto",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // CAMPO: LUGAR
                    TextFormField(
                      controller: _lugarController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: "Ubicación de la tutoría",
                        hintText: "Ej. Biblioteca, Salón 302, Google Meet...",
                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primarioAzul),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primarioAzul, width: 2)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Debes definir en dónde será la clase.";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // CAMPO: CONTACTO
                    TextFormField(
                      controller: _contactoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Método de contacto",
                        hintText: "Tu Correo Institucional o número de WhatsApp",
                        prefixIcon: const Icon(Icons.contact_mail_outlined, color: AppTheme.primarioAzul),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primarioAzul, width: 2)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Deja un método para que los alumnos te contacten.";
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // --- SECCIÓN 3: BOTÓN DE PROCEDER ---
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _estaGuardando ? null : _aceptarClase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primarioVerde, // Verde para reafirmar aceptación
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppTheme.primarioVerde.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _estaGuardando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text(
                          "Aceptar Tutoría",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracionCampo(String etiqueta, IconData icono) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono, color: AppTheme.primarioAzul),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primarioAzul, width: 2)),
    );
  }
}
