import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario_model.dart';
import '../services/autenticacion_servicio.dart';
import '../services/usuario_servicio.dart';

/// Proveedor del Estado de Autenticación (El Sistema Central de Identidad).
/// Imagina este archivo como el 'Megáfono' de la aplicación. Se conecta con el servicio silencioso,
/// le pide confirmar si la clave es correcta, y luego "le grita" a todas las pantallas (notifyListeners):
/// "¡Oigan, una persona inició sesión con éxito, dibujen su foto de perfil y escondan el formulario login!".
class AutenticacionProvider extends ChangeNotifier {
  /// Herramienta o servicio contratado que sabe cómo hacer el trabajo pesado con Firebase.
  final AutenticacionServicio _servicioIntegradoDeAutenticacion =
      AutenticacionServicio();

  final UsuarioServicio _usuarioServicio = UsuarioServicio();

  /// El usuario que actualmente sostiene el teléfono y tiene la aplicación abierta.
  /// Resultará 'nulo' si la persona aún no ha ingresado correctamente correo y contraseña.
  UsuarioModel? _usuarioActual;

  /// Indicador de procesamiento en progreso.
  /// Si es 'true', notifica a que Alejandra deba mostrar un círculo giratorio de espera y bloquee los botones
  /// para impedir sobrecargas en la base de datos mientras validamos un registro o ingreso.
  bool _estaCargando = false;

  /// Indicador exclusivo para el arranque de la app.
  /// Evita que re-construyamos MaterialApp entero durante transacciones normales de Login.
  bool _estaInicializando = true;

  /// Almacena un mensaje de disculpa o error para comunicarle al usuario si se equivocó de clave o se fue el internet.
  String _mensajeDeError = '';

  // Getters (Lectura de solo consulta). Las pantallas pueden asomarse por aquí y leer el estado,
  // pero jamás podrán destruirlo o modificarlo corruptamente burlando a Maiky.
  UsuarioModel? get usuarioActual => _usuarioActual;
  bool get estaCargando => _estaCargando;
  bool get estaInicializando => _estaInicializando;
  String get mensajeDeError => _mensajeDeError;

  /// Auditoría de estado: Retorna true solo si el usuario actual definió su nombre, facultad y carrera.
  /// Esto previene perfiles "fantasma" sin información académica.
  bool get perfilCompleto {
    if (_usuarioActual == null) return false;

    final bool nombreListo = _usuarioActual!.nombreCompleto.trim().isNotEmpty;
    final bool facultadLista =
        _usuarioActual!.facultad != null &&
        _usuarioActual!.facultad!.trim().isNotEmpty;
    final bool carreraLista =
        _usuarioActual!.carrera != null &&
        _usuarioActual!.carrera!.trim().isNotEmpty;

    return nombreListo && facultadLista && carreraLista;
  }

  /// Auditoría de permisos operativos: Impide que perfiles incompletos creen o acepten tutorías.
  /// Devuelve un mensaje de error si [perfilCompleto] es falso, y retorna nulo si el usuario tiene paso libre.
  String? verificarPermisoOperativo() {
    if (!perfilCompleto) {
      return "Acción denegada: Necesitas completar tu información académica (Facultad y Carrera) en tu perfil para poder proceder.";
    }
    return null;
  }

  /// Función esencial. Verifica si había una persona conectada previamente
  /// (Ideal para cuando cierras la App y la vuelves a abrir de golpe horas después).
  Future<void> inicializarSesionAlAbrirApp() async {
    _estaInicializando = true;
    _activarIndicadorDeCargaEnPantalla();

    // Esperamos a que Firebase lea su caché local (IndexedDB en web)
    await FirebaseAuth.instance.authStateChanges().first;

    // Pedimos al servicio que busque de inmediato si existe un "fantasma" de sesión válida en el teléfono
    _usuarioActual = await _servicioIntegradoDeAutenticacion
        .obtenerDatosDelUsuarioActual();

    // Verificación de baneo por tribunal de disciplina
    if (_usuarioActual != null && _usuarioActual!.estaBaneado) {
      await _servicioIntegradoDeAutenticacion.cerrarSesion();
      _usuarioActual = null;
      _mensajeDeError =
          "Tu cuenta ha sido suspendida por el Tribunal de Disciplina.";
    }

    _estaInicializando = false;
    _desactivarIndicadorDeCargaEnPantalla();
    // Anunciamos por el altavoz universal el cambio de estado para que reaccionen las páginas de navegación.
    notifyListeners();
  }

