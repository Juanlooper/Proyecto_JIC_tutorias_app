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
      // La solicitud a Firebase. Retornará únicamente los paquetes alineados con nuestro requerimiento.
      QuerySnapshot lecturaOptimizada = await _bodegaDeConocimiento
          .collection('tutorias')
          .where('estadoDeLaSolicitud', isEqualTo: 'pendiente')
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
  /// Transiciona el negocio inyectándole vida: pasamos a 'aceptada', plantamos el nombre del sensei, y su link Zoom.
  Future<String> aceptarTutoria({
    required String identificadorDeTutoriaEspecifica,
    required String maestroHerederoAlMando,
    String? linkOficialParaSesion,
    String? estadoPropuestoOpcional,
  }) async {
    try {
      // REGLA DE NEGOCIO: Validar que el tutor no tenga otra clase aceptada que se solape en este mismo horario.
      DocumentSnapshot docDeseada = await _bodegaDeConocimiento
          .collection('tutorias')
          .doc(identificadorDeTutoriaEspecifica)
          .get();
          
      if (docDeseada.exists) {
        TutoriaModel tutoriaPorAceptar = TutoriaModel.fromMap(docDeseada.data() as Map<String, dynamic>?);
        
        // REGLA DE NEGOCIO: Prevención de bucles. Un usuario no puede ser tutor y estudiante de la misma sesión simultáneamente.
        if (tutoriaPorAceptar.listaDeEstudiantesInscritos.contains(maestroHerederoAlMando)) {
          return "Error: No puedes ser el tutor de tu propia solicitud";
        }

        DateTime inicioNueva = tutoriaPorAceptar.fechaHoraSugerida;
        DateTime finNueva = inicioNueva.add(Duration(minutes: tutoriaPorAceptar.duracionMinutos));

        QuerySnapshot tutoriasAnteriores = await _bodegaDeConocimiento
            .collection('tutorias')
            .where('identificadorDelTutor', isEqualTo: maestroHerederoAlMando)
            .where('estadoDeLaSolicitud', isEqualTo: 'aceptada')
            .get();

        for (var docTemporal in tutoriasAnteriores.docs) {
          TutoriaModel tutoriaAceptada = TutoriaModel.fromMap(docTemporal.data() as Map<String, dynamic>?);
          DateTime inicioExistente = tutoriaAceptada.fechaHoraSugerida;
          DateTime finExistente = inicioExistente.add(Duration(minutes: tutoriaAceptada.duracionMinutos));

          // Verificamos si existe un traslape en la línea de tiempo real
          bool hayConflicto = inicioNueva.isBefore(finExistente) && finNueva.isAfter(inicioExistente);
          if (hayConflicto) {
            return "Error de agenda: Ya tienes una tutoría programada en este horario";
          }
        }
      } else {
        return "Error crícito: La tutoría ha caducado o no existe en la base de datos.";
      }

      // Carga útil ultra-liviana. Preparamos el sobre de correo nada más con lo que es imperioso cambiar por ahorro.
      Map<String, dynamic> parchesLigeros = {
        'estadoDeLaSolicitud': estadoPropuestoOpcional ?? 'aceptada',
        'identificadorDelTutor': maestroHerederoAlMando,
      };

      // Si el Tutor adjuntó un link para conectarse o aula física, inyectalo al parche.
      if (linkOficialParaSesion != null && linkOficialParaSesion.trim().isNotEmpty) {
        parchesLigeros['enlaceOReunion'] = linkOficialParaSesion;
      }

      await _bodegaDeConocimiento
          .collection('tutorias')
          .doc(identificadorDeTutoriaEspecifica)
          .update(parchesLigeros);

      return "¡Extraordinario! Oficialmente serás el tutor de esta sesión.";
    } catch (errorAsignacional) {
      // Fallback seguro si hubo denegaciones de accesos
      return "La nube interrumpió el proceso de tu asignación como tutor actual.";
    }
  }
}
