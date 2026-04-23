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
}
