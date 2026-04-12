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
  @override
  void initState() {
    super.initState();
    // Programamos la carga para cuando el arbol de widgets este montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TutoriasProvider>().cargarListadoDeTutoriasPendientes();
    });
  }

  Future<void> _actualizarLista() async {
    await context.read<TutoriasProvider>().cargarListadoDeTutoriasPendientes();
  }

  @override
  Widget build(BuildContext context) {
    /*
     * Documentacion de uso de RefreshIndicator:
     * El componente RefreshIndicator envuelve primariamente el area de desplazamiento 
     * (scrollable). Al deslizar la pantalla hacia abajo mas alla de cierto limite,
     * se dispara la funcion de recarga asincrona proporcionada en 'onRefresh'. 
     * Durante la espera, se despliega un circulo superior indicando que la aplicacion
     * esta descargando datos actualizados de la nube antes de redibujar la vista.
     */
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Tutorías'),
      ),
      body: RefreshIndicator(
        onRefresh: _actualizarLista,
        child: Consumer<TutoriasProvider>(
          builder: (context, proveedorTutorias, child) {
            // Evaluacion de espera conectiva
            if (proveedorTutorias.estaCargandoPeticionEnNube && proveedorTutorias.tutoriasPendientesGenerales.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final listado = proveedorTutorias.tutoriasPendientesGenerales;

            // Manejo de vacio informativo
            if (listado.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(), // Fomenta que el gesto swipe-down siga funcionando a pesar del vacio
                children: const [
                  SizedBox(height: 100),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'No hay tutorías pendientes por ahora. ¡Sé el primero en solicitar una!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              );
            }

            // Constructor de Tarjetas
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              itemCount: listado.length,
              itemBuilder: (context, indice) {
                return _TarjetaDeTutoriaDinamica(datosTutoria: listado[indice]);
              },
            );
          },
        ),
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

  Future<void> _ejecutarAccion(BuildContext context, UsuarioModel usuario) async {
    final esProfesor = usuario.tieneRol(RolSistema.tutor);
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

    if (!operacionConcretaExitosa) {
      if (context.mounted) {
        final fallaMotivo = proveedor.mensajeDeErrorDelSistema;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fallaMotivo),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escaneamos la identidad central
    final proveedorIdentidad = context.watch<AutenticacionProvider>();
    final elUsuario = proveedorIdentidad.usuarioActual;

    if (elUsuario == null) return const SizedBox.shrink();

    final esTutor = elUsuario.tieneRol(RolSistema.tutor);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12.0),
      color: Theme.of(context).cardColor, // Adherencia estricta al dark mode o configuracion actual de brillo
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Text(
              datosTutoria.materiaOAsignatura,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              datosTutoria.temaEspecifico,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
            const SizedBox(height: 18),

            // Informacion Compacta (Row)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Grupo 1: Modalidad
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      datosTutoria.modalidadDeClase.toLowerCase().contains('virtual')
                          ? Icons.computer
                          : Icons.meeting_room,
                      size: 20,
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(datosTutoria.modalidadDeClase),
                  ],
                ),
                // Grupo 2: Cupos
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_alt,
                      size: 20,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    Text('${datosTutoria.listaDeEstudiantesInscritos.length} / ${datosTutoria.cupoMaximo}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Accion Dinamica
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
                onPressed: () => _ejecutarAccion(context, elUsuario),
                child: Text(esTutor ? 'Aceptar Tutoría' : 'Unirse a clase'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
