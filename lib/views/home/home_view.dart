import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/autenticacion_provider.dart';
import '../../providers/tutorias_provider.dart';
import '../../models/usuario_model.dart';
import '../../models/tutoria_model.dart';
import '../../services/firebase_storage_servicio.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _terminoBusqueda = '';

  final List<String> _filtrosRapidos = [
    'Cálculo',
    'Física',
    'Programación',
    'Química',
    'Dibujo',
    'Lógica',
  ];

  @override
  void initState() {
    super.initState();
    // Escucha los cambios en el teclado para actualizar el estado reactivamente
    _controladorBusqueda.addListener(() {
      setState(() {
        _terminoBusqueda = _controladorBusqueda.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar Tutorías'), centerTitle: true),
      body: Column(
        children: [
          // Barra de Búsqueda (HCI: Reconocimiento sobre recuerdo)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controladorBusqueda,
              decoration: InputDecoration(
                labelText: 'Buscar por materia o tema...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: esOscuro ? Colors.grey[850] : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          // Filtros Rápidos (Chips)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtrosRapidos.length,
              itemBuilder: (context, index) {
                final filtro = _filtrosRapidos[index];
                final estaSeleccionado =
                    _controladorBusqueda.text.toLowerCase().trim() ==
                    filtro.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      filtro,
                      style: TextStyle(
                        color: estaSeleccionado ? Colors.white : colorTexto,
                        fontWeight: estaSeleccionado
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: estaSeleccionado,
                    selectedColor: const Color(0xFF1CA887),
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: estaSeleccionado
                            ? const Color(0xFF1CA887)
                            : (esOscuro ? Colors.grey[700]! : Colors.grey[300]!),
                      ),
                    ),
                    showCheckmark: false,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _controladorBusqueda.text = filtro;
                        } else {
                          _controladorBusqueda.clear();
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tutorias')
                  .where(
                    'estadoDeLaSolicitud',
                    whereIn: [
                      'pendiente',
                      'Pendiente',
                      'aceptada',
                      'Aceptada',
                      'abierta',
                      'Abierta',
                    ],
                  )
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Error cargando la cartelera."),
                  );
                }

                final universeDocs = snapshot.data?.docs ?? [];
                final elUsuario = context
                    .read<AutenticacionProvider>()
                    .usuarioActual;
                final myUid = elUsuario?.identificadorUnico ?? '';

                final listadoCompleto = universeDocs
                    .map(
                      (doc) => TutoriaModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .where((tutoria) {
                      // Excluir propias
                      if (tutoria.identificadorDelTutor.isEmpty ||
                          tutoria.identificadorDelTutor == myUid) {
                        return false;
                      }

                      // Excluir tutorías cuya hora de finalización ya pasó
                      final DateTime horaFin = tutoria.fechaHoraSugerida.add(
                        Duration(minutes: tutoria.duracionMinutos),
                      );
                      if (horaFin.isBefore(DateTime.now())) return false;

                      return true;
                    })
                    .toList();

                // Lógica de filtrado en memoria local
                final listadoFiltrado = _terminoBusqueda.isEmpty
                    ? listadoCompleto
                    : listadoCompleto.where((tutoria) {
                        final concuerdaMateria = tutoria.materiaOAsignatura
                            .toLowerCase()
                            .contains(_terminoBusqueda);
                        final concuerdaTema = tutoria.temaEspecifico
                            .toLowerCase()
                            .contains(_terminoBusqueda);
                        return concuerdaMateria || concuerdaTema;
                      }).toList();

                if (listadoFiltrado.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'No se encontraron tutorías con esos criterios de búsqueda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  itemCount: listadoFiltrado.length,
                  itemBuilder: (context, indice) {
                    return _TarjetaDeTutoriaDinamica(
                      datosTutoria: listadoFiltrado[indice],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaDeTutoriaDinamica extends StatelessWidget {
  final TutoriaModel datosTutoria;

  const _TarjetaDeTutoriaDinamica({required this.datosTutoria});

  Future<void> _ejecutarAccion(
    BuildContext context,
    UsuarioModel usuario,
  ) async {
    final proveedor = context.read<TutoriasProvider>();
    bool operacionConcretaExitosa = false;

    // Modulo específico de inscripción de Alumnos (Modal Interactivo)
    final TextEditingController motivoCtrl = TextEditingController();
    final TextEditingController enlaceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Estado del archivo subido
    bool estaSubiendoArchivo = false;
    String? archivoSubidoUrl;
    String? archivoSubidoNombre;

    final confirmacion = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevenir cierre accidental al subir
      builder: (contextDialogo) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              'Confirmar Reserva: ${datosTutoria.materiaOAsignatura}',
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: motivoCtrl,
                      decoration: const InputDecoration(
                        labelText: '¿Qué tema específico necesitas reforzar?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa un motivo detallado.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Zona de subida interactiva
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Material de Referencia (Obligatorio)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (estaSubiendoArchivo)
                            const Center(child: CircularProgressIndicator())
                          else if (archivoSubidoUrl != null)
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Archivo adjuntado con éxito.',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () async {
                                setStateDialog(() {
                                  estaSubiendoArchivo = true;
                                });

                                try {
                                  // Llamado al servicio inteligente de Firebase Storage
                                  final mapArchivo =
                                      await FirebaseStorageServicio()
                                          .seleccionarYSubirArchivo(
                                            carpetaDestino: 'tutorias_archivos',
                                          );

                                  setStateDialog(() {
                                    estaSubiendoArchivo = false;
                                    if (mapArchivo != null) {
                                      archivoSubidoUrl = mapArchivo['url'];
                                      archivoSubidoNombre =
                                          mapArchivo['nombre'];
                                      enlaceCtrl.text =
                                          mapArchivo['url']!; // Lo guardamos invisible
                                    }
                                  });
                                } catch (e) {
                                  setStateDialog(() {
                                    estaSubiendoArchivo = false;
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
                          const SizedBox(height: 8),
                          const Text(
                            'Puedes subir un examen, taller o temario.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const Text(
                            'Formatos: PDF, JPG, PNG, DOCX, PPTX (Máx. 5MB)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: estaSubiendoArchivo
                    ? null
                    : () => Navigator.pop(contextDialogo, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              FilledButton(
                onPressed: estaSubiendoArchivo
                    ? null
                    : () {
                        if (archivoSubidoUrl == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Debes adjuntar un material de referencia (PDF o Imagen) para inscribirte.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(contextDialogo, true);
                        }
                      },
                child: const Text('Confirmar Inscripción'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmacion != true) {
      if (archivoSubidoUrl != null) {
        FirebaseStorageServicio().eliminarArchivoFisico(archivoSubidoUrl!);
      }
      return;
    }

    if (!context.mounted) return;

    final url = enlaceCtrl.text.trim();
    final listadoLinks = url.isNotEmpty ? [url] : <String>[];
    final listadoNombres = archivoSubidoNombre != null
        ? [archivoSubidoNombre!]
        : <String>[];

    operacionConcretaExitosa = await proveedor.inscribirseEnTutoria(
      datosTutoria.identificadorDeTutoria,
      usuario.identificadorUnico,
      motivoCtrl.text.trim(),
      listadoLinks,
      listadoNombres,
    );

    if (!context.mounted) return;

    if (!operacionConcretaExitosa) {
      final fallaMotivo = proveedor.mensajeDeErrorDelSistema;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fallaMotivo), backgroundColor: Colors.redAccent),
      );
    } else {
      final msjExito = proveedor.mensajeDeExitoDelSistema.isNotEmpty
          ? proveedor.mensajeDeExitoDelSistema
          : 'Acción procesada con éxito.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msjExito), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proveedorIdentidad = context.watch<AutenticacionProvider>();
    final elUsuario = proveedorIdentidad.usuarioActual;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    final colorSubtexto = esOscuro ? Colors.grey[400] : Colors.grey[700];

    if (elUsuario == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: esOscuro ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1CA887).withValues(alpha: esOscuro ? 0.35 : 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // Activa el efecto Ripple
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  datosTutoria.materiaOAsignatura.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  datosTutoria.temaEspecifico,
                  style: TextStyle(color: colorSubtexto, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      datosTutoria.modalidadDeClase.toLowerCase().contains(
                            'virtual',
                          )
                          ? Icons.computer
                          : Icons.location_on,
                      size: 16,
                      color: const Color(0xFF1951CB),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${datosTutoria.modalidadDeClase}, ${datosTutoria.lugar ?? "Por definir"}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: colorTexto,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tutor: ${datosTutoria.identificadorDelTutor.isEmpty ? "Por asignar" : (datosTutoria.nombre_tutor ?? "Tutor Asignado")}',
                        style: TextStyle(
                          color: colorTexto,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      datosTutoria.listaDeEstudiantesInscritos.length >=
                              datosTutoria.cupoMaximo
                          ? Icons.block
                          : Icons.people_alt,
                      size: 16,
                      color: const Color(0xFF1951CB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cupos: ${datosTutoria.listaDeEstudiantesInscritos.length} / ${datosTutoria.cupoMaximo}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: colorTexto,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${datosTutoria.fechaHoraSugerida.day.toString().padLeft(2, '0')}/${datosTutoria.fechaHoraSugerida.month.toString().padLeft(2, '0')} - ${datosTutoria.fechaHoraSugerida.hour.toString().padLeft(2, '0')}:${datosTutoria.fechaHoraSugerida.minute.toString().padLeft(2, '0')} Hrs',
                        style: TextStyle(
                          color: colorTexto,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.hourglass_bottom,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${datosTutoria.duracionMinutos} min',
                      style: TextStyle(
                        color: colorTexto,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final elUsuario = context
                        .read<AutenticacionProvider>()
                        .usuarioActual;
                    if (elUsuario == null) return const SizedBox.shrink();

                    final bool yaInscrito = datosTutoria
                        .listaDeEstudiantesInscritos
                        .contains(elUsuario.identificadorUnico);
                    final bool estaLleno =
                        datosTutoria.listaDeEstudiantesInscritos.length >=
                        datosTutoria.cupoMaximo;

                    final bool bloquearEstudiante = (yaInscrito || estaLleno);

                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: bloquearEstudiante
                            ? null
                            : () => _ejecutarAccion(context, elUsuario),
                        style: FilledButton.styleFrom(
                          backgroundColor: yaInscrito
                              ? Colors.grey
                              : const Color(0xFF1CA887),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(yaInscrito ? 'Reservado' : 'Reservar'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
