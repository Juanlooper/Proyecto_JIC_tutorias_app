// ignore_for_file: non_constant_identifier_names
/// Clase que representa una sesión de clase o tutoría dentro de la plataforma de la JIC.
/// Ha sido diseñada con la flexibilidad necesaria para manejar tanto clases en grupo como
/// clases individuales, además de adaptarse a diversas etapas de validación de las mismas.
class TutoriaModel {
  /// Código único que identifica esta sesión en toda la base de datos de la plataforma.
  /// Sirve para rastrear y encontrar la tutoriá rápidamente de forma unívoca, sin confusiones.
  final String identificadorDeTutoria;

  /// Nombre general de la materia o conocimiento requerido (Ejemplo: Álgebra Lineal).
  /// Sirve para que en las pantallas los estudiantes y el tutor entiendan a nivel general el tópico de estudio.
  final String materiaOAsignatura;

  /// Explicación detallada o tema clave de lo que se desea resolver (Ejemplo: Problemas con matrices inversas).
  /// Sirve para que el tutor pueda preparar la clase de manera mucho más enfocada.
  final String temaEspecifico;

  /// Especifica a qué rama o carrera de la UTP pertenece la materia solicitada.
  /// Resulta imprescindible para el filtro que Maiky procesa desde los proveedores.
  final String carrera;

  /// Es el identificador único del usuario que está dictando la clase (el profesor/tutor).
  /// Sirve para vincular los honorarios o reseñas a la cuenta directa del responsable de enseñar.
  final String identificadorDelTutor;

  /// Lista que contiene los identificadores de los alumnos que participarán conectados en la clase.
  /// Sirve para permitir clases grupales, enviando notificaciones y los enlaces de manera masiva al grupo inscrito.
  final List<String> listaDeEstudiantesInscritos;

  /// Describe la vía por la que se impartirá la clase. Por lo general los valores son: 'Virtual' o 'Presencial'.
  /// Ayuda al sistema a saber si debe pedir un salón físico requerido o preparar un enlace de videollamada.
  final String modalidadDeClase;

  /// Marca la fase de gestión actual de la clase. Los valores son: 'pendiente', 'aceptada', 'finalizada' o 'cancelada'.
  /// Condiciona los botones que la interfaz grafica (los colores y las barreras de permisos) muestra al usuario.
  final String estadoDeLaSolicitud;

  /// Momento cronológico puntual (fecha y hora) en que los involucrados se conectarán para hacer la tutoría.
  /// Es vital para mostrar el evento en calendarios inteligentes de la aplicación u organizar tiempos.
  final DateTime fechaHoraSugerida;

  /// Puede ser la URL de zoom/meet (virtual) o el número/nombre del salón (presencial).
  /// Es opcional (nulo por defecto) hasta que se decida cómo llevar al cabo la cita concretada.
  final String? enlaceOReunion;

  /// Cupo máximo de estudiantes que pueden participar en la tutoría.
  /// Define el límite de capacidad para gestionar las inscripciones.
  final int cupoMaximo;

  /// Duración planificada de la tutoría en minutos.
  /// Útil para agendamiento y visualización en calendarios.
  final int duracionMinutos;

  /// Indica a qué hora inició realmente la sesión académica.
  final DateTime? horaInicioReal;

  /// Indica a qué hora el tutor dio por finalizada la sesión, útil para calcular pagos u horas formales.
  final DateTime? horaFinReal;

  /// Propiedad que define si la sesión permite múltiples usuarios al mismo tiempo.
  final bool esGrupal;

  /// Motivos de los alumnos. La llave es el UID del alumno y el valor es el tema a reforzar.
  final Map<String, String>? motivos_alumnos;

  /// Enlaces adjuntos a la tutoría. La llave es el UID y el valor es la lista de URLs.
  final Map<String, List<String>>? enlaces_adjuntos;

  /// Nombres de los archivos adjuntos. La llave es el UID y el valor es la lista de nombres.
  final Map<String, List<String>>? nombres_adjuntos;

  /// Registro de asistencia. La llave es el UID, el valor es true (asistió) o false (faltó).
  final Map<String, bool>? registro_asistencia;

  /// Justificación en caso de que la tutoría sea cancelada.
  final String? justificacion_cancelacion;

  /// Ubicación acordada (Salón físico o enlace de plataforma virtual).
  final String? lugar;

  /// Contacto rápido del tutor (Frecuentemente WhatsApp).
  /// Contacto rápido del tutor (Frecuentemente WhatsApp).
  final String? contacto_tutor;

  /// Nombre real del tutor (Desnormalización NoSQL para evitar consultas anidadas).
  final String? nombre_tutor;

