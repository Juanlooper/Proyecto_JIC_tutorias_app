import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notificaciones_servicio.dart';

/// Servicio encargado de la moderación, quejas y el Tribunal de Disciplina.
class TribunalServicio {
  final NotificacionesServicio _notificacionesSvc = NotificacionesServicio();

  /// Reporta automáticamente a un tutor por cancelación tardía.
  Future<void> reportarCancelacionTardia({
    required String tutorId,
    required String tutoriaId,
    required String materia,
    required String justificacion,
  }) async {
    try {
      // Registrar queja formal
      await FirebaseFirestore.instance.collection('quejas').add({
        'tutorId': tutorId,
        'tutoriaId': tutoriaId,
        'fechaQueja': DateTime.now().toIso8601String(),
        'motivo_sistema': 'Cancelación tardía (Menos de 12h) - $materia',
        'justificacion_brindada': justificacion,
      });

      // Registrar excusa para evaluación
      if (justificacion.trim().isNotEmpty) {
        await FirebaseFirestore.instance.collection('reportes_tribunal').add({
          'tutorId': tutorId,
          'tutoriaId': tutoriaId,
          'materia': materia,
          'fechaCancelacion': DateTime.now().toIso8601String(),
          'excusa': justificacion,
          'estado': 'pendiente',
        });

        await _notificacionesSvc.notificarAdministradores(
          'Nueva Excusa en Tribunal ⚖️',
          'El tutor $tutorId canceló tarde ($materia) y presentó una justificación.',
        );
      }
    } catch (e) {
      debugPrint('Error enviando reporte al tribunal: $e');
    }
  }

  /// Procesa strikes de estudiantes que no asistieron y evalúa si merecen ban.
  Future<void> procesarInasistenciaEstudiante(
    String uidAlumno,
    String tutoriaId,
  ) async {
    try {
      final usuarioRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uidAlumno);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final usuarioSnapshot = await transaction.get(usuarioRef);
        if (usuarioSnapshot.exists) {
          final datosUsuario = usuarioSnapshot.data()!;
          
          // Prevención de redundancia: si ya está baneado, no gastamos escrituras.
          if (datosUsuario['esta_baneado'] == true) return;

          final strikesActuales = datosUsuario['strikes_inasistencia'] ?? 0;
          final nuevosStrikes = strikesActuales + 1;

          Map<String, dynamic> actualizacion = {
            'strikes_inasistencia': nuevosStrikes,
          };

          if (nuevosStrikes >= 3) {
            actualizacion['esta_baneado'] = true;
          }

          transaction.update(usuarioRef, actualizacion);
        }
      });

      await _notificacionesSvc.notificarAdministradores(
        'Alerta Administrativa: Strike',
        'El alumno $uidAlumno recibió un strike por inasistencia en tutoría $tutoriaId.',
        tipo: 'alerta_roja',
      );
    } catch (e) {
      debugPrint('Error procesando inasistencia de $uidAlumno: $e');
    }
  }
}
