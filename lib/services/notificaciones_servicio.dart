import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio responsable de manejar los permisos de notificaciones push nativas
/// y extraer el token único del dispositivo para enviarle alertas dirigidas.
class NotificacionesServicio {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Solicita permisos al SO y recupera el FCM Token si son concedidos.
  Future<void> inicializarYObtenerToken() async {
    try {
      // 1. Pedir permisos al sistema (Especialmente importante en iOS y Android 13+)
      NotificationSettings configuracion = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (configuracion.authorizationStatus == AuthorizationStatus.authorized ||
          configuracion.authorizationStatus == AuthorizationStatus.provisional) {
        
        debugPrint('Permisos de notificación concedidos al sistema.');
        
        // 2. Obtener el Token identificador del teléfono/emulador
        String? tokenFCM = await _messaging.getToken();
        debugPrint('FCM Token Extraído: $tokenFCM');
        
        if (tokenFCM != null) {
          await _guardarTokenEnFirestore(tokenFCM);
        }

        // 3. Dejar un listener permanente por si el SO decide cambiar el token por seguridad
        _messaging.onTokenRefresh.listen((nuevoToken) {
          _guardarTokenEnFirestore(nuevoToken);
        });

      } else {
        debugPrint('El usuario denegó los permisos de notificación.');
      }
    } catch (e) {
      debugPrint('Error inicializando el motor de notificaciones (FCM): $e');
    }
  }

  /// Actualiza o inyecta el token en el perfil del usuario activo
  Future<void> _guardarTokenEnFirestore(String token) async {
    final uidUsuario = FirebaseAuth.instance.currentUser?.uid;
    if (uidUsuario != null) {
      try {
        await FirebaseFirestore.instance.collection('usuarios').doc(uidUsuario).set({
          'token_dispositivo': token,
        }, SetOptions(merge: true)); // Se usa merge para no sobreescribir otros datos
      } catch (e) {
        debugPrint('Fallo al guardar el token de dispositivo en la nube: $e');
      }
    }
  }
  /// Crea una notificación individual para un usuario.
  Future<void> crearNotificacion({
    required String usuarioId,
    required String titulo,
    required String mensaje,
    String tipo = 'info',
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notificaciones').add({
        'usuarioId': usuarioId,
        'titulo': titulo,
        'mensaje': mensaje,
        'fecha': DateTime.now().toIso8601String(),
        'leida': false,
        'tipo': tipo,
      });
    } catch (e) {
      debugPrint("Error creando notificación individual: $e");
    }
  }

  /// Envía notificaciones de forma masiva a un grupo de usuarios.
  Future<void> notificarMultiples({
    required List<String> uids,
    required String titulo,
    required String mensaje,
    String tipo = 'info',
  }) async {
    for (var uid in uids) {
      await crearNotificacion(usuarioId: uid, titulo: titulo, mensaje: mensaje, tipo: tipo);
    }
  }

  /// Notifica inmediatamente a todo el staff de administradores del sistema.
  Future<void> notificarAdministradores(String titulo, String mensaje, {String tipo = 'alerta_admin'}) async {
    try {
      final adminsSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rolEnElSistema', isEqualTo: 'admin')
          .get();

      final fechaIso = DateTime.now().toIso8601String();
      for (var doc in adminsSnapshot.docs) {
        await FirebaseFirestore.instance.collection('notificaciones').add({
          'usuarioId': doc.id,
          'titulo': titulo,
          'mensaje': mensaje,
          'fecha': fechaIso,
          'leida': false,
          'tipo': tipo,
        });
      }
    } catch (e) {
      debugPrint('Error al notificar administradores: $e');
    }
  }
}
