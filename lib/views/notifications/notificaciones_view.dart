import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class NotificacionesView extends StatefulWidget {
  const NotificacionesView({super.key});

  @override
  State<NotificacionesView> createState() => _NotificacionesViewState();
}

class _NotificacionesViewState extends State<NotificacionesView> {
  List<Map<String, dynamic>> _notificaciones = [];
  bool _cargando = true;
  String? _error;
  bool _yaCargoUnaVez = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_yaCargoUnaVez) {
        _yaCargoUnaVez = true;
        _cargarNotificaciones();
      }
    });
  }

  Future<void> _cargarNotificaciones() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _error = "Sesión inactiva.";
          _cargando = false;
        });
      }
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notificaciones')
          .where('usuarioId', isEqualTo: uid)
          .get();

      final lista = querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['docId'] = doc.id;
        return data;
      }).toList();

      lista.sort((a, b) {
        final fechaA = a['fecha'] ?? '';
        final fechaB = b['fecha'] ?? '';
        return fechaB.compareTo(fechaA);
      });

      if (mounted) {
        setState(() {
          _notificaciones = lista;
          _cargando = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('ERROR NOTIFICACIONES: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primarioAzul,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _cargando = true;
                _error = null;
              });
              _cargarNotificaciones();
            },
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primarioAzul),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text("No se pudieron cargar las notificaciones."),
              const SizedBox(height: 8),
              SelectableText(
                _error!,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _cargando = true;
                    _error = null;
                  });
                  _cargarNotificaciones();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notificaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes notificaciones.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notificaciones.length,
      itemBuilder: (context, index) {
        final data = _notificaciones[index];
        final notificacionId = data['docId'] ?? '';
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
              color: leida
                  ? Colors.grey.shade300
                  : AppTheme.primarioAzul.withValues(alpha: 0.3),
            ),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: leida
                  ? Colors.grey.shade300
                  : AppTheme.primarioAzul.withValues(alpha: 0.1),
              child: Icon(
                Icons.notifications,
                color: leida ? Colors.grey.shade600 : AppTheme.primarioAzul,
              ),
            ),
            title: Text(
              titulo,
              style: TextStyle(
                fontWeight: leida ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(mensaje, style: TextStyle(color: Colors.grey.shade700)),
                if (fechaStr.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    fechaStr,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            onTap: () {
              if (!leida && notificacionId.isNotEmpty) {
                FirebaseFirestore.instance
                    .collection('notificaciones')
                    .doc(notificacionId)
                    .update({'leida': true})
                    .catchError((_) {});
                setState(() {
                  _notificaciones[index]['leida'] = true;
                });
              }
            },
          ),
        );
      },
    );
  }
}