  /// Lista de los identificadores únicos de los estudiantes que ya evaluaron esta sesión.
  /// Sirve para evitar dobles evaluaciones y deshabilitar el botón de calificar.
  final List<String> alumnosQueYaEvaluaron;

  /// Lista de los identificadores únicos de los estudiantes que el tutor ya evaluó en esta sesión.
  final List<String> alumnosEvaluadosPorTutor;

  /// Lista de UID de estudiantes que apoyan la sugerencia comunitaria
  final List<String> estudiantesApoyando;

  /// Creador original de la solicitud (si era una tutoría sugerida)
  final String? creador;

  /// Fecha en la que la solicitud fue creada en el sistema. Vital para calcular SLA.
  final DateTime? fecha_creacion_solicitud;

  /// Fecha en la que la solicitud fue aceptada por un tutor. Vital para calcular SLA.
  final DateTime? fecha_aceptacion_solicitud;

  /// Constructor base. Se encarga de ensamblar en la memoria RAM una tutoría cuando llamamos la clase.
  /// El atributo 'required' indica qué pieza es indispensable para considerarse legalmente una tutoría.
  TutoriaModel({
    required this.identificadorDeTutoria,
    required this.materiaOAsignatura,
    required this.temaEspecifico,
    required this.carrera,
    required this.identificadorDelTutor,
    required this.listaDeEstudiantesInscritos,
    required this.modalidadDeClase,
    required this.estadoDeLaSolicitud,
    required this.fechaHoraSugerida,
    this.enlaceOReunion,
    this.cupoMaximo = 1,
    required this.duracionMinutos,
    this.horaInicioReal,
    this.horaFinReal,
    this.esGrupal = false,
    this.motivos_alumnos,
    this.enlaces_adjuntos,
    this.nombres_adjuntos,
    this.registro_asistencia,
    this.justificacion_cancelacion,
    this.lugar,
    this.contacto_tutor,
    this.nombre_tutor,
    this.alumnosQueYaEvaluaron = const [],
    this.alumnosEvaluadosPorTutor = const [],
    this.estudiantesApoyando = const [],
    this.creador,
    this.fecha_creacion_solicitud,
    this.fecha_aceptacion_solicitud,
  });

  /// Transforma nuestra estructura de datos de objeto a formato mapa de clave/valor.
  /// Sirve para empaquetar toda la información de este proceso en la estructura estandarizada de guardado de Firebase.
  Map<String, dynamic> toMap() {
    return {
      'identificadorDeTutoria': identificadorDeTutoria,
      'materiaOAsignatura': materiaOAsignatura,
      'temaEspecifico': temaEspecifico,
      'carrera': carrera,
      'identificadorDelTutor': identificadorDelTutor,
      'listaDeEstudiantesInscritos': listaDeEstudiantesInscritos,
      'modalidadDeClase': modalidadDeClase,
      'estadoDeLaSolicitud': estadoDeLaSolicitud,
      // Se utiliza texto de estándar ISO 8601 para que la conversión de la fecha sea inquebrantable
      'fechaHoraSugerida': fechaHoraSugerida.toIso8601String(),
      'enlaceOReunion': enlaceOReunion,
      'cupoMaximo': cupoMaximo,
      'duracionMinutos': duracionMinutos,
      'horaInicioReal': horaInicioReal?.toIso8601String(),
      'horaFinReal': horaFinReal?.toIso8601String(),
      'esGrupal': esGrupal,
      'motivos_alumnos': motivos_alumnos,
      'enlaces_adjuntos': enlaces_adjuntos,
      'nombres_adjuntos': nombres_adjuntos,
      'registro_asistencia': registro_asistencia,
      'justificacion_cancelacion': justificacion_cancelacion,
      'lugar': lugar,
      'contacto_tutor': contacto_tutor,
      'nombre_tutor': nombre_tutor,
      'alumnosQueYaEvaluaron': alumnosQueYaEvaluaron,
      'alumnosEvaluadosPorTutor': alumnosEvaluadosPorTutor,
      'estudiantesApoyando': estudiantesApoyando,
      'creador': creador,
      'fecha_creacion_solicitud': fecha_creacion_solicitud?.toIso8601String(),
      'fecha_aceptacion_solicitud': fecha_aceptacion_solicitud?.toIso8601String(),
    };
  }

