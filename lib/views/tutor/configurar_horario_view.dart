import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/autenticacion_provider.dart';
import '../widgets/overlay_loader.dart';

class ConfigurarHorarioView extends StatefulWidget {
  const ConfigurarHorarioView({super.key});

  @override
  State<ConfigurarHorarioView> createState() => _ConfigurarHorarioViewState();
}

class _ConfigurarHorarioViewState extends State<ConfigurarHorarioView> {
  // Mapa local para gestionar los cambios en pantalla antes de enviarlos a la base de datos
  Map<String, List<String>> _horarioLocal = {};
  
  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];

  // Horas fijas de 7am a 9pm
  final List<String> _horasDisponibles = List.generate(15, (index) {
    final int horaNum = index + 7;
    return '${horaNum.toString().padLeft(2, '0')}:00';
  });

  bool _haCambiado = false;

  @override
  void initState() {
    super.initState();
    _cargarHorarioActual();
  }

  void _cargarHorarioActual() {
    final proveedorAuth = context.read<AutenticacionProvider>();
    final horarioDB = proveedorAuth.usuarioActual?.horarioDisponibilidad;
    
    if (horarioDB != null) {
      // Hacemos una copia profunda (deep copy) del mapa para no mutar el modelo directamente
      _horarioLocal = horarioDB.map((key, value) => MapEntry(key, List.from(value)));
    } else {
      _horarioLocal = {};
    }
  }

  void _toggleHora(String dia, String hora) {
    setState(() {
      _haCambiado = true;
      if (!_horarioLocal.containsKey(dia)) {
        _horarioLocal[dia] = [];
      }
      
      if (_horarioLocal[dia]!.contains(hora)) {
        _horarioLocal[dia]!.remove(hora);
        // Limpiamos la lista si quedó vacía
        if (_horarioLocal[dia]!.isEmpty) {
          _horarioLocal.remove(dia);
        }
      } else {
        _horarioLocal[dia]!.add(hora);
        // Ordenamos para que las horas aparezcan cronológicamente
        _horarioLocal[dia]!.sort((a, b) => a.compareTo(b));
      }
    });
  }

  Future<void> _guardarCambiosEnNube() async {
    final proveedorAuth = context.read<AutenticacionProvider>();
    final idUsuario = proveedorAuth.usuarioActual?.identificadorUnico;

    if (idUsuario == null) return;

    OverlayLoader.mostrar(context, mensaje: "Guardando disponibilidad...");

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(idUsuario)
          .update({'horarioDisponibilidad': _horarioLocal});

      // Refrescar el provider
      await proveedorAuth.inicializarSesionAlAbrirApp();

      if (mounted) {
        OverlayLoader.ocultar(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tus horarios se han guardado exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Volver al perfil
      }
    } catch (e) {
      if (mounted) {
        OverlayLoader.ocultar(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar. Verifica tu conexión a internet.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Disponibilidad'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.deepPurple.shade50,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.deepPurple),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selecciona los bloques de 1 hora en los que estás dispuesto a dictar tutorías. Si una clase te es asignada, ese bloque aparecerá como ocupado para los demás.',
                    style: TextStyle(color: Colors.deepPurple, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _diasSemana.length,
              itemBuilder: (context, index) {
                final String dia = _diasSemana[index];
                final List<String> horasSeleccionadas = _horarioLocal[dia] ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    title: Text(
                      dia,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      horasSeleccionadas.isEmpty
                          ? 'No disponible'
                          : '${horasSeleccionadas.length} bloque(s) seleccionado(s)',
                      style: TextStyle(
                        color: horasSeleccionadas.isEmpty ? Colors.grey : Colors.deepPurple,
                        fontWeight: horasSeleccionadas.isEmpty ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: _horasDisponibles.map((hora) {
                            final bool estaSeleccionada = horasSeleccionadas.contains(hora);
                            return FilterChip(
                              label: Text(hora),
                              selected: estaSeleccionada,
                              onSelected: (bool selected) => _toggleHora(dia, hora),
                              selectedColor: Colors.deepPurple.shade100,
                              checkmarkColor: Colors.deepPurple,
                              labelStyle: TextStyle(
                                color: estaSeleccionada ? Colors.deepPurple.shade900 : Colors.black87,
                                fontWeight: estaSeleccionada ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _haCambiado
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton.icon(
                  onPressed: _guardarCambiosEnNube,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Horarios'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