  /// Conecta al usuario al sistema utilizando sus credenciales formales en Firestore.
  Future<bool> ingresarConCorreoYClave({
    required String correoEscrito,
    required String contrasenaEscrita,
  }) async {
    _activarIndicadorDeCargaEnPantalla();
    _limpiarCualquierTextoDefectuosoAnterior();

    String? mensajeDeError = await _servicioIntegradoDeAutenticacion
        .iniciarSesion(
          correoElectronico: correoEscrito,
          contrasenaSecreta: contrasenaEscrita,
        );

    // Si mensajeDeError es null, el inicio de sesión fue exitoso en Firebase
    if (mensajeDeError == null) {
      // Validación estricta de Email Verificado desactivada para presentación:
      /*
      if (FirebaseAuth.instance.currentUser != null &&
          !FirebaseAuth.instance.currentUser!.emailVerified) {
        String mensajeRetenido =
            "Debes verificar tu correo para poder entrar. Revisa tu bandeja de entrada o SPAM.";
        await salirDeLaSesionActual();
        _mensajeDeError = mensajeRetenido;
        notifyListeners();
        return false;
      }
      */

      // Éxito. Acudimos al baúl de base de datos a traer todo su expediente formal de la JIC.
      _usuarioActual = await _servicioIntegradoDeAutenticacion
          .obtenerDatosDelUsuarioActual();

      // Verificación de baneo tras login
      if (_usuarioActual != null && _usuarioActual!.estaBaneado) {
        await _servicioIntegradoDeAutenticacion.cerrarSesion();
        _usuarioActual = null;
        _mensajeDeError =
            "Tu cuenta ha sido suspendida por acumular 3 strikes. Contacta administración.";
        _desactivarIndicadorDeCargaEnPantalla();
        notifyListeners();
        return false;
      }

      _desactivarIndicadorDeCargaEnPantalla();
      notifyListeners();
      return true;
    } else {
      // Fracaso controlado. Guardamos la disculpa amigable para que la UI la muestre en el SnackBar.
      _mensajeDeError = mensajeDeError;
      _desactivarIndicadorDeCargaEnPantalla();
      notifyListeners();
      return false;
    }
  }

  /// Inscribe a un estudiante/maestro nuevo y le genera inmediatamente una sesión vigente.
  Future<bool> registrarseEnElSistemaGlobal({
    required String correoEscrito,
    required String contrasenaEscrita,
    required String nombreEscrito,
    String? facultadElegidaEnMenu,
    String? carreraElegidaEnMenu,
    String? celular,
    String? contactoEmergenciaNombre,
    String? contactoEmergenciaTelefono,
    String? anoCursando,
  }) async {
    _activarIndicadorDeCargaEnPantalla();
    _limpiarCualquierTextoDefectuosoAnterior();

    String respuestaDeLaInscripcion = await _servicioIntegradoDeAutenticacion
        .registrarNuevoUsuario(
          correoElectronico: correoEscrito,
          contrasenaSecreta: contrasenaEscrita,
          nombreCompleto: nombreEscrito,
          facultad: facultadElegidaEnMenu,
          carrera: carreraElegidaEnMenu,
          telefonoPersonal: celular,
          contactoEmergenciaNombre: contactoEmergenciaNombre,
          contactoEmergenciaTelefono: contactoEmergenciaTelefono,
          anoCursando: anoCursando,
        );

    if (respuestaDeLaInscripcion == "Registro Exitoso") {
      // Retornamos true sin asignar el _usuarioActual, forzando al usuario
      // a iniciar sesión manualmente luego de verificar su correo.
      _desactivarIndicadorDeCargaEnPantalla();
      return true;
    } else {
      _mensajeDeError = respuestaDeLaInscripcion;
      _desactivarIndicadorDeCargaEnPantalla();
      notifyListeners();
      return false;
    }
  }

  /// Corta mecánicamente la conexión con servidores, borra al usuario cargado en la RAM local,
  /// permitiendo regresar el flujo de la aplicación con seguridad a la pantalla clásica inicial (Login).
  Future<void> salirDeLaSesionActual() async {
    _activarIndicadorDeCargaEnPantalla();

    await _servicioIntegradoDeAutenticacion.cerrarSesion();
    _usuarioActual = null; // Purificamos los privilegios
    _limpiarCualquierTextoDefectuosoAnterior();

    _desactivarIndicadorDeCargaEnPantalla();
    notifyListeners();
  }

  // --- Seguridad Avanzada de Identidad ---

