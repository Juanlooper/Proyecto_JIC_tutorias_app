import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart'; // Importamos el molde de usuario que creamos antes

/// Servicio principal de Autenticación de la Plataforma.
/// Funciona como el "recepcionista" y "guardia de seguridad" de la app.
/// Su misión es validar quién entra, quién sale, y crear las fichas de los usuarios nuevos.
class AutenticacionServicio {
  
  /// Herramienta conectada a Firebase Auth para manejar correos y contraseñas.
  /// Es la llave maestra para manejar sesiones seguras.
  final FirebaseAuth _llavesDeAcceso = FirebaseAuth.instance;

  /// Herramienta conectada a Firestore para leer y guardar la base de datos adicional.
  /// La usamos para guardar el nombre completo, carrera y otras cosas que Auth no guarda por sí solo.
  final FirebaseFirestore _baseDeDatos = FirebaseFirestore.instance;

  /// Inscribe a un estudiante/tutor nuevo por primera vez.
  /// Retorna un texto (String) que indica si todo salió bien o si hubo algún error específico,
  /// ideal para que Alejandra muestre esos mensajes en pop-ups en la pantalla.
  Future<String> registrarNuevoUsuario({
    required String correoElectronico,
    required String contrasenaSecreta,
    required String nombreCompleto,
    String? facultad,
    String? carrera,
  }) async {
    try {


      // Paso 1: Pedimos permiso a Firebase para crear la cuenta de seguridad
      UserCredential credencialesCreadas = await _llavesDeAcceso.createUserWithEmailAndPassword(
        email: correoElectronico,
        password: contrasenaSecreta,
      );

      // Verificamos si realmente se asignó un usuario con éxito
      if (credencialesCreadas.user != null) {
        // Acabamos de obtener el comprobante de seguridad (ID) de este usuario
        String identificadorRecienNacido = credencialesCreadas.user!.uid;

        // Paso 2: Armamos nuestra estructura con el modelo que entiende el negocio (UsuarioModel)
        UsuarioModel nuevoUsuario = UsuarioModel(
          identificadorUnico: identificadorRecienNacido,
          nombreCompleto: nombreCompleto,
          correoElectronico: correoElectronico,
          rolEnElSistema: RolSistema.estudiante, // Valor por defecto. Se asume que todo el que se registra es inicialmente estudiante.
          facultad: facultad,
          carrera: carrera,
          listaDeTutoresSuscritos: [], // Al ser nuevo, no tiene a nadie en su lista
        );

        // Paso 3: Depositamos la ficha oficial de este usuario dentro de la colección 'usuarios'
        await _baseDeDatos
            .collection('usuarios')
            .doc(identificadorRecienNacido)
            .set(nuevoUsuario.toMap());

        return "Registro Exitoso"; // Mensaje que la interfaz comprenderá como éxito
      } else {
        return "El sistema falló en procesar la identidad. Inténtalo de nuevo.";
      }
    } on FirebaseAuthException catch (errorFirebase) {
      // Capturamos cualquier caja de error nativa de la nube y la ponemos en español para Alejandra.
      if (errorFirebase.code == 'weak-password') {
        return "La contraseña ingresada es demasiado débil o fácil de adivinar.";
      } else if (errorFirebase.code == 'email-already-in-use') {
        return "Ups. Ese correo electrónico ya está registrado en nuestra plataforma.";
      } else if (errorFirebase.code == 'invalid-email') {
        return "Escribe el correo electrónico en un formato correcto.";
      } else {
        return "Detalle técnico de registro: ${errorFirebase.message}";
      }
    } catch (errorGeneral) {
      // El bloque "catch" principal evitará que toda la aplicación colapse si algo explota
      return "Se produjo un error crítico. Por favor, revisa tu conexión e inténtalo otra vez.";
    }
  }

  /// Permite iniciar sesión a un usuario existente en la plataforma.
  ///
  /// Conecta con Firebase Auth. En caso de éxito, la función retorna `null`
  /// para dar paso libre al inicio de la sesión.
  /// Durante el proceso capturamos excepciones del tipo [FirebaseAuthException]
  /// y retornamos un [String]? conteniendo el mensaje de error traducido,
  /// que será empleado en la interfaz gráfica para dar feedback al usuario.
  ///
  /// Flujo de Excepciones:
  /// - `user-not-found`: Se dispara al no existir usuario vinculado con el correo.
  /// - `wrong-password`: El usuario erró la contraseña indicada.
  /// - `invalid-email`: El input de correo es un texto sin el formato esperado.
  /// - `user-disabled`: El usuario existe pero su acceso está bloqueado administrativamente.
  /// - Exception general (`catch` default): Errores varios, usualmente de red o sistema.
  Future<String?> iniciarSesion({
    required String correoElectronico,
    required String contrasenaSecreta,
  }) async {
    try {
      // Intentamos girar la llave en el sistema
      await _llavesDeAcceso.signInWithEmailAndPassword(
        email: correoElectronico,
        password: contrasenaSecreta,
      );
      
      // Retornamos null para simbolizar el éxito del proceso
      return null;

    } on FirebaseAuthException catch (e) {
      // Lógica precisa para interceder por los errores de FirebaseAuth
      switch (e.code) {
        case 'invalid-credential':
          return "Credenciales incorrectas. Verifique su correo y contraseña.";
        case 'user-not-found':
          return "El correo electrónico no se encuentra registrado";
        case 'wrong-password':
          return "La contraseña ingresada es incorrecta";
        case 'invalid-email':
          return "El formato del correo es inválido (ejemplo@utp.ac.pa)";
        case 'user-disabled':
          return "Esta cuenta ha sido deshabilitada por el administrador";
        default:
          return "Error inesperado al intentar iniciar sesión. Inténtelo de nuevo";
      }
    } catch (e) {
      // Atrapamos errores generales
      return "Error inesperado al intentar iniciar sesión. Inténtelo de nuevo";
    }
  }

