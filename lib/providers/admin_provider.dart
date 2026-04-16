import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Central de Métricas Globales para el Dashboard de Administración.
/// Este proveedor suministra los datos exactos que Alejandra diseñó en la interfaz.
class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _baseDeDatosOperativa = FirebaseFirestore.instance;

  bool _estaCargando = false;
  bool get estaCargando => _estaCargando;

  // Variables para las métricas de la interfaz
  int estudiantesActivos = 0;
  int clasesProgramadas = 0;
  int tutoriasFinalizadas = 0;
  int inscripcionesTotales = 0;

  /// Carga todas las estadísticas necesarias para el Dashboard.
  /// Implementa filtros específicos en el servidor para ahorrar datos.
  Future<void> cargarEstadisticasDashboard() async {
    _estaCargando = true;
    notifyListeners();

    try {
      // 1. Estudiantes activos: Contamos solo usuarios con rol de estudiante.
      final queryEstudiantes = await _baseDeDatosOperativa
          .collection('usuarios')
          .where('rolEnElSistema', isEqualTo: 'estudiante')
          .count()
          .get();
      estudiantesActivos = queryEstudiantes.count ?? 0;

      // 2. Clases programadas: Contamos tutorías que están en estado 'pendiente' o 'aceptada'.
      final queryProgramadas = await _baseDeDatosOperativa
          .collection('tutorias')
          .where('estadoDeLaSolicitud', whereIn: ['pendiente', 'aceptada'])
          .count()
          .get();
      clasesProgramadas = queryProgramadas.count ?? 0;

      // 3. Tutorías finalizadas: Conteo de sesiones culminadas exitosamente.
      final queryFinalizadas = await _baseDeDatosOperativa
          .collection('tutorias')
          .where('estadoDeLaSolicitud', isEqualTo: 'finalizada')
          .count()
          .get();
      tutoriasFinalizadas = queryFinalizadas.count ?? 0;

      // 4. Inscripciones totales: Sumatoria de todos los alumnos en todas las tutorías.
      // Nota técnica para Maiky: Firebase count() no suma longitudes de arreglos, 
      // por lo que traemos los documentos para procesar la suma en local.
      final snapshotTutorias = await _baseDeDatosOperativa.collection('tutorias').get();
      int acumuladorInscripciones = 0;
      for (var documento in snapshotTutorias.docs) {
        final listaAlumnos = documento.data()['listaDeEstudiantesInscritos'] as List?;
        acumuladorInscripciones += listaAlumnos?.length ?? 0;
      }
      inscripcionesTotales = acumuladorInscripciones;

    } catch (error) {
      debugPrint("Error al cargar métricas de admin: $error");
    }

    _estaCargando = false;
    notifyListeners();
  }
}