  /// Receptor que reconstruye el modelo de tutoría valiéndose de los datos puros descargados de nube (Firebase).
  /// Utiliza un enfoque anti-caídas asegurando defaults fiables o listas vacías al detectar atributos dañados/ausentes.
  factory TutoriaModel.fromMap(Map<String, dynamic>? mapaDeDatos) {
    // Escudo #1: Si no llegan datos por cortes de internet o error de recolección, retornamo un estado limpio provisorio básico.
    if (mapaDeDatos == null) {
      return TutoriaModel(
        identificadorDeTutoria: '',
        materiaOAsignatura: 'Materia no registrada',
        temaEspecifico: 'No se detalló el tema',
        carrera: 'General',
        identificadorDelTutor: '',
        listaDeEstudiantesInscritos: [],
        modalidadDeClase: 'Virtual',
        estadoDeLaSolicitud: 'pendiente',
        fechaHoraSugerida: DateTime.now(), // Por si no hay fecha, no colapsa el motor
        cupoMaximo: 1,
        duracionMinutos: 60,
        alumnosQueYaEvaluaron: [],
        alumnosEvaluadosPorTutor: [],
        estudiantesApoyando: [],
        creador: null,
        fecha_creacion_solicitud: null,
        fecha_aceptacion_solicitud: null,
      );
    }

    // Escudo #2: Mecanismo ultra flexible para descifrar fechas. Detecta posibles Tipos de objeto por si proviene
    // de Base de datos como Timestamp, como String, o un DateTime puro nativo en el dispositivo.
    DateTime fechaSegura;
    var rawFecha = mapaDeDatos['fechaHoraSugerida'];
    
    if (rawFecha == null) {
      fechaSegura = DateTime.now();
    } else if (rawFecha is DateTime) {
      fechaSegura = rawFecha;
    } else if (rawFecha is String) {
      fechaSegura = DateTime.tryParse(rawFecha) ?? DateTime.now();
    } else {
      // Método dinámico. Usualmente Firebase usa un formato especial (Timestamp) que tiene su propio "toDate()".
      try {
        fechaSegura = rawFecha.toDate();
      } catch (e) {
        fechaSegura = DateTime.now();
      }
    }

    // Retorno limpio usando coalescencia nula (??) proveyéndonos valores predeterminados
    return TutoriaModel(
      identificadorDeTutoria: mapaDeDatos['identificadorDeTutoria'] ?? '',
      materiaOAsignatura: mapaDeDatos['materiaOAsignatura'] ?? 'Materia no definida',
      temaEspecifico: mapaDeDatos['temaEspecifico'] ?? 'No se ha indicado un tema',
      carrera: mapaDeDatos['carrera'] ?? 'General',
      identificadorDelTutor: mapaDeDatos['identificadorDelTutor'] ?? '',
      
      // Requisito cumplido: Si la lista de estudiantes viene vacía o nula se la obliga a interpretar y crear un []
      listaDeEstudiantesInscritos: mapaDeDatos['listaDeEstudiantesInscritos'] != null
          ? List<String>.from(mapaDeDatos['listaDeEstudiantesInscritos'])
          : [],
          
      modalidadDeClase: mapaDeDatos['modalidadDeClase'] ?? 'Virtual',
      
      // Requisito cumplido: Si el estado no está definido del todo (nulo), se forzará por orden al estado raíz 'pendiente'
      estadoDeLaSolicitud: mapaDeDatos['estadoDeLaSolicitud'] ?? 'pendiente',
      
      fechaHoraSugerida: fechaSegura,
      enlaceOReunion: mapaDeDatos['enlaceOReunion'],
      cupoMaximo: mapaDeDatos['cupoMaximo'] ?? 1,
      duracionMinutos: mapaDeDatos['duracionMinutos'] ?? 60,
      horaInicioReal: mapaDeDatos['horaInicioReal'] != null ? DateTime.tryParse(mapaDeDatos['horaInicioReal']) : null,
      horaFinReal: mapaDeDatos['horaFinReal'] != null ? DateTime.tryParse(mapaDeDatos['horaFinReal']) : null,
      esGrupal: mapaDeDatos['esGrupal'] ?? false,
      motivos_alumnos: mapaDeDatos['motivos_alumnos'] != null 
          ? Map<String, String>.from(mapaDeDatos['motivos_alumnos']) 
          : null,
      enlaces_adjuntos: mapaDeDatos['enlaces_adjuntos'] != null 
          ? (mapaDeDatos['enlaces_adjuntos'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<String>.from(v)),
            ) 
          : null,
      nombres_adjuntos: mapaDeDatos['nombres_adjuntos'] != null 
          ? (mapaDeDatos['nombres_adjuntos'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, List<String>.from(v)),
            ) 
          : null,
      registro_asistencia: mapaDeDatos['registro_asistencia'] != null 
          ? Map<String, bool>.from(mapaDeDatos['registro_asistencia']) 
          : null,
      justificacion_cancelacion: mapaDeDatos['justificacion_cancelacion'],
      lugar: mapaDeDatos['lugar'],
      contacto_tutor: mapaDeDatos['contacto_tutor'],
      nombre_tutor: mapaDeDatos['nombre_tutor'],
      alumnosQueYaEvaluaron: mapaDeDatos['alumnosQueYaEvaluaron'] != null
          ? List<String>.from(mapaDeDatos['alumnosQueYaEvaluaron'])
          : [],
      alumnosEvaluadosPorTutor: mapaDeDatos['alumnosEvaluadosPorTutor'] != null
          ? List<String>.from(mapaDeDatos['alumnosEvaluadosPorTutor'])
          : [],
      estudiantesApoyando: mapaDeDatos['estudiantesApoyando'] != null
          ? List<String>.from(mapaDeDatos['estudiantesApoyando'])
          : [],
      creador: mapaDeDatos['creador'],
      fecha_creacion_solicitud: mapaDeDatos['fecha_creacion_solicitud'] != null ? DateTime.tryParse(mapaDeDatos['fecha_creacion_solicitud']) : null,
      fecha_aceptacion_solicitud: mapaDeDatos['fecha_aceptacion_solicitud'] != null ? DateTime.tryParse(mapaDeDatos['fecha_aceptacion_solicitud']) : null,
    );
  }

