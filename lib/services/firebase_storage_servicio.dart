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
  Future<Map<String, String>?> seleccionarYSubirArchivo({
    required String carpetaDestino,
  }) async {
    try {
      // 1. Selector de Archivos Restringido (HCI: Prevención de errores / seguridad)
      FilePickerResult? resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
          'ppt',
          'pptx',
        ],
        withData:
            true, // ¡Obligatorio para que Flutter Web pueda leer los bytes!
      );

      // Si el usuario da "Atrás" sin seleccionar nada
      if (resultado == null) {
        return null;
      }

      final file = resultado.files.single;

      // En web, 'path' es null, por lo que debemos verificar 'bytes'
      if (kIsWeb && file.bytes == null) {
        return null;
      } else if (!kIsWeb && file.path == null) {
        return null;
      }

      // Validación Estricta de Tamaño (Límite: 5MB)
      final sizeEnBytes = file.size;
      final maximoPermitido = 5 * 1024 * 1024; // 5 MB
      if (sizeEnBytes > maximoPermitido) {
        debugPrint("Error de Seguridad: Archivo excede el límite de 5MB.");
        throw Exception("El archivo es demasiado pesado (Máximo 5MB).");
      }

      String extensionBase = file.extension ?? 'bin';
      String nombreOriginal = file.name;

      // Obtener el identificador del usuario para saber quién es dueño del almacenamiento (trazabilidad)
      final uidActual =
          FirebaseAuth.instance.currentUser?.uid ?? 'usuario_anonimo';

      // Nomenclatura del archivo en el Storage (Anti-Colisiones)
      String marcaDeTiempo = DateTime.now().millisecondsSinceEpoch.toString();
      String nombreSeguroDelArchivo =
          'adjunto_${uidActual}_$marcaDeTiempo.$extensionBase';

      // Ruta dentro del bucket de Firebase (por ejemplo: tutorias_archivos/adjunto_uid_123.pdf)
      String rutaEnBucket = '$carpetaDestino/$nombreSeguroDelArchivo';

      // Proceso de Subida Multi-plataforma (Web vs Mobile/Desktop)
      final ref = _storage.ref().child(rutaEnBucket);
      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = ref.putData(file.bytes!);
      } else {
        File archivoFisico = File(file.path!);
        uploadTask = ref.putFile(archivoFisico);
      }

      // Esperar a que la subida termine
      final snapshot = await uploadTask;

      // 4. Extracción de Llink Público Seguro
      final stringPublicoSeguro = await snapshot.ref.getDownloadURL();

      return {'url': stringPublicoSeguro, 'nombre': nombreOriginal};
    } catch (e) {
      debugPrint("Fallo crítico durante el intento de subida al Storage: $e");
      // Lanzamos la excepción para que la UI sepa exactamente qué falló (ej. error de CORS cacheado)
      throw Exception(e.toString());
    }
  }

  /// Permite seleccionar y subir hasta 3 archivos, devolviendo una lista de mapas con 'url' y 'nombre'.
  Future<List<Map<String, String>>> seleccionarYSubirMultiplesArchivos({
    required String carpetaDestino,
  }) async {
    try {
      FilePickerResult? resultado = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
          'ppt',
          'pptx',
        ],
        withData: true,
      );

      if (resultado == null) return [];

      List<PlatformFile> archivos = resultado.files;
      if (archivos.length > 3) {
        throw Exception(
          "Solo se permite adjuntar un máximo de 3 archivos. Se recomienda unir todo en un solo PDF o DOCX.",
        );
      }

      List<Map<String, String>> archivosSubidos = [];
      final uidActual =
          FirebaseAuth.instance.currentUser?.uid ?? 'usuario_anonimo';

      for (var file in archivos) {
        if (kIsWeb && file.bytes == null) continue;
        if (!kIsWeb && file.path == null) continue;

        if (file.size > 5 * 1024 * 1024) {
          throw Exception(
            "El archivo ${file.name} es demasiado pesado (Máximo 5MB).",
          );
        }

        String extensionBase = file.extension ?? 'bin';
        String nombreOriginal = file.name;
        String marcaDeTiempo = DateTime.now().millisecondsSinceEpoch.toString();
        // Agregamos un hash simple basado en el nombre para evitar colisiones si se suben varios rápido
        String nombreSeguro =
            'adjunto_${uidActual}_${marcaDeTiempo}_${nombreOriginal.hashCode}.$extensionBase';
        String rutaEnBucket = '$carpetaDestino/$nombreSeguro';

        final ref = _storage.ref().child(rutaEnBucket);
        UploadTask uploadTask;

        if (kIsWeb) {
          uploadTask = ref.putData(file.bytes!);
        } else {
          uploadTask = ref.putFile(File(file.path!));
        }

        final snapshot = await uploadTask;
        final stringPublicoSeguro = await snapshot.ref.getDownloadURL();

        archivosSubidos.add({
          'url': stringPublicoSeguro,
          'nombre': nombreOriginal,
        });
      }

      return archivosSubidos;
    } catch (e) {
      debugPrint("Error subiendo múltiples archivos: $e");
      throw Exception(e.toString());
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
