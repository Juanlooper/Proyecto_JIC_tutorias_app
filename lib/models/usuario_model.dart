/// Enumeración que define los diferentes roles disponibles para un usuario en la plataforma.
enum RolSistema { estudiante, tutor, admin }

/// Clase que representa el modelo de un usuario en la plataforma de tutorías.
/// Esta clase es la encargada de estructurar los datos principales de las personas.
class UsuarioModel {
  /// Identificador único del usuario.
  /// Sirve para reconocer de forma exacta a cada usuario en el sistema sin importar si cambian su nombre.
  final String identificadorUnico;

  /// Nombre completo del estudiante, tutor o administrador.
  /// Sirve para mostrar de forma amigable la identidad de la persona en su perfil y pantallas del sistema.
  final String nombreCompleto;

  /// Correo electrónico del usuario.
  /// Sirve como la vía principal de contacto y también es la credencial para iniciar sesión.
  final String correoElectronico;

  /// Rol dentro del sistema. Determina los permisos y las pantallas que puede visualizar.
  /// Los roles definidos están estructurados mediante el enum [RolSistema].
  final RolSistema rolEnElSistema;

  /// Facultad a la que pertenece el usuario (Ejemplo: Ingeniería en Sistemas).
  /// Puede ser nulo (vacío) si el usuario aún no ha llenado este dato o su perfil es más general.
  final String? facultad;

  /// Carrera universitaria que estudia o dicta el usuario (Ejemplo: Desarrollo de Software).
  /// Puede ser nulo (vacío) si no ha especificado la carrera dentro de la aplicación.
  final String? carrera;

  /// Lista de los identificadores únicos de los tutores a los que el usuario se ha suscrito.
  /// Sirve para vincular al estudiante con sus tutores seleccionados y mostrar rápidamente a quiénes sigue.
  final List<String> listaDeTutoresSuscritos;

  /// Cantidad de faltas o inasistencias en las tutorías programadas.
  final int strikes_inasistencia;

  /// Indica si la cuenta del usuario está suspendida (baneada).
  final bool esta_baneado;

  /// Refleja la fase de postulación del usuario para convertirse en tutor. Posibles: 'ninguna', 'en_revision', 'aprobado'.
  final String estado_solicitud_tutor;

  /// Función constructora que inicializa o "crea" la representación del usuario cuando ya tenemos su información.
  UsuarioModel({
    required this.identificadorUnico,
    required this.nombreCompleto,
    required this.correoElectronico,
    required this.rolEnElSistema,
    this.facultad,
    this.carrera,
    required this.listaDeTutoresSuscritos,
    this.strikes_inasistencia = 0,
    this.esta_baneado = false,
    this.estado_solicitud_tutor = 'ninguna',
  });

  /// Convierte la información del objeto de usuario actual a un formato de lista de parejas (Mapa/Diccionario).
  /// Sirve para poder enviar y guardar correctamente toda la información del usuario en la base de datos de Firebase.
  Map<String, dynamic> toMap() {
    return {
      'identificadorUnico': identificadorUnico,
      'nombreCompleto': nombreCompleto,
      'correoElectronico': correoElectronico,
      'rolEnElSistema': rolEnElSistema.name,
      'facultad': facultad,
      'carrera': carrera,
      'listaDeTutoresSuscritos': listaDeTutoresSuscritos,
      'strikes_inasistencia': strikes_inasistencia,
      'esta_baneado': esta_baneado,
      'estado_solicitud_tutor': estado_solicitud_tutor,
    };
  }

  /// Construye un objeto de usuario leyendo y organizando la información descargada desde la base de datos (Firebase).
  /// Contiene protecciones: si llega un dato faltante o nulo, asigna valores por defecto para evitar que la app colapse.
  factory UsuarioModel.fromMap(Map<String, dynamic>? mapaDeDatos) {
    // Protección 1: Si no llegan datos por algún error en la red o base de datos, retornamos un usuario vacío seguro.
    if (mapaDeDatos == null) {
      return UsuarioModel(
        identificadorUnico: '',
        nombreCompleto: 'Usuario Desconocido',
        correoElectronico: '',
        rolEnElSistema: RolSistema.estudiante,
        listaDeTutoresSuscritos: [],
        strikes_inasistencia: 0,
        esta_baneado: false,
        estado_solicitud_tutor: 'ninguna',
      );
    }

    // Protección 2: Asignamos valores predeterminados (como '' o 'estudiante') usando el operador ?? por si algún campo específico viene nulo.
    return UsuarioModel(
      identificadorUnico: mapaDeDatos['identificadorUnico'] ?? '',
      nombreCompleto: mapaDeDatos['nombreCompleto'] ?? 'Usuario Desconocido',
      correoElectronico: mapaDeDatos['correoElectronico'] ?? '',
      rolEnElSistema: RolSistema.values.firstWhere(
        (rol) => rol.name == mapaDeDatos['rolEnElSistema'],
        orElse: () => RolSistema.estudiante,
      ),
      
      // La facultad y la carrera aceptan valores nulos de forma natural, por lo que no es necesario un valor por defecto drástico.
      facultad: mapaDeDatos['facultad'],
      carrera: mapaDeDatos['carrera'],
      
      // Protección 3: Chequeamos si existe la lista de tutores. Si no existe en la base de datos, asignamos una lista vacía [].
      listaDeTutoresSuscritos: mapaDeDatos['listaDeTutoresSuscritos'] != null
          ? List<String>.from(mapaDeDatos['listaDeTutoresSuscritos'])
          : [],
      strikes_inasistencia: mapaDeDatos['strikes_inasistencia'] ?? 0,
      esta_baneado: mapaDeDatos['esta_baneado'] ?? false,
      estado_solicitud_tutor: mapaDeDatos['estado_solicitud_tutor'] ?? 'ninguna',
    );
  }

  /// Método utilitario ágil diseñado para facilitar auditorías y verificaciones de permisos a lo largo de la app.
  /// Compara el rol asignado actualmente al perfil frente a un rol específico introducido como parámetro.
  bool tieneRol(RolSistema rolRequerido) {
    return rolEnElSistema == rolRequerido;
  }

  /// Crea una réplica del usuario actual variando las propiedades que se necesiten actualizar.
  UsuarioModel copyWith({
    String? identificadorUnico,
    String? nombreCompleto,
    String? correoElectronico,
    RolSistema? rolEnElSistema,
    String? facultad,
    String? carrera,
    List<String>? listaDeTutoresSuscritos,
    int? strikes_inasistencia,
    bool? esta_baneado,
    String? estado_solicitud_tutor,
  }) {
    return UsuarioModel(
      identificadorUnico: identificadorUnico ?? this.identificadorUnico,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correoElectronico: correoElectronico ?? this.correoElectronico,
      rolEnElSistema: rolEnElSistema ?? this.rolEnElSistema,
      facultad: facultad ?? this.facultad,
      carrera: carrera ?? this.carrera,
      listaDeTutoresSuscritos: listaDeTutoresSuscritos ?? this.listaDeTutoresSuscritos,
      strikes_inasistencia: strikes_inasistencia ?? this.strikes_inasistencia,
      esta_baneado: esta_baneado ?? this.esta_baneado,
      estado_solicitud_tutor: estado_solicitud_tutor ?? this.estado_solicitud_tutor,
    );
  }
}