  /// Genera una copia de la tutoría actual con la posibilidad de modificar propiedades específicas.
  TutoriaModel copyWith({
    String? identificadorDeTutoria,
    String? materiaOAsignatura,
    String? temaEspecifico,
    String? carrera,
    String? identificadorDelTutor,
    List<String>? listaDeEstudiantesInscritos,
    String? modalidadDeClase,
    String? estadoDeLaSolicitud,
    DateTime? fechaHoraSugerida,
    String? enlaceOReunion,
    int? cupoMaximo,
    int? duracionMinutos,
    DateTime? horaInicioReal,
    DateTime? horaFinReal,
    bool? esGrupal,
    Map<String, String>? motivos_alumnos,
    Map<String, List<String>>? enlaces_adjuntos,
    Map<String, List<String>>? nombres_adjuntos,
    Map<String, bool>? registro_asistencia,
    String? justificacion_cancelacion,
    String? lugar,
    String? contacto_tutor,
    String? nombre_tutor,
    List<String>? alumnosQueYaEvaluaron,
    List<String>? alumnosEvaluadosPorTutor,
    List<String>? estudiantesApoyando,
    String? creador,
    DateTime? fecha_creacion_solicitud,
    DateTime? fecha_aceptacion_solicitud,
  }) {
    return TutoriaModel(
      identificadorDeTutoria: identificadorDeTutoria ?? this.identificadorDeTutoria,
      materiaOAsignatura: materiaOAsignatura ?? this.materiaOAsignatura,
      temaEspecifico: temaEspecifico ?? this.temaEspecifico,
      carrera: carrera ?? this.carrera,
      identificadorDelTutor: identificadorDelTutor ?? this.identificadorDelTutor,
      listaDeEstudiantesInscritos: listaDeEstudiantesInscritos ?? this.listaDeEstudiantesInscritos,
      modalidadDeClase: modalidadDeClase ?? this.modalidadDeClase,
      estadoDeLaSolicitud: estadoDeLaSolicitud ?? this.estadoDeLaSolicitud,
      fechaHoraSugerida: fechaHoraSugerida ?? this.fechaHoraSugerida,
      enlaceOReunion: enlaceOReunion ?? this.enlaceOReunion,
      cupoMaximo: cupoMaximo ?? this.cupoMaximo,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      horaInicioReal: horaInicioReal ?? this.horaInicioReal,
      horaFinReal: horaFinReal ?? this.horaFinReal,
      esGrupal: esGrupal ?? this.esGrupal,
      motivos_alumnos: motivos_alumnos ?? this.motivos_alumnos,
      enlaces_adjuntos: enlaces_adjuntos ?? this.enlaces_adjuntos,
      nombres_adjuntos: nombres_adjuntos ?? this.nombres_adjuntos,
      registro_asistencia: registro_asistencia ?? this.registro_asistencia,
      justificacion_cancelacion: justificacion_cancelacion ?? this.justificacion_cancelacion,
      lugar: lugar ?? this.lugar,
      contacto_tutor: contacto_tutor ?? this.contacto_tutor,
      nombre_tutor: nombre_tutor ?? this.nombre_tutor,
      alumnosQueYaEvaluaron: alumnosQueYaEvaluaron ?? this.alumnosQueYaEvaluaron,
      alumnosEvaluadosPorTutor: alumnosEvaluadosPorTutor ?? this.alumnosEvaluadosPorTutor,
      estudiantesApoyando: estudiantesApoyando ?? this.estudiantesApoyando,
      creador: creador ?? this.creador,
      fecha_creacion_solicitud: fecha_creacion_solicitud ?? this.fecha_creacion_solicitud,
      fecha_aceptacion_solicitud: fecha_aceptacion_solicitud ?? this.fecha_aceptacion_solicitud,
    );
  }
}
