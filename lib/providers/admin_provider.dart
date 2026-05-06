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
  
  // --- NUEVAS MÉTRICAS MÓDULO 4 ---
  double totalHorasImpartidas = 0.0;
  Map<int, double> horasPorSemana = {}; // weekOfYear -> horas
  Map<String, double> horasPorAsignaturaTreemap = {};

  // --- NUEVAS MÉTRICAS MÓDULO 1 ---
  
  // Auditoría de Tutores
  Map<String, double> tasaRetencionTutor = {}; // uid -> % retencion
  Map<String, double> tasaCancelacionTardiaTutor = {}; // uid -> % cancelacion
  Duration slaPromedioGlobal = Duration.zero; // SLA de toda la plataforma
  Map<int, int> distribucionEstrellasGlobal = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  
  // Bienestar Estudiantil
  List<MapEntry<String, int>> materiasCuelloDeBotella = []; // top materias solicitadas
  double indiceDesercionGlobal = 0.0; // % de false en asistencia
  List<Map<String, dynamic>> heavyUsers = []; // uid, horas, nombre

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
      totalHorasImpartidas = 0.0;
      horasPorSemana.clear();
      horasPorAsignaturaTreemap.clear();

      for (var documento in snapshotTutorias.docs) {
        final data = documento.data();
        final listaAlumnos = data['listaDeEstudiantesInscritos'] as List?;
        acumuladorInscripciones += listaAlumnos?.length ?? 0;

        // Cálculos de horas (solo clases finalizadas)
        if (data['estadoDeLaSolicitud'] == 'finalizada') {
          double horas = (data['duracionMinutos'] ?? 60) / 60.0;
          totalHorasImpartidas += horas;

          if (data['fecha_creacion_solicitud'] != null) {
            DateTime? fecha = DateTime.tryParse(data['fecha_creacion_solicitud']);
            if (fecha != null) {
              int weekOfYear = _getWeekOfYear(fecha);
              horasPorSemana[weekOfYear] = (horasPorSemana[weekOfYear] ?? 0) + horas;
            }
          }
          
          final tutorNombre = data['nombre_tutor'] ?? 'Tutor Desconocido';
          horasPorTutor[tutorNombre] = (horasPorTutor[tutorNombre] ?? 0) + horas;

          final materia = data['materiaOAsignatura'] ?? 'Materia Desconocida';
          horasPorMateria[materia] = (horasPorMateria[materia] ?? 0) + horas;
          
          final tema = data['temasAReforzar']?.toString() ?? '';
          String llaveTreemap = tema.isNotEmpty ? '$materia\n$tema' : materia;
          horasPorAsignaturaTreemap[llaveTreemap] = (horasPorAsignaturaTreemap[llaveTreemap] ?? 0) + horas;

          if (listaAlumnos != null) {
            for (var uidAlumno in listaAlumnos) {
              horasPorEstudiante[uidAlumno.toString()] = (horasPorEstudiante[uidAlumno.toString()] ?? 0) + horas;
            }
          }
        }
      }
      inscripcionesTotales = acumuladorInscripciones;

      // ==========================================
      // CÁLCULO DE NUEVAS MÉTRICAS (MÓDULO 1)
      // ==========================================
      
      // 1. Tasa de Retención de Estudiantes por Tutor
      // (Estudiantes que han tomado >1 clase con el tutor) / (Total estudiantes únicos del tutor)
      Map<String, Map<String, int>> clasesPorAlumnoYtutor = {}; // tutorUid -> { alumnoUid -> count }
      
      // 2. SLA Promedio Global
      int countSLA = 0;
      int totalSecondsSLA = 0;

      // 3. Cuello de Botella
      Map<String, int> conteoMateriasSolicitadas = {};

      // 4. Índice de Deserción
      int totalAsistenciasEsperadas = 0;
      int totalInasistencias = 0;

      // 5. Cancelación Tardía
      Map<String, int> totalClasesProgramadasPorTutor = {}; // tutorUid -> count

      for (var doc in snapshotTutorias.docs) {
        final data = doc.data();
        final estado = data['estadoDeLaSolicitud'];
        final tutorId = data['identificadorDelTutor'] as String?;
        final materia = data['materiaOAsignatura'] as String?;
        
        // SLA Promedio
        if (data['fecha_creacion_solicitud'] != null && data['fecha_aceptacion_solicitud'] != null) {
           final creacion = DateTime.tryParse(data['fecha_creacion_solicitud']);
           final aceptacion = DateTime.tryParse(data['fecha_aceptacion_solicitud']);
           if (creacion != null && aceptacion != null && aceptacion.isAfter(creacion)) {
             totalSecondsSLA += aceptacion.difference(creacion).inSeconds;
             countSLA++;
           }
        }

        // Cuello de botella (Materias más solicitadas)
        if (estado == 'solicitada' && materia != null) {
           conteoMateriasSolicitadas[materia] = (conteoMateriasSolicitadas[materia] ?? 0) + 1;
        }

        // Conteo para cancelaciones
        if (tutorId != null && tutorId.isNotEmpty && estado != 'solicitada') {
           totalClasesProgramadasPorTutor[tutorId] = (totalClasesProgramadasPorTutor[tutorId] ?? 0) + 1;
        }

        if (estado == 'finalizada') {
          // Retención
          if (tutorId != null && tutorId.isNotEmpty) {
             clasesPorAlumnoYtutor.putIfAbsent(tutorId, () => {});
             final asistencia = data['registro_asistencia'] as Map<String, dynamic>? ?? {};
             for (var entry in asistencia.entries) {
               if (entry.value == true) { // Solo cuenta si realmente asistió
                 clasesPorAlumnoYtutor[tutorId]![entry.key] = (clasesPorAlumnoYtutor[tutorId]![entry.key] ?? 0) + 1;
               }
             }
          }
          
          // Deserción
          final asistencia = data['registro_asistencia'] as Map<String, dynamic>? ?? {};
          for (var entry in asistencia.entries) {
             totalAsistenciasEsperadas++;
             if (entry.value == false) {
               totalInasistencias++;
             }
          }
        }
      }

      // Finalizar SLA
      if (countSLA > 0) {
        slaPromedioGlobal = Duration(seconds: totalSecondsSLA ~/ countSLA);
      } else {
        slaPromedioGlobal = Duration.zero;
      }

      // Finalizar Cuello de Botella (Top 5)
      var sortedMaterias = conteoMateriasSolicitadas.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      materiasCuelloDeBotella = sortedMaterias.take(5).toList();

      // Finalizar Deserción
      if (totalAsistenciasEsperadas > 0) {
        indiceDesercionGlobal = (totalInasistencias / totalAsistenciasEsperadas) * 100.0;
      } else {
        indiceDesercionGlobal = 0.0;
      }

      // Finalizar Retención por Tutor
      tasaRetencionTutor.clear();
      clasesPorAlumnoYtutor.forEach((tutorId, alumnos) {
        int totalUnicos = alumnos.length;
        if (totalUnicos == 0) {
          tasaRetencionTutor[tutorId] = 0.0;
        } else {
          int repetidores = alumnos.values.where((count) => count > 1).length;
          tasaRetencionTutor[tutorId] = (repetidores / totalUnicos) * 100.0;
        }
      });

      // Calcular Tasa de Cancelación Tardía
      final quejasSnapshot = await _baseDeDatosOperativa.collection('quejas').get();
      Map<String, int> cancelacionesTardiasTutor = {};
      for (var q in quejasSnapshot.docs) {
        final d = q.data();
        if (d['motivo_sistema'] != null && d['motivo_sistema'].toString().contains('Menos de 12h')) {
          String tId = d['tutorId'] ?? '';
          if (tId.isNotEmpty) {
            cancelacionesTardiasTutor[tId] = (cancelacionesTardiasTutor[tId] ?? 0) + 1;
          }
        }
      }
      
      tasaCancelacionTardiaTutor.clear();
      totalClasesProgramadasPorTutor.forEach((tutorId, totalClases) {
        int tardias = cancelacionesTardiasTutor[tutorId] ?? 0;
        if (totalClases > 0) {
          tasaCancelacionTardiaTutor[tutorId] = (tardias / totalClases) * 100.0;
        } else {
          tasaCancelacionTardiaTutor[tutorId] = 0.0;
        }
      });

      // Distribución de Estrellas Global y Heavy Users
      distribucionEstrellasGlobal = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      
      final usuariosSnapshot = await _baseDeDatosOperativa.collection('usuarios').get();
      
      heavyUsers.clear();
      for (var u in usuariosSnapshot.docs) {
        final d = u.data();
        // Heavy Users
        if (d['rolEnElSistema'] == 'estudiante') {
          double horas = horasPorEstudiante[u.id] ?? 0.0;
          if (horas > 0) {
            heavyUsers.add({
              'uid': u.id,
              'nombre': d['nombreCompleto'] ?? d['nombre'] ?? 'Anónimo',
              'horas': horas,
            });
          }
        }
        
        // Estrellas (Revisar subcolección evaluaciones)
        if (d['rolEnElSistema'] == 'tutor') {
           final evals = await u.reference.collection('evaluaciones').get();
           for (var e in evals.docs) {
             final ed = e.data();
             double est = (ed['estrellas'] ?? 5).toDouble();
             int estRound = est.round().clamp(1, 5);
             distribucionEstrellasGlobal[estRound] = (distribucionEstrellasGlobal[estRound] ?? 0) + 1;
           }
        }
      }
      
      // Ordenar Heavy Users desc
      heavyUsers.sort((a, b) => (b['horas'] as double).compareTo(a['horas'] as double));
      if (heavyUsers.length > 5) heavyUsers = heavyUsers.sublist(0, 5); // top 5

    } catch (error) {
      debugPrint("Error al cargar métricas de admin: $error");
    }

      _estaCargando = false;
      notifyListeners();
  }

  int _getWeekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.weekday;
    final daysToFirstMonday = (8 - firstMonday) % 7;
    final firstMondayDate = startOfYear.add(Duration(days: daysToFirstMonday));
    if (date.isBefore(firstMondayDate)) {
      return 1;
    }
    final difference = date.difference(firstMondayDate).inDays;
    return 2 + (difference ~/ 7);
  }
}