  /// Se encarga de destruir por completo los rastros temporales de sesión.
  /// Impide que otra persona siga usando el dispositivo con este usuario logueado.
  Future<void> cerrarSesion() async {
    try {
      await _llavesDeAcceso.signOut();
    } catch (errorGeneral) {
      // Es muy raro que esto falle, pero de igual forma lo "atrapamos" para evitar cierres violentos.
    }
  }

  /// Es la encargada de buscar en la nube quién es exactamente el usuario que tiene ahora el teléfono encendido.
  /// Sirve para dibujar los perfiles e interfaces personalizadas inmediatamente después de que alguien inicie sesión.
  Future<UsuarioModel?> obtenerDatosDelUsuarioActual() async {
    try {
      // 1. Preguntamos a FirebaseAuth quién nos acompaña en este bloque de sesión
      User? visitanteActivo = _llavesDeAcceso.currentUser;

      if (visitanteActivo == null) {
        // La persona que busca información no está realmente logueada (o la sesión caducó)
        return null; 
      }

      String identificadorActual = visitanteActivo.uid;

      // 2. Teniendo su ID, vamos a la base de datos Firestore y buscamos su carpeta en el cajón de 'usuarios'
      DocumentSnapshot registroFisicoBD = await _baseDeDatos
          .collection('usuarios')
          .doc(identificadorActual)
          .get();

      // 3. Revisamos que sí fue encontrado su registro
      if (registroFisicoBD.exists) {
        // Rescatamos los datos como mapa nativo y se lo pasamos al modelo 'UsuarioModel' para que los convierta
        var informacionMapeada = registroFisicoBD.data() as Map<String, dynamic>?;
        return UsuarioModel.fromMap(informacionMapeada);
      } else {
        // En los casos bordes donde se generaron llaves pero nunca se metió el usuario a una colección
        return null; 
      }
      
    } catch (errorGeneral) {
      // Manejador del error, si se nos cae el internet a medio paso retornamos tranquilamente un espacio vacío.
      return null;
    }
  }

  /// Dispara un correo de verificacion hacia la bandeja del usuario registrado.
  /// Documentacion para Maiky: La verificacion de correo es vital para evitar "usuarios fantasma"
  /// en la base de datos. Sin ella, cualquier persona podria registrarse con un correo ajeno
  /// (incluso inventado) y contaminar la coleccion 'usuarios' con perfiles ficticios que jamas
  /// podran recuperar su acceso ni confirmar su identidad academica real.
  Future<String> enviarVerificacionDeCorreo() async {
    try {
      User? visitanteActivo = _llavesDeAcceso.currentUser;

      if (visitanteActivo == null) {
        return "No hay ninguna sesion activa para verificar.";
      }

      await visitanteActivo.sendEmailVerification();
      return "Verificacion Enviada";

    } on FirebaseAuthException catch (errorFirebase) {
      if (errorFirebase.code == 'too-many-requests') {
        return "Has solicitado demasiadas verificaciones. Espera unos minutos antes de intentar nuevamente.";
      }
      return "Error al enviar verificacion: ${errorFirebase.message}";
    } catch (errorGeneral) {
      return "Fallo critico al intentar enviar el correo de verificacion. Revisa tu conexion.";
    }
  }

  /// Envia un enlace seguro al buzon del usuario para que pueda restablecer su contrasena.
  /// Documentacion para Maiky: Este proceso es exclusivamente controlado por Firebase Auth, 
  /// quien genera un token temporal con caducidad. Nosotros jamas tocamos la contrasena directamente.
  Future<String> enviarRecuperacionDeContrasena(String correoDestino) async {
    try {
      await _llavesDeAcceso.sendPasswordResetEmail(email: correoDestino);
      return "Recuperacion Enviada";

    } on FirebaseAuthException catch (errorFirebase) {
      if (errorFirebase.code == 'user-not-found' || errorFirebase.code == 'invalid-email') {
        return "No existe ninguna cuenta asociada a ese correo electronico.";
      } else if (errorFirebase.code == 'too-many-requests') {
        return "Demasiados intentos de recuperacion. Espera unos minutos.";
      }
      return "Error en el proceso de recuperacion: ${errorFirebase.message}";
    } catch (errorGeneral) {
      return "Fallo critico al solicitar la recuperacion. Verifica tu conexion a internet.";
    }
  }
}
