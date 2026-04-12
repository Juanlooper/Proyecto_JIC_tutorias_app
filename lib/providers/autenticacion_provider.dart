import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../services/autenticacion_servicio.dart';

/// Proveedor del Estado de Autenticación (El Sistema Central de Identidad).
/// Imagina este archivo como el 'Megáfono' de la aplicación. Se conecta con el servicio silencioso,
/// le pide confirmar si la clave es correcta, y luego "le grita" a todas las pantallas (notifyListeners): 
/// "¡Oigan, una persona inició sesión con éxito, dibujen su foto de perfil y escondan el formulario login!".
class AutenticacionProvider extends ChangeNotifier {
  
  /// Herramienta o servicio contratado que sabe cómo hacer el trabajo pesado con Firebase.
  final AutenticacionServicio _servicioIntegradoDeAutenticacion = AutenticacionServicio();

  /// El usuario que actualmente sostiene el teléfono y tiene la aplicación abierta.
  /// Resultará 'nulo' si la persona aún no ha ingresado correctamente correo y contraseña.
  UsuarioModel? _usuarioActual;

  /// Indicador de procesamiento en progreso. 
  /// Si es 'true', notifica a que Alejandra deba mostrar un círculo giratorio de espera y bloquee los botones
  /// para impedir sobrecargas en la base de datos mientras validamos un registro o ingreso.
  bool _estaCargando = false;

  /// Almacena un mensaje de disculpa o error para comunicarle al usuario si se equivocó de clave o se fue el internet.
  String _mensajeDeError = '';

  // Getters (Lectura de solo consulta). Las pantallas pueden asomarse por aquí y leer el estado,
  // pero jamás podrán destruirlo o modificarlo corruptamente burlando a Maiky.
  UsuarioModel? get usuarioActual => _usuarioActual;
  bool get estaCargando => _estaCargando;
  String get mensajeDeError => _mensajeDeError;

  /// Función esencial. Verifica si había una persona conectada previamente
  /// (Ideal para cuando cierras la App y la vuelves a abrir de golpe horas después).
  Future<void> inicializarSesionAlAbrirApp() async {
    _activarIndicadorDeCargaEnPantalla();

    // Pedimos al servicio que busque de inmediato si existe un "fantasma" de sesión válida en el teléfono
    _usuarioActual = await _servicioIntegradoDeAutenticacion.obtenerDatosDelUsuarioActual();
    
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

    String respuestaCrudaDelServidor = await _servicioIntegradoDeAutenticacion.iniciarSesion(
      correoElectronico: correoEscrito,
      contrasenaSecreta: contrasenaEscrita,
    );

    if (respuestaCrudaDelServidor == "Acceso Concedido") {
      // Éxito. Acudimos al baúl de base de datos a traer todo su expediente formal de la JIC.
      _usuarioActual = await _servicioIntegradoDeAutenticacion.obtenerDatosDelUsuarioActual();
      _desactivarIndicadorDeCargaEnPantalla();
      notifyListeners();
      return true; 
    } else {
      // Fracaso controlado. Guardamos la disculpa amigable para que Alejandra la pinte en rojo brillante.
      _mensajeDeError = respuestaCrudaDelServidor;
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
  }) async {
    _activarIndicadorDeCargaEnPantalla();
    _limpiarCualquierTextoDefectuosoAnterior();

    String respuestaDeLaInscripcion = await _servicioIntegradoDeAutenticacion.registrarNuevoUsuario(
      correoElectronico: correoEscrito,
      contrasenaSecreta: contrasenaEscrita,
      nombreCompleto: nombreEscrito,
      facultad: facultadElegidaEnMenu,
      carrera: carreraElegidaEnMenu,
    );

    if (respuestaDeLaInscripcion == "Registro Exitoso") {
      // Lo autorizamos, de manera que buscamos e implantamos oficialmente su perfil como usuario en control activo.
      _usuarioActual = await _servicioIntegradoDeAutenticacion.obtenerDatosDelUsuarioActual();
      _desactivarIndicadorDeCargaEnPantalla();
      notifyListeners();
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
