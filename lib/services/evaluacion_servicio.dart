import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de Calidad y Auditoría de la Plataforma.
/// Este archivo se asegura de recopilar qué tan buena es una clase y vigilar la reputación del tutor.
/// Representa el motor de inspecciones (que usará Maiky) para mantener la excelencia del proyecto JIC.
class EvaluacionServicio {
  
  /// Instancia directa conectada a nuestra base de datos (Firestore).
  /// La llamaremos bóveda documental para hacer más amigable su lectura.
  final FirebaseFirestore _bovedaDocumentalAuditoria = FirebaseFirestore.instance;

  /// Almacena permanentemente el testimonio y puntaje de un alumno sobre una materia que finalizó.
  /// Toma las estrellas generadas en la interfaz (del 1 al 5) y las sube a la base de datos bajo 'evaluaciones'.
  Future<String> registrarEvaluacionCompleta({
    required String identificadorDeLaTutoria,
    required String identificadorDelTutorQueDioLaClase,
    required int calificacionDeLaClase, // Escala de 1 a 5 (¿Qué tan buena fue la metodología o contenido?)
    required int calificacionDelTutor,  // Escala de 1 a 5 (¿Qué tan bueno, amable o puntual fue el humano involucrado?)
    String? comentarioEscritoOpcional,
  }) async {
    try {
      // Utilizamos ".add()" en este caso para que Firebase nos fabrique una hoja con ID automático al instante.
      await _bovedaDocumentalAuditoria.collection('evaluaciones').add({
        'identificadorDeLaTutoria': identificadorDeLaTutoria,
        'identificadorDelTutor': identificadorDelTutorQueDioLaClase,
        'calificacionDeLaClase': calificacionDeLaClase,
        'calificacionDelTutor': calificacionDelTutor,
        'comentarioAdicional': comentarioEscritoOpcional ?? '', // Si el alumno fue tímido y no quiso escribir, va vacío
        
        // Colocamos también la marca exacta de tiempo que tiene el servidor para saber de que mes es el puntaje
        'fechaOficialDeEvaluacion': FieldValue.serverTimestamp(), 
      });

      return "¡Excelente! Has contribuido enormemente al sistema enviando tu evaluación.";
    } catch (errorAlPuntuar) {
      return "Hubo un tropezón de red al intentar registrar las estrellas para este perfil.";
    }
  }

  /// Funciona como un botón de emergencia silencioso para los integrantes del estudiantado.
  /// Si ocurre algo antiético o hay un severo bug que impida dar la clase, esto va a parar a una colección crítica ('quejas')
  Future<String> reportarIncidenteOQueja({
    required String identificadorDelUsuarioAfectado,
    required String descripcionCriticaDelProblema,
  }) async {
    try {
      await _bovedaDocumentalAuditoria.collection('quejas').add({
        'identificadorDelUsuarioAfectado': identificadorDelUsuarioAfectado,
        'relatoFormalDelIncidente': descripcionCriticaDelProblema,
        'estadoDeInvestigacion': 'pendiente_revision', // Identificador vital para el panel de Maiky.
        'fechaDeCreacion': FieldValue.serverTimestamp(),
      });

      return "Agradecemos tu reporte. Un moderador humano analizará inmediatamente esta advertencia.";
    } catch (errorEnElBuzon) {
      return "Problemas con el canal de reportes. Envíe un correo directo si es de ultra-urgencia.";
    }
  }

  /// El cerebro matemático de este servicio: Cuenta todo el "karma" o prestigio del profesor.
  /// Descarga el historial general y dictamina su promedio exacto en estrellas para mostrarlo en el dashboard.
  Future<double> obtenerPromedioDeTutor({
    required String identificadorEspecificoDelTutor,
  }) async {
    try {
      // PASO #1: Extraemos del cajón principal EXCLUSIVAMENTE los boletines de evaluación de ESE PRESTADOR.
      QuerySnapshot lecturaDelHistorialDelTutor = await _bovedaDocumentalAuditoria
          .collection('evaluaciones')
          .where('identificadorDelTutor', isEqualTo: identificadorEspecificoDelTutor)
          .get();

      // Validación lógica de Maiky: Si el profesor es nuevo y no tiene ningún review, su promedio base es 0 estrellas.
      if (lecturaDelHistorialDelTutor.docs.isEmpty) {
        return 0.0; 
      }

      // PASO #2: Pizarra de conteo de las calificaciones totales adquiridas en este historial.
      double sumatoriaTotalDeLasEstrellasGrapadas = 0;
      
      // La cantidad total representa "la cantidad de alumnos" que fueron a votarlo.
      int cantidadCensadaDeVotantes = lecturaDelHistorialDelTutor.docs.length;

      // PASO #3: Iteramos (pasamos un dedo) por cada hoja extraída para sumar la calificación lograda.
      // Escribimos un For-Loop clásico de sumar uno a uno de los boletines logrados y ser claros para la auditoria.
      for (var hojaDocumentalUnica in lecturaDelHistorialDelTutor.docs) {
        var informaciónMapaDelBoleto = hojaDocumentalUnica.data() as Map<String, dynamic>;
        
        // Sumamos lo que el Alumno asignó. Si por raro azar un documento se daña, asumimos por seguridad un "5" por defecto (beneficio de duda).
        int calificacionHaciaProfesionalExtraida = informaciónMapaDelBoleto['calificacionDelTutor'] ?? 5; 
        
        sumatoriaTotalDeLasEstrellasGrapadas = sumatoriaTotalDeLasEstrellasGrapadas + calificacionHaciaProfesionalExtraida;
      }

      // PASO #4: Fórmula clásica del promedio: Total acumulado dividido por todo el volumen evaluativos ingresados.
      double promedioMateOficialAcumulado = sumatoriaTotalDeLasEstrellasGrapadas / cantidadCensadaDeVotantes;

      return promedioMateOficialAcumulado;

    } catch (errorAlComputarLaCifra) {
      // Salvavidas de caídas: Un fallo no debe derribar un dashboard gráfico, devolvemos neutro
      return 0.0;
    }
  }
}
