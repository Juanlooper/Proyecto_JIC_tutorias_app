import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../models/usuario_model.dart';

class BuzonPostulacionesView extends StatelessWidget {
  const BuzonPostulacionesView({super.key});

  Future<void> _actualizarEstadoPostulacion(
    BuildContext context,
    String docId,
    String nombre,
    bool aprobado,
  ) async {
    try {
      final actualizacion = aprobado
          ? {
              'rolEnElSistema': RolSistema.tutor.name,
              'estado_solicitud_tutor': 'aprobado',
            }
          : {'estado_solicitud_tutor': 'ninguna'};

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(docId)
          .update(actualizacion);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              aprobado
                  ? 'Solicitud aprobada. $nombre ahora es un Tutor Oficial.'
                  : 'Solicitud rechazada. $nombre podrá intentar nuevamente.',
            ),
            backgroundColor: aprobado ? AppTheme.primarioVerde : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al accionar la postulación.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Postulaciones de Tutores'),
        backgroundColor: Colors.blueAccent.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('estado_solicitud_tutor', isEqualTo: 'en_revision')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al conectar con el servidor.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay postulaciones nuevas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'El buzón de solicitudes para tutores está vacío.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final postulantes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: postulantes.length,
            itemBuilder: (context, index) {
              final doc = postulantes[index];
              final data = doc.data() as Map<String, dynamic>;
              final nombre = data['nombreCompleto'] ?? 'Desconocido';
              final correo = data['correoElectronico'] ?? 'Sin correo';
              final facultad = data['facultad'] ?? 'Facultad no especificada';
              final carrera = data['carrera'] ?? 'Carrera no especificada';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade200, width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.shade50,
                            child: const Icon(
                              Icons.school,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  correo,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Antecedentes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('• Facultad: $facultad'),
                      Text('• Carrera: $carrera'),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () => _actualizarEstadoPostulacion(
                                context,
                                doc.id,
                                nombre,
                                false,
                              ),
                              icon: const Icon(Icons.close),
                              label: const Text('Rechazar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primarioVerde,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () => _actualizarEstadoPostulacion(
                                context,
                                doc.id,
                                nombre,
                                true,
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text('Aprobar'),
                            ),
                          ),
                        ],
                      ),
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
