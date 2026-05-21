import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/autenticacion_provider.dart';
import '../../models/usuario_model.dart';
import 'perfil_publico_tutor_view.dart';

class ExplorarView extends StatefulWidget {
  const ExplorarView({super.key});

  @override
  State<ExplorarView> createState() => _ExplorarViewState();
}

class _ExplorarViewState extends State<ExplorarView> {
  final TextEditingController _controladorDeBusqueda = TextEditingController();
  String _terminoBusqueda = '';

  @override
  void initState() {
    super.initState();
    _controladorDeBusqueda.addListener(() {
      setState(() {
        _terminoBusqueda = _controladorDeBusqueda.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _controladorDeBusqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final identidadMotor = context.watch<AutenticacionProvider>();
    final elUsuario = identidadMotor.usuarioActual;

    if (elUsuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuestra comunidad',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        elevation: 0,
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

          // Grilla Principal usando StreamBuilder para Reactividad Total
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('rolEnElSistema', isEqualTo: 'tutor')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Error de red al cargar tutores.',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                List<UsuarioModel> tutoresVirtuales = docs
                    .map(
                      (d) => UsuarioModel.fromMap(
                        d.data() as Map<String, dynamic>,
                      ),
                    )
                    .toList();

                if (_terminoBusqueda.isNotEmpty) {
                  tutoresVirtuales = tutoresVirtuales.where((maestro) {
                    final concuerdaNombre = maestro.nombreCompleto
                        .toLowerCase()
                        .contains(_terminoBusqueda);
                    final concuerdaFacultad =
                        (maestro.facultad?.toLowerCase() ?? '').contains(
                          _terminoBusqueda,
                        );
                    final concuerdaCarrera =
                        (maestro.carrera?.toLowerCase() ?? '').contains(
                          _terminoBusqueda,
                        );
                    return concuerdaNombre ||
                        concuerdaFacultad ||
                        concuerdaCarrera;
                  }).toList();
                }

                if (tutoresVirtuales.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No se encontraron tutores con ese criterio.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  itemCount: tutoresVirtuales.length,
                  itemBuilder: (context, index) {
                    final mentor = tutoresVirtuales[index];
                    return TarjetaComunidad(mentor: mentor);
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

class TarjetaComunidad extends StatelessWidget {
  final UsuarioModel mentor;

  const TarjetaComunidad({super.key, required this.mentor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PerfilPublicoTutorView(mentor: mentor),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Row(
            children: [
              // Columna Izquierda: Nombre
              Expanded(
                flex: 3,
                child: Text(
                  mentor.nombreCompleto,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    // Oscuro corporativo
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Columna Central: Área de especialidad
              Expanded(
                flex: 4,
                child: Text(
                  'Área de especialidad: ${mentor.carrera ?? mentor.facultad ?? 'General'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Columna Derecha: Estrellas
              Expanded(
                flex: 2,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(mentor.identificadorUnico)
                      .collection('evaluaciones')
                      .snapshots(),
                  builder: (context, snapshot) {
                    double promedio = 0;
                    int totalResenas = 0;
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final docs = snapshot.data!.docs;
                      totalResenas = docs.length;
                      for (var d in docs) {
                        promedio += (d['estrellas'] as num).toDouble();
                      }
                      promedio /= docs.length;
                    }

                    if (totalResenas < 10) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Nuevo',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    int estrellasLlenas = promedio.round();

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          size: 16,
                          color: index < estrellasLlenas
                              ? Colors.teal.shade500
                              : Colors.grey.shade300,
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
