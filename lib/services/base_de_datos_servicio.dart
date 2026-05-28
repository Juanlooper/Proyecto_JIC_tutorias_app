import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tutoria_model.dart'; // Importación obligatoria del Modelo que creamos anteriormente

/// Servicio especialista en el manejo de Datos y Estadísticas en la Nube.
/// Esta clase orquesta todo el control de tráfico dentro de Firestore asociado a las Clases/Tutorías.
class BaseDeDatosServicio {
  
  /// Instancia pre-configurada apuntando directamente a nuestra gran bodega online (Firebase Firestore).
  final FirebaseFirestore _bodegaDeConocimiento = FirebaseFirestore.instance;

  /// Registra una petición "desde cero" almacenando todo el detalle de la tutoría elaborada en nuestra base de datos.
  /// El bloque 'try' es un escudo anti-cortes de internet, validando que solo retorne "verdadero" si hubo un impacto real en DB.
  Future<bool> crearNuevaTutoria({required TutoriaModel modeloDeLaNuevaClase}) async {
    try {
      // REGLA DE NEGOCIO: Validación de Integridad Temporal. No se pueden programar tutorías en un tiempo vencido (pasado).
      if (modeloDeLaNuevaClase.fechaHoraSugerida.isBefore(DateTime.now())) {
        return false;
      }

      // 1. Apuntamos al pasillo "tutorias". Usamos de etiqueta de la carpeta el mismo 'identificadorDeTutoria'.
      // 2. .set() esparcirá el resultado nativo extraído de .toMap() directamente al servidor de la JIC.
      await _bodegaDeConocimiento
          .collection('tutorias')
          .doc(modeloDeLaNuevaClase.identificadorDeTutoria)
          .set(modeloDeLaNuevaClase.toMap());
          
      return true; // Retornal al UI un éxito transparente
    } catch (errorSilencioso) {
      // Control de pérdidas. No "romperá" la app si hay error conectivo o denegación de reglas
      return false; 
    }
  }

  /// Realiza una "lectura eficiente" recuperando SOLO aquellas sesiones vírgenes solicitando profesores.
  /// Es clave hacer el filtro .where('pendiente') en Cloud (lado servidor) para jamás exceder cuotas de descargas en Firebase.
  Future<List<TutoriaModel>> obtenerTutoriasPendientes() async {
    try {
      QuerySnapshot lecturaOptimizada = await _bodegaDeConocimiento
          .collection('tutorias')
          .where('estadoDeLaSolicitud', whereIn: ['pendiente', 'Pendiente', 'aceptada', 'Aceptada', 'abierta', 'Abierta'])
          .limit(50) // Optimización escalable: Previene leer miles de docs de golpe, topado a 50 recientes
          .get();

      // Transformamos ('map') el montón crudo de registros a una lista formal de nuestro prestigioso modelo
      List<TutoriaModel> listadoResultante = lecturaOptimizada.docs.map((hojaDocumental) {
        var informacionBruta = hojaDocumental.data() as Map<String, dynamic>?;
        // Aquí pasamos los datos por el colador super-protegido del fromMap que diseñamos antes
        return TutoriaModel.fromMap(informacionBruta); 
      }).toList();

      return listadoResultante;

    } catch (errorEnFlujoLectura) {
      // Respuesta resiliente: si colapsamos, entregamos lista vacía [] para no asustar al usuario ni romper gráficas de Alejandra.
      return []; 
    }
  }

  /// Añade el nombre/cédula del Estudiante a un registro masivo en clases grandes.
  /// Por órdenes lógicas, usamos arrayUnion: es el método definitivo para apilar datos sin sobreescribir ni re-descargar todo.
  Future<String> unirseATutoria({
    required String identificadorDeTutoriaEspecifica,
    required String identificadorDeUnAlumnoFinal,
  }) async {
    try {
      // Explicación Técnica (SRE): El uso de runTransaction le dice a Firestore que agrupe este procedimiento
      // en un cerrojo (lock) de lectura/escritura atómico. Garantiza matemática y sistemáticamente que si existen picos de concurrencia
      // (Ejemplo: varios alumnos uniéndose al unísono al último cupo) sólo se proceda si la lectura en memoria está inmaculada, evitando carreras (Race Conditions).
      return await _bodegaDeConocimiento.runTransaction((transaccion) async {
        DocumentReference refTutoria = _bodegaDeConocimiento
            .collection('tutorias')
            .doc(identificadorDeTutoriaEspecifica);
            
        DocumentSnapshot tutoriaDoc = await transaccion.get(refTutoria);
        
        if (!tutoriaDoc.exists) {
          return "Error crítico: La tutoría deseada no existe.";
        }

        TutoriaModel tutoriaVigente = TutoriaModel.fromMap(tutoriaDoc.data() as Map<String, dynamic>?);
        
        // REGLA DE NEGOCIO: Proteger el cupo máximo para asegurar la capacidad de la clase.
        if (tutoriaVigente.listaDeEstudiantesInscritos.length >= tutoriaVigente.cupoMaximo) {
          return "La tutoría ha alcanzado su límite de cupos";
        }
        
        transaccion.update(refTutoria, {
             'listaDeEstudiantesInscritos': FieldValue.arrayUnion([identificadorDeUnAlumnoFinal])
        });

        return "Cupo Asegurado: Ya te encuentras en lista";
      });
    } catch (errorDeIntegracion) {
      return "Sucedió un colapso en la nube intentando ingresar tu registro.";
    }
  }

