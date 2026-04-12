import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Proveedor para manejar el Buzon de Alertas y Retencion del Estudiante.
/// Construido para centralizar las campanas de notificaciones de Alejandra y dotarla de vida.
class NotificacionesProvider extends ChangeNotifier {
  final FirebaseFirestore _fabricaDeDatos = FirebaseFirestore.instance;

  /// Mecanismo que regula si Alejandra debe encender giros de carga en las interfaces de notificacion.
  bool _estaCargando = false;

  bool get estaCargando => _estaCargando;

  /// Representa las cartas y mensajes acumulados dirigidos exclusivamente hacia este usuario.
  List<Map<String, dynamic>> _listaDeAvisosTotales = [];

  List<Map<String, dynamic>> get listaDeAvisosTotales => _listaDeAvisosTotales;

  /// Retorna el numero matematico de cuentas que Alejandra usa para pintar la temida "burbuja roja" en la campana.
  int get totalNoLeidas {
    int conteoNotificaciones = 0;
    for (var aviso in _listaDeAvisosTotales) {
      if (aviso['leida'] == false) {
        conteoNotificaciones++;
      }
    }
    return conteoNotificaciones;
  }

  /// Conecta a la base y filtra de forma eficiente solo los mensajes de este participante.
  Future<void> descargarBuzon(String idDestinatario) async {
    _estaCargando = true;
    notifyListeners();

    try {
      // Descargando documentos de una nueva colección "notificaciones"
      QuerySnapshot lecturaActiva = await _fabricaDeDatos
          .collection('notificaciones')
          .where('idDestinatario', isEqualTo: idDestinatario)
          .get();

      _listaDeAvisosTotales = lecturaActiva.docs.map((hojaDocumento) {
        var contenidoTextual = hojaDocumento.data() as Map<String, dynamic>;
        // Inyectamos su identificador de documento para cuando querramos alterarlo
        contenidoTextual['idDocumentoRaiz'] = hojaDocumento.id;
        return contenidoTextual;
      }).toList();
    } catch (fallaConectiva) {
      // Optamos por silencio tecnico y resiliencia si la red falla en leer notificaciones no vitales
    }

    _estaCargando = false;
    notifyListeners();
  }

  /// Limpia visual y estructuralmente un aviso marcandolo positivamente.
  Future<void> marcarComoLeida(String idNotificacion) async {
    // 1. Efecto Optico Inmediato (Para que Alejandra sea ultrarrapida a los ojos humanos)
    int indiceBuscado = _listaDeAvisosTotales.indexWhere(
      (n) => n['idDocumentoRaiz'] == idNotificacion,
    );
    if (indiceBuscado != -1) {
      _listaDeAvisosTotales[indiceBuscado]['leida'] = true;
      notifyListeners();
    }

    // 2. Comunicacion Silenciosa en Background (Para que Maiky asiente el cambio contable oficial)
    try {
      await _fabricaDeDatos
          .collection('notificaciones')
          .doc(idNotificacion)
          .update({'leida': true});
    } catch (fallaRemota) {
      // Revertimos solo si es mortalmente necesario
    }
  }
}
