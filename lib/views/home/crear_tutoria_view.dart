import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/autenticacion_provider.dart';
import '../../providers/tutorias_provider.dart';
import '../../models/tutoria_model.dart';
import '../../models/usuario_model.dart';
import '../../core/utils/moderacion_servicio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_storage_servicio.dart';

class CrearTutoriaView extends StatefulWidget {
  const CrearTutoriaView({super.key});

  @override
  State<CrearTutoriaView> createState() => _CrearTutoriaViewState();
}

class _CrearTutoriaViewState extends State<CrearTutoriaView> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de los campos de texto
  final _materiaController = TextEditingController();
  final _temaController = TextEditingController();
  final _cupoController = TextEditingController(text: '1');
  final _duracionController = TextEditingController(text: '60');

  String _modalidadSeleccionada = 'Virtual';
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;

  bool _estaSubiendoArchivo = false;
  String? _archivoSubidoUrl;
  String? _archivoSubidoNombre;

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
    );

    if (horaElegida != null) {
      setState(() {
        _horaSeleccionada = horaElegida;
      });
    }
  }

  Future<void> _confirmarYSubirTutoria(UsuarioModel usuarioCreador) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (ModeracionServicio.contieneLenguajeToxico(_materiaController.text) ||
        ModeracionServicio.contieneLenguajeToxico(_temaController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "El texto ingresado contiene lenguaje inapropiado u ofensivo. Por favor, corrígelo antes de publicar.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_fechaSeleccionada == null || _horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, selecciona tanto la fecha como la hora sugerida para la tutoría.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_archivoSubidoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes adjuntar un material de referencia (PDF o Imagen) para solicitar una tutoría.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    /*
     * Proceso de combinación de Date y Time en un único DateTime:
     * Para lograr una marca de tiempo absoluta y estandarizada, capturamos el año,
     * mes y día del objeto DateTime provisto por 'showDatePicker'. A estos pilares
     * esenciales les acoplamos la hora y los minutos extraídos del objeto TimeOfDay 
     * retornado por 'showTimePicker'.
     * Esta fusión permite el almacenamiento fluido, el orden cronológico estricto 
     * y el filtrado ultra rápido dentro de las colecciones de Firebase Firestore.
     */
    final DateTime fechaHoraFinalSugerida = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );

    // Generamos una huella digital temporal inquebrantable para el documento
    final String identificadorUnico = FirebaseFirestore.instance
        .collection('tutorias')
        .doc()
        .id;

    final int cuposElegidos = int.tryParse(_cupoController.text) ?? 1;
    final int minutosDuracion = int.tryParse(_duracionController.text) ?? 60;

    final TutoriaModel miModelo = TutoriaModel(
      identificadorDeTutoria: identificadorUnico,
      materiaOAsignatura: _materiaController.text.trim(),
      temaEspecifico: _temaController.text.trim(),
      carrera: usuarioCreador.carrera ?? 'General',
      identificadorDelTutor:
          '', // Se inicializa vacío a la espera de que un profesor del sistema acepte el encargo
      listaDeEstudiantesInscritos: [
        usuarioCreador.identificadorUnico,
      ], // El autor solicitante ocupa automáticamente la primera plaza
      enlaces_adjuntos: {
        usuarioCreador.identificadorUnico: [_archivoSubidoUrl!],
      },
      nombres_adjuntos: {
        usuarioCreador.identificadorUnico: [_archivoSubidoNombre!],
      },
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
            content: Text(
              'La solicitud de tutoría ha sido publicada exitosamente en el foro mundial.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Cerramos el formulario triunfalmente
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
    // Validamos estrictamente las condiciones de acceso iniciales exigidas
    final proveedorAutenticacion = context.read<AutenticacionProvider>();
    final perfilValido = proveedorAutenticacion.perfilCompleto;

    // Si el usuario no ha suministrado los campos críticos de Facultad y Carrera, bloqueamos el formulario.
    if (!perfilValido) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Restringido')),
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
                const Text(
                  'Perfil Incompleto',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Para garantizar la calidad educativa, por favor completa tu Facultad y Carrera en la pestaña Perfil antes de solicitar sesiones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    // Retorna al sistema anterior para que el usuario navegue voluntariamente.
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retornar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Como perfilValido asegura la existencia de modelo, leemos el usuario.
    final usuarioActualDelDispositivo = proveedorAutenticacion.usuarioActual!;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Tutoría')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _materiaController,
                decoration: const InputDecoration(
                  labelText: 'Materia o Asignatura',
                  hintText: 'Ej. Física Mecánica',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (valorTexto) {
                  if (valorTexto == null || valorTexto.trim().isEmpty) {
                    return 'Debes especificar la materia.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _temaController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Tema Específico / Dudas Puntuales',
                  hintText: 'Detalla lo que necesitas repasar...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (valorTexto) {
                  if (valorTexto == null || valorTexto.trim().isEmpty) {
                    return 'Debes escribir sobre el tema específico a tratar.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _modalidadSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Modalidad de Clase',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Virtual', child: Text('Virtual')),
                  DropdownMenuItem(
                    value: 'Presencial',
                    child: Text('Presencial'),
                  ),
                ],
                onChanged: (nuevaEleccion) {
                  if (nuevaEleccion != null) {
                    setState(() {
                      _modalidadSeleccionada = nuevaEleccion;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cupoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cupo Máximo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      validator: (valorTexto) {
                        if (valorTexto == null || valorTexto.trim().isEmpty) {
                          return 'Obligatorio';
                        }
                        final intentoNumerico = int.tryParse(valorTexto);
                        if (intentoNumerico == null || intentoNumerico < 1) {
                          return 'Inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _duracionController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duración (Mins)',
                        hintText: '30, 60, 90',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                      validator: (valorTexto) {
                        if (valorTexto == null || valorTexto.trim().isEmpty) {
                          return 'Obligatorio';
                        }
                        final intentoNumerico = int.tryParse(valorTexto);
                        if (intentoNumerico == null || intentoNumerico < 10) {
                          return 'Min 10';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Zona de subida interactiva
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Material de Referencia (Obligatorio)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_estaSubiendoArchivo)
                      const Center(child: CircularProgressIndicator())
                    else if (_archivoSubidoUrl != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Archivo adjuntado: $_archivoSubidoNombre',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () async {
                          setState(() {
                            _estaSubiendoArchivo = true;
                          });

                          try {
                            final mapArchivo = await FirebaseStorageServicio()
                                .seleccionarYSubirArchivo(
                                  carpetaDestino: 'tutorias_archivos',
                                );

                            setState(() {
                              _estaSubiendoArchivo = false;
                              if (mapArchivo != null) {
                                _archivoSubidoUrl = mapArchivo['url'];
                                _archivoSubidoNombre = mapArchivo['nombre'];
                              }
                            });
                          } catch (e) {
                            setState(() {
                              _estaSubiendoArchivo = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Adjuntar PDF o Imagen'),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      'Puedes subir un examen, taller o temario.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Text(
                      'Formatos: PDF, JPG, PNG, DOCX, PPTX (Máx. 5MB)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Seccion de Calendario y Reloj
              const Text(
                'Planificación Sugerida',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarFecha,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                      ),
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        _fechaSeleccionada == null
                            ? 'Fijar Fecha'
                            : '${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaSeleccionada!.month.toString().padLeft(2, '0')}/${_fechaSeleccionada!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarHora,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
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

              const SizedBox(height: 48),

              // Boton de Envio Transaccional
              Consumer<TutoriasProvider>(
                builder: (context, elProveedorDeTutorias, elNinoNoUsado) {
                  return FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: elProveedorDeTutorias.estaCargandoPeticionEnNube
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
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
