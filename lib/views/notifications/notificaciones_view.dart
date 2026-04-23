import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/autenticacion_provider.dart';
import '../../core/theme/app_theme.dart';

class NotificacionesView extends StatelessWidget {
  const NotificacionesView({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AutenticacionProvider>().usuarioActual;

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notificaciones')),
        body: const Center(child: Text('Debes iniciar sesión.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primarioAzul,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: AppTheme.fondoClaro,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notificaciones')
            .where('usuarioId', isEqualTo: usuario.identificadorUnico)
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primarioAzul));
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar notificaciones."));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones nuevas.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final notificacionId = docs[index].id;
              final titulo = data['titulo'] ?? 'Notificación';
              final mensaje = data['mensaje'] ?? '';
              final leida = data['leida'] ?? false;
              final fechaRaw = data['fecha'] ?? '';
              
              DateTime? fecha;
              try {
                fecha = DateTime.parse(fechaRaw);
              } catch (_) {}

              final fechaStr = fecha != null 
                  ? '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')} - ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')} Hrs'
                  : '';

              return Card(
                elevation: leida ? 0 : 2,
                color: leida ? Colors.grey.shade100 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: leida ? Colors.grey.shade300 : AppTheme.primarioAzul.withValues(alpha: 0.3),
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: leida ? Colors.grey.shade300 : AppTheme.primarioAzul.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.notifications,
                      color: leida ? Colors.grey.shade600 : AppTheme.primarioAzul,
                    ),
                  ),
                  title: Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: leida ? FontWeight.normal : FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(mensaje, style: TextStyle(color: Colors.grey.shade700)),
                      if (fechaStr.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(fechaStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ]
                    ],
                  ),
                  onTap: () {
                    if (!leida) {
                      FirebaseFirestore.instance.collection('notificaciones').doc(notificacionId).update({
                        'leida': true,
                      });
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
