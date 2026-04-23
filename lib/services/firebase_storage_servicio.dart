import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Servicio responsable de manejar la subida y bajada de documentos/imágenes nativas del dispositivo a Firebase Storage.
class FirebaseStorageServicio {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Abre un explorador de archivos nativo permitiendo al usuario seleccionar un PDF, JPG, PNG, etc.
  /// Luego, valida que el archivo no exceda los 5MB para prevenir malware oculto y sobrecarga,
  /// lo sube e inyecta la URL de descarga directa generada por Firebase Storage.
  /// 
  /// Retorna un mapa con {'url': ..., 'nombre': ...} si la subida fue exitosa, o null si falló/canceló.
  Future<Map<String, String>?> seleccionarYSubirArchivo({required String carpetaDestino}) async {
    try {
      // 1. Selector de Archivos Restringido (HCI: Prevención de errores / seguridad)
      FilePickerResult? resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'ppt', 'pptx'],
      );

      // Si el usuario da "Atrás" sin seleccionar nada
      if (resultado == null || resultado.files.single.path == null) {
        return null;
      }

      // Validación Estricta de Tamaño (Límite: 5MB)
      final sizeEnBytes = resultado.files.single.size;
      final maximoPermitido = 5 * 1024 * 1024; // 5 MB
      if (sizeEnBytes > maximoPermitido) {
        // En una app más estructurada, esto lanzaría una excepción que la UI atraparía
        debugPrint("Error de Seguridad: Archivo excede el límite de 5MB.");
        throw Exception("El archivo es demasiado pesado (Máximo 5MB).");
      }

      // Preparación del Archivo Local
      File archivoFisico = File(resultado.files.single.path!);
      String extensionBase = resultado.files.single.extension ?? 'bin';
      String nombreOriginal = resultado.files.single.name;
      
      // Obtener el identificador del usuario para saber quién es dueño del almacenamiento (trazabilidad)
      final uidActual = FirebaseAuth.instance.currentUser?.uid ?? 'usuario_anonimo';
      
      // 2. Nomenclatura del archivo en el Storage (Anti-Colisiones)
      String marcaDeTiempo = DateTime.now().millisecondsSinceEpoch.toString();
      String nombreSeguroDelArchivo = 'adjunto_${uidActual}_$marcaDeTiempo.$extensionBase';
      
      // Ruta dentro del bucket de Firebase (por ejemplo: tutorias_archivos/adjunto_uid_123.pdf)
      String rutaEnBucket = '$carpetaDestino/$nombreSeguroDelArchivo';

      // 3. Proceso de Subida
      final ref = _storage.ref().child(rutaEnBucket);
      final uploadTask = ref.putFile(archivoFisico);

      // (Opcional) Podemos escuchar el progreso, sin embargo, la subida será pequeña (< 5MB) en la mayoría de casos
      final snapshot = await uploadTask;
      
      // 4. Extracción de Llink Público Seguro
      final stringPublicoSeguro = await snapshot.ref.getDownloadURL();
      
      return {
        'url': stringPublicoSeguro,
        'nombre': nombreOriginal
      };

    } catch (e) {
      debugPrint("Fallo crítico durante el intento de subida al Storage: $e");
      // Si lanzamos un error sobre el peso, queremos que llegue a la UI
      if (e.toString().contains('5MB')) rethrow;
      return null;
    }
  }

  /// Método inteligente que se encarga de localizar el archivo físico en el bucket a través
  /// de su URL pública y eliminarlo para mantener el costo en cero.
  Future<bool> eliminarArchivoFisico(String urlDeDescarga) async {
    try {
      final referencia = _storage.refFromURL(urlDeDescarga);
      await referencia.delete();
      return true;
    } catch (e) {
      debugPrint("No se pudo eliminar el archivo de Storage: $e");
      return false;
    }
  }
}