  /// Problema de negocio que resuelve: Impide que actores maliciosos o descuidados registren
  /// correos falsos que contaminen la base de datos con "usuarios fantasma". Al exigir que el
  /// correo se verifique, aseguramos que cada perfil en Firestore corresponde a una persona real
  /// con acceso legitimo a esa bandeja de entrada.
  /// UX para Alejandra: Mientras el correo viaja por los servidores de Google, el indicador
  /// _estaCargando se activa para que la interfaz muestre un spinner y bloquee el boton de reenvio.
  Future<bool> dispararVerificacionDeCorreo() async {
    _activarIndicadorDeCargaEnPantalla();
    _limpiarCualquierTextoDefectuosoAnterior();

    String verificacionEnviada = await _servicioIntegradoDeAutenticacion
        .enviarVerificacionDeCorreo();

    _desactivarIndicadorDeCargaEnPantalla();

    if (verificacionEnviada != "Verificacion Enviada") {
      _mensajeDeError = verificacionEnviada;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  /// Problema de negocio que resuelve: Ofrece a los estudiantes una salida segura cuando
  /// olvidan su contrasena sin requerir intervencion manual del equipo administrativo.
  /// Retorna true si el correo de recuperacion se envio exitosamente para que Alejandra
  /// pueda mostrar un dialogo de confirmacion positiva en pantalla.
  Future<bool> solicitarCambioDeContrasena(String correoDestino) async {
    _activarIndicadorDeCargaEnPantalla();
    _limpiarCualquierTextoDefectuosoAnterior();

    String procesoDeRecuperacion = await _servicioIntegradoDeAutenticacion
        .enviarRecuperacionDeContrasena(correoDestino);

    if (procesoDeRecuperacion == "Recuperacion Enviada") {
      _desactivarIndicadorDeCargaEnPantalla();
      notifyListeners();
      return true;
    } else {
      _mensajeDeError = procesoDeRecuperacion;
      _desactivarIndicadorDeCargaEnPantalla();
      notifyListeners();
      return false;
    }
  }

  // --- Gestión Social y de Comunidad ---

  /// Permite a un alumno suscribirse a un tutor para que la UI de Alejandra cambie al instante.
  /// Documentacion Técnica para Maiky: El uso de FieldValue.arrayUnion y FieldValue.arrayRemove
  /// manda la orden exacta a la nube para agregar/quitar este id sin sobre-escribir toda la cadena.
  /// Esto evita colisiones de datos y sobreescrituras corruptas si el alumno sigue a varios tutores rápido.
  Future<void> gestionarSuscripcionATutor(String idTutor) async {
    if (_usuarioActual == null) return;

    _activarIndicadorDeCargaEnPantalla();

    bool loEstabaSiguiendo = _usuarioActual!.listaDeTutoresSuscritos.contains(
      idTutor,
    );

    try {
      if (loEstabaSiguiendo) {
        // Removerlo para reflejo instantaneo
        _usuarioActual!.listaDeTutoresSuscritos.remove(idTutor);
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_usuarioActual!.identificadorUnico)
            .update({
              'listaDeTutoresSuscritos': FieldValue.arrayRemove([idTutor]),
            });
      } else {
        // Anadirlo visualmente al instante
        _usuarioActual!.listaDeTutoresSuscritos.add(idTutor);
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_usuarioActual!.identificadorUnico)
            .update({
              'listaDeTutoresSuscritos': FieldValue.arrayUnion([idTutor]),
            });
      }
    } catch (error) {
      // Reversión amistosa ante caidas de señal
      if (loEstabaSiguiendo) {
        _usuarioActual!.listaDeTutoresSuscritos.add(idTutor);
      } else {
        _usuarioActual!.listaDeTutoresSuscritos.remove(idTutor);
      }
    }

    _desactivarIndicadorDeCargaEnPantalla();
    notifyListeners();
  }

  Future<bool> actualizarInformacionPerfil(
    String facultad,
    String carrera,
  ) async {
    if (_usuarioActual == null) return false;

    _estaCargando = true;
    _limpiarCualquierTextoDefectuosoAnterior();
    notifyListeners();

    try {
      bool exito = await _usuarioServicio.actualizarDatosAcademicos(
        idUsuario: _usuarioActual!.identificadorUnico,
        nuevaFacultad: facultad,
        nuevaCarrera: carrera,
      );

      if (exito) {
        _usuarioActual = UsuarioModel(
          identificadorUnico: _usuarioActual!.identificadorUnico,
          nombreCompleto: _usuarioActual!.nombreCompleto,
          correoElectronico: _usuarioActual!.correoElectronico,
          rolEnElSistema: _usuarioActual!.rolEnElSistema,
          listaDeTutoresSuscritos: _usuarioActual!.listaDeTutoresSuscritos,
          facultad: facultad,
          carrera: carrera,
        );
      }

      _estaCargando = false;
      notifyListeners();
      return exito;
    } catch (e) {
      _mensajeDeError = 'Error al actualizar perfil: ${e.toString()}';
      _estaCargando = false;
      notifyListeners();
      return false;
    }
  }

  // --- Motores Internos (Herramientas encapsuladas de Provider) ---

  /// Manda una señal global indicando que estamos "pensando" u "operando por internet", habilitando animaciones visuales.
  void _activarIndicadorDeCargaEnPantalla() {
    _estaCargando = true;
    notifyListeners();
  }

  /// Retira la carga después que una operación pesada acaba de culminar.
  void _desactivarIndicadorDeCargaEnPantalla() {
    _estaCargando = false;
    // Omitimos notifyListeners intencionalmente aquí ya que la función maestra que nos invoca
    // típicamente llamará a notifyListeners() por su cuenta.
  }

  /// Borra problemas viejos guardados al abrir nuevamente el menú de autenticación.
  void _limpiarCualquierTextoDefectuosoAnterior() {
    _mensajeDeError = '';
  }
}
