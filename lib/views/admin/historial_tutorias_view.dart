import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialTutoriasView extends StatelessWidget {
  const HistorialTutoriasView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial Global de Tutorías'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tutorias').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
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
                'Registro de tutorías vacío.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final tutorias = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tutorias.length,
            itemBuilder: (context, index) {
              final tutoData = tutorias[index].data() as Map<String, dynamic>;
              final materia = tutoData['materiaOAsignatura'] ?? 'Desconocida';
              final estado = tutoData['estadoDeLaSolicitud'] ?? 'solicitada';
              final tutorId = tutoData['identificadorDelTutor'] ?? 'N/A';
              final cuposRestantes = tutoData['cuposDisponiblesRestantes'] ?? 0;
              final inscritos =
                  (tutoData['listaDeEstudiantesInscritos'] as List<dynamic>? ??
                          [])
                      .length;

              Color colorEstado = Colors.grey;
              if (estado == 'pendiente' || estado == 'solicitada') {
                colorEstado = Colors.orange;
              }
              if (estado == 'aceptada' || estado == 'abierta') {
                colorEstado = Colors.blue;
              }
              if (estado == 'finalizada') colorEstado = Colors.green;
              if (estado == 'cancelada') colorEstado = Colors.red;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              materia,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorEstado.withValues(alpha: 0.1),
                              border: Border.all(color: colorEstado),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              estado.toUpperCase(),
                              style: TextStyle(
                                color: colorEstado,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tutor UID: $tutorId',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Alumnos inscritos: $inscritos | Cupos restantes: $cuposRestantes',
                        style: const TextStyle(fontSize: 13),
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