  /// Es el gran comando que pulsa un profesor experto cuando reclama enseñar una de las materias libres.
  /// Transiciona el negocio inyectándole vida utilizando Transacciones Atómicas (SRE Architecture).
  Future<String> aceptarTutoria({
    required String identificadorDeTutoriaEspecifica,
    required String maestroHerederoAlMando,
    String? linkOficialParaSesion,
    String? estadoPropuestoOpcional,
  }) async {
    try {
      final refDocumentoTutoria = _bodegaDeConocimiento
          .collection('tutorias')
          .doc(identificadorDeTutoriaEspecifica);

      // Iniciamos el blindaje atómico contra condiciones de carrera (Race Conditions)
      await _bodegaDeConocimiento.runTransaction((transaccion) async {
        // 1. LECTURA OBLIGATORIA: Obtenemos el snapshot bloqueante de la tutoría deseada
        DocumentSnapshot documentoSnapshot = await transaccion.get(refDocumentoTutoria);
        
        // 2. NULL SAFETY: Eliminamos aserciones forzadas y realizamos casting defensivo
        final datosDeLaTutoria = documentoSnapshot.data() as Map<String, dynamic>?;
        if (datosDeLaTutoria == null || !documentoSnapshot.exists) {
          throw Exception("Error crítico: La tutoría ha caducado o no existe en la base de datos.");
        }

        // 3. RECONSTRUCCIÓN HIGIÉNICA: Utilizamos factory method seguro
        TutoriaModel tutoriaPorAceptar = TutoriaModel.fromMap(datosDeLaTutoria);
        
        // 4. CONTROL DE CONCURRENCIA: Rechazo temprano si otro hilo ganó la transacción milisegundos antes
        if (tutoriaPorAceptar.estadoDeLaSolicitud != 'pendiente' && 
            tutoriaPorAceptar.estadoDeLaSolicitud != 'solicitada') {
          throw Exception("La tutoría ya fue reclamada por otro profesor.");
        }

        // 5. PREVENCIÓN DE BUCLES LÓGICOS: Un usuario no puede auto-enseñarse
        if (tutoriaPorAceptar.listaDeEstudiantesInscritos.contains(maestroHerederoAlMando)) {
          throw Exception("Error: No puedes ser el tutor de tu propia solicitud.");
        }

        // 6. VALIDACIÓN CRUZADA: Evaluar traslape horario extrayendo el modelo interno
        DateTime inicioNueva = tutoriaPorAceptar.fechaHoraSugerida;
        DateTime finNueva = inicioNueva.add(Duration(minutes: tutoriaPorAceptar.duracionMinutos));

        // Procedimiento de chequeo de agenda (Ejecutado perimetralmente para asegurar agenda del tutor)
        QuerySnapshot tutoriasAnteriores = await _bodegaDeConocimiento
            .collection('tutorias')
            .where('identificadorDelTutor', isEqualTo: maestroHerederoAlMando)
            .where('estadoDeLaSolicitud', isEqualTo: 'aceptada')
            .get();

        for (var docTemporal in tutoriasAnteriores.docs) {
          TutoriaModel tutoriaAceptada = TutoriaModel.fromMap(docTemporal.data() as Map<String, dynamic>?);
          DateTime inicioExistente = tutoriaAceptada.fechaHoraSugerida;
          DateTime finExistente = inicioExistente.add(Duration(minutes: tutoriaAceptada.duracionMinutos));

          bool hayConflicto = inicioNueva.isBefore(finExistente) && finNueva.isAfter(inicioExistente);
          if (hayConflicto) {
            throw Exception("Error de agenda: Ya tienes una tutoría programada en este horario.");
          }
        }

        // 7. ESCRITURA ATÓMICA: Inyectamos el update solo tras validar todo el muro de excepciones
        Map<String, dynamic> parchesLigeros = {
          'estadoDeLaSolicitud': estadoPropuestoOpcional ?? 'aceptada',
          'identificadorDelTutor': maestroHerederoAlMando,
        };

        if (linkOficialParaSesion != null && linkOficialParaSesion.trim().isNotEmpty) {
          parchesLigeros['enlaceOReunion'] = linkOficialParaSesion;
        }

        transaccion.update(refDocumentoTutoria, parchesLigeros);
      });

      return "¡Extraordinario! Oficialmente serás el tutor de esta sesión.";
    } catch (errorTransaccional) {
      // 8. INTERRUPCIÓN DEL FLUJO: Capturamos excepciones limpias inyectadas desde el rollback transaccional
      String mensajeCapturado = errorTransaccional.toString();
      if (mensajeCapturado.contains("Exception: ")) {
        return mensajeCapturado.split("Exception: ").last.trim();
      }
      return "La nube interrumpió el proceso de tu asignación como tutor actual.";
    }
  }

