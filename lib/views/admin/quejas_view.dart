import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuejasView extends StatelessWidget {
  final bool ocultarAppBar;

  const QuejasView({super.key, this.ocultarAppBar = false});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: ocultarAppBar
            ? const TabBar(
                    labelColor: Colors.orange,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.orange,
                    tabs: [
                      Tab(text: 'Quejas', icon: Icon(Icons.warning)),
                      Tab(
                        text: 'Moderación de Reseñas',
                        icon: Icon(Icons.reviews),
                      ),
                    ],
                  )
                  as PreferredSizeWidget
            : AppBar(
                title: const Text('Panel de Moderación'),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                bottom: const TabBar(
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(text: 'Quejas', icon: Icon(Icons.warning)),
                    Tab(text: 'Reseñas', icon: Icon(Icons.reviews)),
                  ],
                ),
              ),
        body: const TabBarView(children: [_TabQuejas(), _TabResenas()]),
      ),
    );
  }
}

class _TabQuejas extends StatelessWidget {
  const _TabQuejas();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quejas').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error al conectar con la base de datos'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Ninguna queja o cancelación tardía registrada.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final actas = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: actas.length,
          itemBuilder: (context, index) {
            final acta = actas[index].data() as Map<String, dynamic>;
            final fechaStr = acta['fechaRegistro'] ?? '';
            final tutorId = acta['tutorId'] ?? 'Desconocido';
            final tutoriaId = acta['tutoriaId'] ?? 'N/A';
            final justificacion = acta['justificacion'] ?? 'Sin justificación';

            DateTime? fecha;
            try {
              if (fechaStr.isNotEmpty) fecha = DateTime.parse(fechaStr);
            } catch (_) {}

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.orange.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fecha != null
                                ? '${fecha.day}/${fecha.month}/${fecha.year} - ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}'
                                : 'Fecha Desconocida',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('quejas')
                                .doc(actas[index].id)
                                .delete();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tutor ID: $tutorId',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Clase ID: $tutoriaId',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Justificación de cancelación:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"$justificacion"',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TabResenas extends StatelessWidget {
  const _TabResenas();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('evaluaciones')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar reseñas'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No hay reseñas registradas.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final resenas = snapshot.data!.docs;

        // Ordenar localmente por fecha descendente
        resenas.sort((a, b) {
          final aDatos = a.data() as Map<String, dynamic>;
          final bDatos = b.data() as Map<String, dynamic>;
          return (bDatos['fecha'] ?? '').compareTo(aDatos['fecha'] ?? '');
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: resenas.length,
          itemBuilder: (context, index) {
            final doc = resenas[index];
            final datos = doc.data() as Map<String, dynamic>;
            final fechaStr = datos['fecha'] ?? '';
            final publico =
                datos['comentario_publico'] ??
                datos['comentario'] ??
                'Sin comentario público';
            final privado =
                datos['comentario_admin'] ?? 'Sin comentario confidencial';
            final estrellas = datos['estrellas'] ?? 0;
            final autor = datos['uid_alumno'] ?? 'Anónimo';
            final tutorRefId = doc.reference.parent.parent?.id ?? 'Desconocido';

            DateTime? fecha;
            try {
              if (fechaStr.isNotEmpty) fecha = DateTime.parse(fechaStr);
            } catch (_) {}

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          '${estrellas is int ? estrellas.toStringAsFixed(1) : (estrellas as double).toStringAsFixed(1)} Estrellas',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (fecha != null)
                          Text(
                            '${fecha.day}/${fecha.month}/${fecha.year}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Ocultar Público',
                          onPressed: () {
                            doc.reference.update({
                              'comentario_publico':
                                  '[Eliminado por Moderación]',
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Comentario público eliminado.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      'Tutor Evaluado ID: $tutorRefId',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueAccent,
                      ),
                    ),
                    Text(
                      'Autor ID: $autor',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Comentario Público:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"$publico"',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Comentario Privado (Solo Admin):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"$privado"',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
