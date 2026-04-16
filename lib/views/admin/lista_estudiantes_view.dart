import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class ListaEstudiantesView extends StatelessWidget {
  const ListaEstudiantesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoClaro,
      appBar: AppBar(
        title: const Text('Padrón de Estudiantes Activos'),
        backgroundColor: AppTheme.primarioAzul,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').where('rolEnElSistema', isEqualTo: 'estudiante').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al conectar con la base de datos'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay estudiantes inscritos en la plataforma.', style: TextStyle(color: Colors.grey)),
            );
          }

          final estudiantes = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: estudiantes.length,
            itemBuilder: (context, index) {
              final userData = estudiantes[index].data() as Map<String, dynamic>;
              final nombre = userData['nombreCompleto'] ?? 'Desconocido';
              final correo = userData['correoElectronico'] ?? 'Sin correo';
              final strikes = userData['strikes_inasistencia'] ?? 0;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(correo),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: strikes > 0 ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Strikes: $strikes',
                      style: TextStyle(
                        color: strikes > 0 ? Colors.red.shade900 : Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
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
