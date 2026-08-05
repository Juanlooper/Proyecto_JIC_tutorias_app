import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MensajeChat {
  final String id;
  final String emisorId;
  final String emisorNombre;
  final String texto;
  final DateTime fechaHora;
  final String? respuestaA;
  final String? textoRespuesta;

  MensajeChat({
    required this.id,
    required this.emisorId,
    required this.emisorNombre,
    required this.texto,
    required this.fechaHora,
    this.respuestaA,
    this.textoRespuesta,
  });

  factory MensajeChat.fromMap(String key, Map<String, dynamic> map) {
    return MensajeChat(
      id: key,
      emisorId: map['emisorId'] ?? '',
      emisorNombre: map['emisorNombre'] ?? 'Usuario',
      texto: map['texto'] ?? '',
      fechaHora: map['fechaHora'] != null
          ? (map['fechaHora'] as Timestamp).toDate()
          : DateTime.now(),
      respuestaA: map['respuestaA'],
      textoRespuesta: map['textoRespuesta'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emisorId': emisorId,
      'emisorNombre': emisorNombre,
      'texto': texto,
      'fechaHora': Timestamp.fromDate(fechaHora),
      if (respuestaA != null) 'respuestaA': respuestaA,
      if (textoRespuesta != null) 'textoRespuesta': textoRespuesta,
    };
  }
}

class ChatServicio {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Retorna un Stream con los mensajes de una tutoría ordenados por fecha.
  Stream<List<MensajeChat>> obtenerMensajesDeTutoria(String tutoriaId) {
    // Cálculo seguro de la ventana de tiempo (últimas 24 horas)
    final ventana24H = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));

    return _db
        .collection('tutorias')
        .doc(tutoriaId)
        .collection('chat')
        .where('fechaHora', isGreaterThanOrEqualTo: ventana24H)
        .orderBy('fechaHora', descending: false)
        .snapshots()
        .map((snapshot) {
          List<MensajeChat> mensajesRecientes = [];
          for (var doc in snapshot.docs) {
            final msg = MensajeChat.fromMap(doc.id, doc.data());

            mensajesRecientes.add(msg);
          }

          return mensajesRecientes;
        });
  }

  /// Envía un mensaje al nodo de la tutoría específica.
  Future<void> enviarMensaje({
    required String tutoriaId,
    required String emisorId,
    required String emisorNombre,
    required String texto,
    String? respuestaA,
    String? textoRespuesta,
  }) async {
    try {
      final collectionRef = _db
          .collection('tutorias')
          .doc(tutoriaId)
          .collection('chat');
      final nuevoDoc = collectionRef.doc();

      final nuevoMensaje = MensajeChat(
        id: nuevoDoc.id,
        emisorId: emisorId,
        emisorNombre: emisorNombre,
        texto: texto,
        fechaHora: DateTime.now(),
        respuestaA: respuestaA,
        textoRespuesta: textoRespuesta,
      );

      await nuevoDoc.set(nuevoMensaje.toMap());
    } catch (e) {
      debugPrint('Error al enviar mensaje de chat en Firestore: $e');
      throw Exception('Error de red al enviar mensaje.');
    }
  }

  /// Elimina un mensaje específico del chat (Ej. el usuario se arrepiente)
  Future<void> eliminarMensaje(String tutoriaId, String mensajeId) async {
    try {
      await _db
          .collection('tutorias')
          .doc(tutoriaId)
          .collection('chat')
          .doc(mensajeId)
          .delete();
    } catch (e) {
      debugPrint('Error al eliminar mensaje en Firestore: $e');
      throw Exception('Error al eliminar el mensaje.');
    }
  }

  /// Elimina la subcolección completa del chat usando un Batch Delete
  Future<void> eliminarChatCompleto(String tutoriaId) async {
    try {
      final collectionRef = _db
          .collection('tutorias')
          .doc(tutoriaId)
          .collection('chat');
      final snapshot = await collectionRef.get();

      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error al borrar nodo completo de chat en Firestore: $e');
    }
  }
}
