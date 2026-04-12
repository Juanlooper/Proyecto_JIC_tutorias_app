import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio especializado en la gestión de metadatos de usuario.
/// Centraliza la edición de perfiles para auditoría y seguridad.
class UsuarioServicio {
  final FirebaseFirestore _baseDeDatos = FirebaseFirestore.instance;

  /// Actualiza los campos académicos en Firestore.
  /// REGLA DE NEGOCIO: No permite la edición del Rol desde esta función.
  Future<bool> actualizarDatosAcademicos({
    required String idUsuario,
    required String nuevaFacultad,
    required String nuevaCarrera,
  }) async {
    try {
      await _baseDeDatos.collection('usuarios').doc(idUsuario).update({
        'facultad': nuevaFacultad,
        'carrera': nuevaCarrera,
      });
      return true;
    } catch (e) {
      // Registro de error para auditoría técnica
      return false;
    }
  }
}
