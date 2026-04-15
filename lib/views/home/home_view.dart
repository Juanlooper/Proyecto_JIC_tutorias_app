import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/autenticacion_provider.dart';
import '../../providers/tutorias_provider.dart';
import '../../models/usuario_model.dart';
import '../../models/tutoria_model.dart';
import 'crear_tutoria_view.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutoriasProvider>().cargarListadoDeTutoriasPendientes();
    });
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  Future<void> _actualizarLista() async {
    await context.read<TutoriasProvider>().cargarListadoDeTutoriasPendientes();
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
            child: RefreshIndicator(
              onRefresh: _actualizarLista,
              child: Consumer<TutoriasProvider>(
                builder: (context, proveedorTutorias, child) {
                  if (proveedorTutorias.estaCargandoPeticionEnNube &&
                      proveedorTutorias.tutoriasPendientesGenerales.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final listadoCompleto =
                      proveedorTutorias.tutoriasPendientesGenerales;

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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearTutoriaView()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Solicitar Tutoría'),
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
    final esProfesor = usuario.tieneRol(RolSistema.tutor);
    final accionTexto = esProfesor
        ? 'impartir esta tutoría'
        : 'inscribirte en esta clase';

    // HCI: Barrera de confirmación preventiva antes de alterar la base de datos
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (contextDialogo) => AlertDialog(
        title: const Text('Confirmar Acción'),
        content: Text('¿Estás seguro de que deseas $accionTexto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextDialogo, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contextDialogo, true),
            child: const Text('Sí, confirmar'),
          ),
        ],
      ),
    );

    if (confirmacion != true || !context.mounted) return;

    final proveedor = context.read<TutoriasProvider>();
    bool operacionConcretaExitosa = false;

    if (esProfesor) {
      operacionConcretaExitosa = await proveedor.aceptarTutoria(
        datosTutoria.identificadorDeTutoria,
        usuario.identificadorUnico,
      );
    } else {
      operacionConcretaExitosa = await proveedor.unirseAClaseMultitudinaria(
        identificacionGlobalDeLaClase: datosTutoria.identificadorDeTutoria,
        matriculaDeIdentidadDelEstudiante: usuario.identificadorUnico,
      );
    }

    if (!operacionConcretaExitosa && context.mounted) {
      final fallaMotivo = proveedor.mensajeDeErrorDelSistema;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fallaMotivo), backgroundColor: Colors.redAccent),
      );
    } else if (operacionConcretaExitosa && context.mounted) {
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
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed:
                    datosTutoria.listaDeEstudiantesInscritos.length >=
                            datosTutoria.cupoMaximo &&
                        !esTutor
                    ? null
                    : () => _ejecutarAccion(context, elUsuario),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
                child: Text(esTutor ? 'Aceptar Tutoría' : 'Unirse a clase'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
