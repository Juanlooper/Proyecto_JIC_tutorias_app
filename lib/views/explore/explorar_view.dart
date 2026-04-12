import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/autenticacion_provider.dart';
import '../../models/usuario_model.dart';

class ExplorarView extends StatefulWidget {
  const ExplorarView({super.key});

  @override
  State<ExplorarView> createState() => _ExplorarViewState();
}

class _ExplorarViewState extends State<ExplorarView> {
  final TextEditingController _controladorDeBusqueda = TextEditingController();
  String _terminoBusqueda = '';
  
  // Caché de memoria para los tutores descargados y evitar consumos repetidos
  List<UsuarioModel>? _tutoresDeLaComunidad;
  bool _estaCargandoRespuesta = true;

  @override
  void initState() {
    super.initState();
    _controladorDeBusqueda.addListener(() {
      setState(() {
        _terminoBusqueda = _controladorDeBusqueda.text.toLowerCase();
      });
    });
    
    _descargarMallaDeTutoresGenerales();
  }

  @override
  void dispose() {
    _controladorDeBusqueda.dispose();
    super.dispose();
  }

  /// Carga silente de todos los tutores iniciales para llenar la grilla
  Future<void> _descargarMallaDeTutoresGenerales() async {
    try {
      final consultaEnVivo = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rolEnElSistema', isEqualTo: 'tutor')
          .get();

      if (mounted) {
        setState(() {
          _tutoresDeLaComunidad = consultaEnVivo.docs
              .map((doc) => UsuarioModel.fromMap(doc.data()))
              .toList();
          _estaCargandoRespuesta = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _tutoresDeLaComunidad = [];
          _estaCargandoRespuesta = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complicaciones de red al intentar cargar la comunidad de tutores.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _extraerIniciales(String nombre) {
    if (nombre.trim().isEmpty) return '?';
    final fragmentos = nombre.trim().split(' ');
    if (fragmentos.length > 1) {
      return '${fragmentos[0][0]}${fragmentos[1][0]}'.toUpperCase();
    }
    return fragmentos[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final identidadMotor = context.watch<AutenticacionProvider>();
    final elUsuario = identidadMotor.usuarioActual;

    if (elUsuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Algoritmo de filtrado reactivo
    List<UsuarioModel> tutoresPresentables = _tutoresDeLaComunidad ?? [];
    if (_terminoBusqueda.isNotEmpty) {
      tutoresPresentables = tutoresPresentables.where((maestro) {
        final concuerdaNombre = maestro.nombreCompleto.toLowerCase().contains(_terminoBusqueda);
        final concuerdaFacultad = (maestro.facultad?.toLowerCase() ?? '').contains(_terminoBusqueda);
        final concuerdaCarrera = (maestro.carrera?.toLowerCase() ?? '').contains(_terminoBusqueda);
        
        return concuerdaNombre || concuerdaFacultad || concuerdaCarrera;
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad de Tutores'),
      ),
      body: Column(
        children: [
          // Sección Superior Fija de Búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _controladorDeBusqueda,
              leading: const Icon(Icons.search, color: Colors.grey),
              hintText: 'Buscar por nombre, carrera o facultad...',
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              elevation: WidgetStateProperty.all(1.5),
            ),
          ),

          // Grilla Principal
          Expanded(
            child: _estaCargandoRespuesta
                ? const Center(child: CircularProgressIndicator())
                : tutoresPresentables.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No se encontraron tutores con ese criterio.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75, // Otorga un perfil más vertical y estético
                        ),
                        itemCount: tutoresPresentables.length,
                        itemBuilder: (context, index) {
                          final mentor = tutoresPresentables[index];
                          final loEstoySiguiendo = elUsuario.listaDeTutoresSuscritos.contains(mentor.identificadorUnico);

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Text(
                                      _extraerIniciales(mentor.nombreCompleto),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    mentor.nombreCompleto,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    mentor.carrera ?? mentor.facultad ?? 'Indefinido',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () {
                                        identidadMotor.gestionarSuscripcionATutor(mentor.identificadorUnico);
                                      },
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 0),
                                        backgroundColor: loEstoySiguiendo ? Colors.grey[700] : Theme.of(context).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        loEstoySiguiendo ? 'Suscrito' : 'Seguir',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
