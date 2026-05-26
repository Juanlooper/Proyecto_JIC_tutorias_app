import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class MensajeChat {
  final String id;
  final String emisorId;
  final String emisorNombre;
  final String texto;
  final DateTime fechaHora;

  MensajeChat({
    required this.id,
    required this.emisorId,
    required this.emisorNombre,
    required this.texto,
    required this.fechaHora,
  });

  factory MensajeChat.fromMap(String key, Map<dynamic, dynamic> map) {
    return MensajeChat(
      id: key,
      emisorId: map['emisorId'] ?? '',
      emisorNombre: map['emisorNombre'] ?? 'Usuario',
      texto: map['texto'] ?? '',
      fechaHora: DateTime.tryParse(map['fechaHora'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emisorId': emisorId,
      'emisorNombre': emisorNombre,
      'texto': texto,
      'fechaHora': fechaHora.toIso8601String(),
    };
  }
}

class ChatServicio {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Retorna un Stream con los mensajes de una tutoría ordenados por fecha.
  Stream<List<MensajeChat>> obtenerMensajesDeTutoria(String tutoriaId) {
    return _db.ref('chats/$tutoriaId').orderByChild('fechaHora').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final mensajes = data.entries.map((e) {
        return MensajeChat.fromMap(e.key.toString(), e.value as Map<dynamic, dynamic>);
      }).toList();

      final ahora = DateTime.now();
      List<MensajeChat> mensajesRecientes = [];

      for (var msg in mensajes) {
        if (ahora.difference(msg.fechaHora).inHours >= 24) {
          // Limpieza descentralizada: Borramos el mensaje expirado de la base de datos (Costo 0)
          _db.ref('chats/$tutoriaId/${msg.id}').remove();
        } else {
          mensajesRecientes.add(msg);
        }
      }

      // Ordenar localmente por si Firebase no lo entrega perfectamente ordenado
      mensajesRecientes.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
      return mensajesRecientes;
    });
  }

  /// Envía un mensaje al nodo de la tutoría específica.
  Future<void> enviarMensaje({
    required String tutoriaId,
    required String emisorId,
    required String emisorNombre,
    required String texto,
  }) async {
    try {
      final ref = _db.ref('chats/$tutoriaId').push();
      final nuevoMensaje = MensajeChat(
        id: ref.key ?? '',
        emisorId: emisorId,
        emisorNombre: emisorNombre,
        texto: texto,
        fechaHora: DateTime.now(),
      );
      
      await ref.set(nuevoMensaje.toMap());
    } catch (e) {
      debugPrint('Error al enviar mensaje de chat: $e');
    }
  }
}
