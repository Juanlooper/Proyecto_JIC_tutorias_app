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
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

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
            child: TextField(
              controller: _controladorDeBusqueda,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, carrera o facultad...',
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
    final esOscuro = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = Theme.of(context).colorScheme.onSurface;
    final colorSubtexto = esOscuro ? Colors.grey[400] : Colors.grey;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: esOscuro
              ? Colors.grey.shade700
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PerfilPublicoTutorView(mentor: mentor),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: esOscuro
                    ? Colors.teal.withValues(alpha: 0.2)
                    : Colors.teal.shade50,
                child: const Icon(Icons.person, color: Color(0xFF1CA887)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentor.nombreCompleto,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorTexto,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Área de especialidad: ${mentor.carrera ?? mentor.facultad ?? 'General'}',
                      style: TextStyle(fontSize: 13, color: colorSubtexto),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: esOscuro
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 14,
                      color: esOscuro
                          ? Colors.blue.shade300
                          : const Color(0xFF1951CB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Nuevo',
                      style: TextStyle(
                        color: esOscuro
                            ? Colors.blue.shade300
                            : const Color(0xFF1951CB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