  /// Permite a un estudiante sumar su apoyo a una solicitud comunitaria.
  Future<void> agregarApoyoEnComunidad(String tutoriaId, String uidUsuario) async {
    await _bodegaDeConocimiento.collection('tutorias').doc(tutoriaId).update({
      'estudiantesApoyando': FieldValue.arrayUnion([uidUsuario])
    });
  }

  /// Permite a un estudiante abandonar una tutoría (retirarse de listas).
  /// Retorna un mapa con el uid del promovido (si hubo) y datos extra.
  Future<Map<String, dynamic>> retirarseDeTutoria(String tutoriaId, String uidUsuario) async {
    final docSnapshot = await _bodegaDeConocimiento.collection('tutorias').doc(tutoriaId).get();
    if (!docSnapshot.exists) throw Exception("Tutoría no encontrada.");
    
    final data = docSnapshot.data();
    if (data == null) throw Exception("Documento vacío o corrupto.");

    if (data['estadoDeLaSolicitud'] == 'solicitada') {
      await _bodegaDeConocimiento.collection('tutorias').doc(tutoriaId).update({
        'estudiantesApoyando': FieldValue.arrayRemove([uidUsuario])
      });
      return {'promovidoUid': null, 'dataOriginal': data};
    } else {
      String? promovidoUid;
      await _bodegaDeConocimiento.runTransaction((transaction) async {
        final docRef = _bodegaDeConocimiento.collection('tutorias').doc(tutoriaId);
        final docSnap = await transaction.get(docRef);
        if (!docSnap.exists) throw Exception("Tutoría no encontrada.");
        
        final docData = docSnap.data();
        if (docData == null) throw Exception("Documento vacío.");

        List<dynamic> inscritos = List.from(docData['listaDeEstudiantesInscritos'] ?? []);
        List<dynamic> espera = List.from(docData['listaDeEspera'] ?? []);
        
        if (espera.contains(uidUsuario)) {
           espera.remove(uidUsuario);
           transaction.update(docRef, {'listaDeEspera': espera});
        } else if (inscritos.contains(uidUsuario)) {
           inscritos.remove(uidUsuario);
           
           if (espera.isNotEmpty) {
              promovidoUid = espera.removeAt(0).toString();
              inscritos.add(promovidoUid);
           }
           
           transaction.update(docRef, {
              'listaDeEstudiantesInscritos': inscritos,
              'listaDeEspera': espera,
           });
        }
      });
      return {'promovidoUid': promovidoUid, 'dataOriginal': data};
    }
  }

  /// Registra una excusa de cancelación en el tribunal.
  Future<void> registrarExcusaEnTribunal(String tutoriaId, String uidUsuario, String materia, String fecha, String excusa) async {
    await _bodegaDeConocimiento.collection('reportes_tribunal').add({
      'alumnoId': uidUsuario,
      'tutoriaId': tutoriaId,
      'materia': materia,
      'fechaTutoria': fecha,
      'excusa': excusa,
      'fechaReporte': DateTime.now().toIso8601String(),
      'estado': 'pendiente',
    });
  }

  /// Cancela una tutoría como tutor y registra la queja de forma obligatoria.
  /// Retorna los datos íntegros del documento antes de cancelar, para enviar notificaciones posteriores.
  Future<Map<String, dynamic>> cancelarTutoriaPorTutor(String tutoriaId, String motivoCancelacion, String uidTutor) async {
    final docSnapshot = await _bodegaDeConocimiento.collection('tutorias').doc(tutoriaId).get();
    if (!docSnapshot.exists) throw Exception("Tutoría no encontrada.");
    
    final data = docSnapshot.data();
    if (data == null) throw Exception("Documento vacío.");

    await _bodegaDeConocimiento.collection('tutorias').doc(tutoriaId).update({
      'estadoDeLaSolicitud': 'cancelada',
      'motivoDeCancelacion': motivoCancelacion,
    });

    await _bodegaDeConocimiento.collection('quejas').add({
      'tutorId': uidTutor,
      'tutoriaId': tutoriaId,
      'fechaRegistro': DateTime.now().toIso8601String(),
      'justificacion': motivoCancelacion,
    });

    return data;
  }
}
