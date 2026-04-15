import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/autenticacion_provider.dart';
import '../../providers/tutorias_provider.dart';
import '../../models/tutoria_model.dart';
import '../../models/usuario_model.dart';
import '../../core/theme/app_theme.dart';

class CrearTutoriaView extends StatefulWidget {
  const CrearTutoriaView({super.key});

  @override
  State<CrearTutoriaView> createState() => _CrearTutoriaViewState();
}

class _CrearTutoriaViewState extends State<CrearTutoriaView> {
  final _formKey = GlobalKey<FormState>();

  final _materiaController = TextEditingController();
  final _temaController = TextEditingController();
  final _cupoController = TextEditingController(text: '1');
  final _duracionController = TextEditingController(text: '60');

  String _modalidadSeleccionada = 'Virtual';
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;

  @override
  void dispose() {
    _materiaController.dispose();
    _temaController.dispose();
    _cupoController.dispose();
    _duracionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primarioAzul,
              onPrimary: Colors.white,
              onSurface: AppTheme.textoOscuro,
            ),
          ),
          child: child!,
        );
      },
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
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primarioAzul,
            ),
          ),
          child: child!,
        );
      },
    );
    if (horaElegida != null) {
      setState(() {
        _horaSeleccionada = horaElegida;
      });
    }
  }

  Future<void> _confirmarYSubirTutoria(UsuarioModel usuarioCreador) async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaSeleccionada == null || _horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, selecciona tanto la fecha como la hora sugerida.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final DateTime fechaHoraFinalSugerida = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );

    final String identificadorUnico = DateTime.now().millisecondsSinceEpoch
        .toString();
    final int cuposElegidos = int.tryParse(_cupoController.text) ?? 1;
    final int minutosDuracion = int.tryParse(_duracionController.text) ?? 60;

    final TutoriaModel miModelo = TutoriaModel(
      identificadorDeTutoria: identificadorUnico,
      materiaOAsignatura: _materiaController.text.trim(),
      temaEspecifico: _temaController.text.trim(),
      carrera: usuarioCreador.carrera ?? 'General',
      identificadorDelTutor: '',
      listaDeEstudiantesInscritos: [usuarioCreador.identificadorUnico],
      modalidadDeClase: _modalidadSeleccionada,
      estadoDeLaSolicitud: 'pendiente',
      fechaHoraSugerida: fechaHoraFinalSugerida,
      cupoMaximo: cuposElegidos,
      duracionMinutos: minutosDuracion,
      esGrupal: cuposElegidos > 1,
    );

    final proveedorTutorias = context.read<TutoriasProvider>();
    final operacionExitosa = await proveedorTutorias
        .crearAperturaDeNuevaTutoria(planoFormateadoDelExamen: miModelo);

    if (mounted) {
      if (operacionExitosa) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud publicada exitosamente.'),
            backgroundColor: AppTheme.primarioVerde,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(proveedorTutorias.mensajeDeErrorDelSistema),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proveedorAutenticacion = context.read<AutenticacionProvider>();
    final perfilValido = proveedorAutenticacion.perfilCompleto;

    // Pantalla de bloqueo por perfil incompleto
    if (!perfilValido) {
      return Scaffold(
        backgroundColor: AppTheme.fondoClaro,
        appBar: AppBar(
          title: const Text(
            'Acceso Restringido',
            style: TextStyle(color: AppTheme.primarioAzul),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.primarioAzul),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 72,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 24),
                Text(
                  'Perfil Incompleto',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppTheme.textoOscuro),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Para garantizar la calidad educativa, por favor completa tu Facultad y Carrera en la pestaña Perfil antes de solicitar sesiones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppTheme.grisTexto),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retornar al inicio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primarioAzul,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final usuarioActualDelDispositivo = proveedorAutenticacion.usuarioActual!;

    return Scaffold(
      backgroundColor: AppTheme.fondoClaro,
      appBar: AppBar(
        title: const Text(
          'Solicitar Tutoría',
          style: TextStyle(color: AppTheme.primarioAzul),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primarioAzul),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grupo 1: Información Académica
              Text(
                'Información Académica',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primarioVerde,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _materiaController,
                        decoration: _decoracionCampo(
                          'Materia o Asignatura',
                          'Ej. Física Mecánica',
                          Icons.book_outlined,
                        ),
                        validator: (valor) =>
                            valor == null || valor.trim().isEmpty
                            ? 'Debes especificar la materia.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _temaController,
                        maxLines: 4,
                        decoration: _decoracionCampo(
                          'Tema Específico',
                          'Detalla lo que necesitas repasar...',
                          null,
                        ),
                        validator: (valor) =>
                            valor == null || valor.trim().isEmpty
                            ? 'Debes detallar el tema.'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Grupo 2: Logística y Tiempo
              Text(
                'Logística de la Sesión',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primarioVerde,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _modalidadSeleccionada,
                        decoration: _decoracionCampo(
                          'Modalidad de Clase',
                          '',
                          Icons.location_on_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Virtual',
                            child: Text('Virtual'),
                          ),
                          DropdownMenuItem(
                            value: 'Presencial',
                            child: Text('Presencial'),
                          ),
                        ],
                        onChanged: (nuevaEleccion) {
                          if (nuevaEleccion != null)
                            setState(
                              () => _modalidadSeleccionada = nuevaEleccion,
                            );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cupoController,
                              keyboardType: TextInputType.number,
                              decoration: _decoracionCampo(
                                'Cupo Máximo',
                                '',
                                Icons.groups_outlined,
                              ),
                              validator: (valor) {
                                if (valor == null || valor.trim().isEmpty)
                                  return 'Obligatorio';
                                if ((int.tryParse(valor) ?? 0) < 1)
                                  return 'Inválido';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _duracionController,
                              keyboardType: TextInputType.number,
                              decoration: _decoracionCampo(
                                'Minutos',
                                '60',
                                Icons.timer_outlined,
                              ),
                              validator: (valor) {
                                if (valor == null || valor.trim().isEmpty)
                                  return 'Obligatorio';
                                if ((int.tryParse(valor) ?? 0) < 10)
                                  return 'Min 10';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _seleccionarFecha,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primarioAzul,
                                side: const BorderSide(
                                  color: AppTheme.primarioAzul,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                _fechaSeleccionada == null
                                    ? 'Fijar Fecha'
                                    : '${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaSeleccionada!.month.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _seleccionarHora,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primarioAzul,
                                side: const BorderSide(
                                  color: AppTheme.primarioAzul,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.access_time_rounded),
                              label: Text(
                                _horaSeleccionada == null
                                    ? 'Fijar Hora'
                                    : _horaSeleccionada!.format(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botón de Envío
              Consumer<TutoriasProvider>(
                builder: (context, elProveedorDeTutorias, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primarioAzul,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: AppTheme.primarioAzul
                            .withOpacity(0.6),
                      ),
                      onPressed:
                          elProveedorDeTutorias.estaCargandoPeticionEnNube
                          ? null
                          : () => _confirmarYSubirTutoria(
                              usuarioActualDelDispositivo,
                            ),
                      child: elProveedorDeTutorias.estaCargandoPeticionEnNube
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Publicar Solicitud',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Método auxiliar para unificar la estética de los campos de texto
  InputDecoration _decoracionCampo(
    String etiqueta,
    String hint,
    IconData? icono,
  ) {
    return InputDecoration(
      labelText: etiqueta,
      hintText: hint,
      prefixIcon: icono != null ? Icon(icono, color: AppTheme.grisTexto) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primarioAzul, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
