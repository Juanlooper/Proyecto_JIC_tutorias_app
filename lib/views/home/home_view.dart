import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/autenticacion_provider.dart';
import '../../providers/tutorias_provider.dart';
import '../../models/usuario_model.dart';
import '../../models/tutoria_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _terminoBusqueda = '';

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
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tutorias').where('estadoDeLaSolicitud', isEqualTo: 'pendiente').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error cargando la cartelera."));
                }

                final universeDocs = snapshot.data?.docs ?? [];
                final elUsuario = context.read<AutenticacionProvider>().usuarioActual;
                final myUid = elUsuario?.identificadorUnico ?? '';

                final listadoCompleto = universeDocs
                    .map((doc) => TutoriaModel.fromMap(doc.data() as Map<String, dynamic>))
                    .where((tutoria) => tutoria.identificadorDelTutor.isNotEmpty && tutoria.identificadorDelTutor != myUid)
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

      final confirmacion = await showDialog<bool>(
        context: context,
        builder: (contextDialogo) => AlertDialog(
          title: Text('Confirmar Reserva: ${datosTutoria.materiaOAsignatura}'),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: enlaceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Enlace a material (Drive, PDF, etc.)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextDialogo, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(contextDialogo, true);
                }
              },
              child: const Text('Confirmar Inscripción'),
            ),
          ],
        ),
      );

      if (confirmacion != true || !context.mounted) return;

      final url = enlaceCtrl.text.trim();
      final listadoLinks = url.isNotEmpty ? [url] : <String>[];

      operacionConcretaExitosa = await proveedor.inscribirseEnTutoria(
        datosTutoria.identificadorDeTutoria,
        usuario.identificadorUnico,
        motivoCtrl.text.trim(),
        listadoLinks,
      );

    if (!context.mounted) return;

    if (!operacionConcretaExitosa) {
      final fallaMotivo = proveedor.mensajeDeErrorDelSistema;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fallaMotivo), backgroundColor: Colors.redAccent),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acción procesada con éxito.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proveedorIdentidad = context.watch<AutenticacionProvider>();
    final elUsuario = proveedorIdentidad.usuarioActual;

    if (elUsuario == null) return const SizedBox.shrink();

    final esTutor = elUsuario.tieneRol(RolSistema.tutor);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              datosTutoria.materiaOAsignatura,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              datosTutoria.temaEspecifico,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      datosTutoria.modalidadDeClase.toLowerCase().contains(
                            'virtual',
                          )
                          ? Icons.computer
                          : Icons.meeting_room,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(datosTutoria.modalidadDeClase),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      datosTutoria.listaDeEstudiantesInscritos.length >=
                              datosTutoria.cupoMaximo
                          ? Icons.block
                          : Icons.people_alt,
                      size: 20,
                      color:
                          datosTutoria.listaDeEstudiantesInscritos.length >=
                              datosTutoria.cupoMaximo
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${datosTutoria.listaDeEstudiantesInscritos.length} / ${datosTutoria.cupoMaximo}',
                      style: TextStyle(
                        color:
                            datosTutoria.listaDeEstudiantesInscritos.length >=
                                datosTutoria.cupoMaximo
                            ? Colors.red
                            : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Detalles extendidos solicitados: Tutor y Fecha
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tutor: ${datosTutoria.identificadorDelTutor.isEmpty ? "Por asignar" : (datosTutoria.nombre_tutor ?? "Tutor Asignado")}',
                     style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lugar: ${datosTutoria.lugar ?? "Por definir"}',
                     style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.contact_mail, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contacto: ${datosTutoria.contacto_tutor ?? "Contacto pendiente"}',
                     style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${datosTutoria.fechaHoraSugerida.day.toString().padLeft(2, '0')}/${datosTutoria.fechaHoraSugerida.month.toString().padLeft(2, '0')} - ${datosTutoria.fechaHoraSugerida.hour.toString().padLeft(2, '0')}:${datosTutoria.fechaHoraSugerida.minute.toString().padLeft(2, '0')} Hrs',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Builder(
                builder: (context) {
                  final bool yaInscrito = datosTutoria.listaDeEstudiantesInscritos.contains(elUsuario.identificadorUnico);
                  final bool estaLleno = datosTutoria.listaDeEstudiantesInscritos.length >= datosTutoria.cupoMaximo;

                  final bool bloquearEstudiante = (yaInscrito || estaLleno);

                  return FilledButton(
                    onPressed: bloquearEstudiante
                        ? null
                        : () => _ejecutarAccion(context, elUsuario),
                    style: FilledButton.styleFrom(
                      backgroundColor: yaInscrito 
                          ? Colors.grey 
                          : Theme.of(context).colorScheme.secondary,
                    ),
                    child: Text(yaInscrito ? 'Suscrito' : 'Reservar'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
