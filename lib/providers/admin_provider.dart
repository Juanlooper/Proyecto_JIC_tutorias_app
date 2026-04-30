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

  // Variables de métricas avanzadas (Gráficas)
  Map<String, double> horasPorTutor = {};
  Map<String, double> horasPorMateria = {};
  Map<String, double> horasPorEstudiante = {};

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

      // 4. Inscripciones y Métricas Complejas.
      // Traemos las tutorías para procesar las sumas en local.
      final snapshotTutorias = await _baseDeDatosOperativa.collection('tutorias').get();
      int acumuladorInscripciones = 0;
      
      horasPorTutor.clear();
      horasPorMateria.clear();
      horasPorEstudiante.clear();

      for (var documento in snapshotTutorias.docs) {
        final data = documento.data();
        final listaAlumnos = data['listaDeEstudiantesInscritos'] as List?;
        acumuladorInscripciones += listaAlumnos?.length ?? 0;

        // Cálculos de horas (solo clases finalizadas)
        if (data['estadoDeLaSolicitud'] == 'finalizada') {
          double horas = (data['duracionMinutos'] ?? 60) / 60.0;
          
          final tutorNombre = data['nombre_tutor'] ?? 'Tutor Desconocido';
          horasPorTutor[tutorNombre] = (horasPorTutor[tutorNombre] ?? 0) + horas;

          final materia = data['materiaOAsignatura'] ?? 'Materia Desconocida';
          horasPorMateria[materia] = (horasPorMateria[materia] ?? 0) + horas;

          if (listaAlumnos != null) {
            for (var uidAlumno in listaAlumnos) {
              horasPorEstudiante[uidAlumno.toString()] = (horasPorEstudiante[uidAlumno.toString()] ?? 0) + horas;
            }
          }
        }
      }
      inscripcionesTotales = acumuladorInscripciones;

    } catch (error) {
      debugPrint("Error al cargar métricas de admin: $error");
    }

    _estaCargando = false;
    notifyListeners();
  }
}