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

  /// Rol dentro del sistema. Los valores permitidos son: 'estudiante', 'tutor' o 'admin'.
  /// Sirve para saber qué permisos se le otorgan en la aplicación y qué pantallas puede visualizar.
  final String rolEnElSistema;

  /// Facultad a la que pertenece el usuario (Ejemplo: Ingeniería en Sistemas).
  /// Puede ser nulo (vacío) si el usuario aún no ha llenado este dato o su perfil es más general.
  final String? facultad;

  /// Carrera universitaria que estudia o dicta el usuario (Ejemplo: Desarrollo de Software).
  /// Puede ser nulo (vacío) si no ha especificado la carrera dentro de la aplicación.
  final String? carrera;

  /// Lista de los identificadores únicos de los tutores a los que el usuario se ha suscrito.
  /// Sirve para vincular al estudiante con sus tutores seleccionados y mostrar rápidamente a quiénes sigue.
  final List<String> listaDeTutoresSuscritos;

  /// Función constructora que inicializa o "crea" la representación del usuario cuando ya tenemos su información.
  UsuarioModel({
    required this.identificadorUnico,
    required this.nombreCompleto,
    required this.correoElectronico,
    required this.rolEnElSistema,
    this.facultad,
    this.carrera,
    required this.listaDeTutoresSuscritos,
  });

  /// Convierte la información del objeto de usuario actual a un formato de lista de parejas (Mapa/Diccionario).
  /// Sirve para poder enviar y guardar correctamente toda la información del usuario en la base de datos de Firebase.
  Map<String, dynamic> toMap() {
    return {
      'identificadorUnico': identificadorUnico,
      'nombreCompleto': nombreCompleto,
      'correoElectronico': correoElectronico,
      'rolEnElSistema': rolEnElSistema,
      'facultad': facultad,
      'carrera': carrera,
      'listaDeTutoresSuscritos': listaDeTutoresSuscritos,
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
        rolEnElSistema: 'estudiante',
        listaDeTutoresSuscritos: [],
      );
    }

    // Protección 2: Asignamos valores predeterminados (como '' o 'estudiante') usando el operador ?? por si algún campo específico viene nulo.
    return UsuarioModel(
      identificadorUnico: mapaDeDatos['identificadorUnico'] ?? '',
      nombreCompleto: mapaDeDatos['nombreCompleto'] ?? 'Usuario Desconocido',
      correoElectronico: mapaDeDatos['correoElectronico'] ?? '',
      rolEnElSistema: mapaDeDatos['rolEnElSistema'] ?? 'estudiante',
      
      // La facultad y la carrera aceptan valores nulos de forma natural, por lo que no es necesario un valor por defecto drástico.
      facultad: mapaDeDatos['facultad'],
      carrera: mapaDeDatos['carrera'],
      
      // Protección 3: Chequeamos si existe la lista de tutores. Si no existe en la base de datos, asignamos una lista vacía [].
      listaDeTutoresSuscritos: mapaDeDatos['listaDeTutoresSuscritos'] != null
          ? List<String>.from(mapaDeDatos['listaDeTutoresSuscritos'])
          : [],
    );
  }
}
