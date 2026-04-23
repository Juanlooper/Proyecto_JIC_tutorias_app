import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class QuejasView extends StatelessWidget {
  final bool ocultarAppBar;

  const QuejasView({super.key, this.ocultarAppBar = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoClaro,
      appBar: ocultarAppBar ? null : AppBar(
        title: const Text('Registro de Quejas'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('quejas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al conectar con la base de datos'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Ninguna queja o cancelación tardía registrada.', style: TextStyle(color: Colors.grey)),
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
                              fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year} - ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}' : 'Fecha Desconocida',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              FirebaseFirestore.instance.collection('quejas').doc(actas[index].id).delete();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Tutor ID: $tutorId', style: const TextStyle(fontSize: 13, color: Colors.blueAccent)),
                      const SizedBox(height: 4),
                      Text('Clase ID: $tutoriaId', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      const Divider(height: 24),
                      const Text('Justificación de cancelación:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('"$justificacion"', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
