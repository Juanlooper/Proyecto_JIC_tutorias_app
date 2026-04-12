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

  /// Constructor base. Se encarga de ensamblar en la memoria RAM una tutoría cuando llamamos la clase.
  /// El atributo 'required' indica qué pieza es indispensable para considerarse legalmente una tutoría.
  TutoriaModel({
    required this.identificadorDeTutoria,
    required this.materiaOAsignatura,
    required this.temaEspecifico,
    required this.identificadorDelTutor,
    required this.listaDeEstudiantesInscritos,
    required this.modalidadDeClase,
    required this.estadoDeLaSolicitud,
    required this.fechaHoraSugerida,
    this.enlaceOReunion,
  });

  /// Transforma nuestra estructura de datos de objeto a formato mapa de clave/valor.
  /// Sirve para empaquetar toda la información de este proceso en la estructura estandarizada de guardado de Firebase.
  Map<String, dynamic> toMap() {
    return {
      'identificadorDeTutoria': identificadorDeTutoria,
      'materiaOAsignatura': materiaOAsignatura,
      'temaEspecifico': temaEspecifico,
      'identificadorDelTutor': identificadorDelTutor,
      'listaDeEstudiantesInscritos': listaDeEstudiantesInscritos,
      'modalidadDeClase': modalidadDeClase,
      'estadoDeLaSolicitud': estadoDeLaSolicitud,
      // Se utiliza texto de estándar ISO 8601 para que la conversión de la fecha sea inquebrantable
      'fechaHoraSugerida': fechaHoraSugerida.toIso8601String(),
      'enlaceOReunion': enlaceOReunion,
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
        identificadorDelTutor: '',
        listaDeEstudiantesInscritos: [],
        modalidadDeClase: 'Virtual',
        estadoDeLaSolicitud: 'pendiente',
        fechaHoraSugerida: DateTime.now(), // Por si no hay fecha, no colapsa el motor
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
    );
  }
}
