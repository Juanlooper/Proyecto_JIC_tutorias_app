import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class TribunalBaneosView extends StatelessWidget {
  const TribunalBaneosView({super.key});

  Future<void> _perdonarBaneo(
    BuildContext context,
    String docId,
    String nombre,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(docId).update(
        {'esta_baneado': false, 'strikes_inasistencia': 0},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La cuenta de $nombre ha sido perdonada y restaurada.',
            ),
            backgroundColor: AppTheme.primarioVerde,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar la restauración.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _perdonarExcusa(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('reportes_tribunal').doc(docId).update({
        'estado': 'perdonado'
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excusa aceptada. No se aplicó strike.'), backgroundColor: AppTheme.primarioVerde));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al perdonar.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _penalizarExcusa(BuildContext context, String reporteId, String alumnoId) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final reporteRef = FirebaseFirestore.instance.collection('reportes_tribunal').doc(reporteId);
        final usuarioRef = FirebaseFirestore.instance.collection('usuarios').doc(alumnoId);
        
        final usuarioSnap = await transaction.get(usuarioRef);
        if (usuarioSnap.exists) {
          final strikesActuales = usuarioSnap.data()?['strikes_inasistencia'] ?? 0;
          final nuevosStrikes = strikesActuales + 1;
          
          Map<String, dynamic> actualizacion = {'strikes_inasistencia': nuevosStrikes};
          if (nuevosStrikes >= 3) actualizacion['esta_baneado'] = true;
          
          transaction.update(usuarioRef, actualizacion);
          transaction.update(reporteRef, {'estado': 'penalizado'});
        }
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Strike aplicado exitosamente.'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al penalizar.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.fondoClaro,
        appBar: AppBar(
          title: const Text('Tribunal de Disciplina'),
          backgroundColor: Colors.red.shade800,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: "Excusas Pendientes"),
              Tab(icon: Icon(Icons.block), text: "Estudiantes Baneados"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabExcusas(),
            _buildTabBaneados(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabExcusas() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reportes_tribunal')
          .where('estado', isEqualTo: 'pendiente')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('Sin excusas pendientes', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        final reportes = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reportes.length,
          itemBuilder: (context, index) {
            final doc = reportes[index];
            final data = doc.data() as Map<String, dynamic>;
            final alumnoId = data['alumnoId'] ?? '';
            final materia = data['materia'] ?? 'Tutoría';
            final excusa = data['excusa'] ?? 'Sin motivo provisto';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Materia: $materia', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Alumno ID: $alumnoId', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const Divider(),
                    const Text('Justificación dada:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text('"$excusa"', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: Colors.green),
                            onPressed: () => _perdonarExcusa(context, doc.id),
                            icon: const Icon(Icons.thumb_up),
                            label: const Text('Perdonar'),
                          ),
                        ),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                            onPressed: () => _penalizarExcusa(context, doc.id, alumnoId),
                            icon: const Icon(Icons.warning),
                            label: const Text('Dar Strike'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabBaneados() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .where('strikes_inasistencia', isGreaterThanOrEqualTo: 3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.red));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No hay estudiantes baneados', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('La disciplina universitaria está en orden.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final baneados = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: baneados.length,
          itemBuilder: (context, index) {
            final doc = baneados[index];
            final data = doc.data() as Map<String, dynamic>;
            final nombre = data['nombreCompleto'] ?? 'Desconocido';
            final correo = data['correoElectronico'] ?? 'Sin correo';
            final strikes = data['strikes_inasistencia'] ?? 0;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade200, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.red.shade50,
                          child: const Icon(Icons.block, color: Colors.red, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(correo, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                                child: Text('Strikes acumulados: $strikes', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), foregroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Restaurar Cuenta'),
                              content: Text('¿Deseas retirar el baneo y perdonar los $strikes strikes de $nombre?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _perdonarBaneo(context, doc.id, nombre);
                                  },
                                  child: const Text('Confirmar Perdón'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.health_and_safety_outlined),
                        label: const Text('Perdonar / Restaurar Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
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
