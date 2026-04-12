import 'package:flutter/material.dart';
import '../models/tutoria_model.dart';
import '../services/base_de_datos_servicio.dart';

/// Proveedor de Estado Operativo para las Tutorías.
/// Actúa como una enorme "Pizarra Organizativa". Descarga el listado de las clases 
/// vírgenes disponibles desde la Base de Datos, las memoriza localmente, y luego 
/// avisa al diseño de Front-End de Alejandra que ya puede mostrar o "pintar" las Tarjetas y Listas en pantalla.
class TutoriasProvider extends ChangeNotifier {
  
  /// Motor que sirve y sabe exactamente cómo dialogar peticiones eficientes contra Firestore.
  final BaseDeDatosServicio _motorBasesDeDatosGenuino = BaseDeDatosServicio();

  /// El "Tablero Comunitario de la App". Contiene las materias que buscan un maestro de inmediato ('pendiente').
  List<TutoriaModel> _tutoriasPendientesGenerales = [];

  /// El "Calendario Privado". Reservado para almacenar en donde el estudiante en particular dictará o asistirá próximamente.
  List<TutoriaModel> _tutoriasSuscritasDelUsuario = [];

  /// Mecanismo semáforo. Cuando está activado (true), Alejandra debe poner un velo de progreso u oscuro
  /// evitando que alguna persona nerviosa toque 3 veces "Aceptar clase" y duplique procesos inintencionalmente.
  bool _estaCargandoPeticionEnNube = false;

  /// Contenedor estandarizado en donde depositaremos las razones descriptivas por el cual algo natural del flujo falló.
  String _mensajeDeErrorDelSistema = '';

  // Getters. Dan permiso a la Interfaz Gráfica para admirar el contenido actual de las listas y variables,
  // con la restricción de que es de "solo-lectura" salvaguardando así la lógica íntegra del backend.
  List<TutoriaModel> get tutoriasPendientesGenerales => _tutoriasPendientesGenerales;
  List<TutoriaModel> get tutoriasSuscritasDelUsuario => _tutoriasSuscritasDelUsuario;
  bool get estaCargandoPeticionEnNube => _estaCargandoPeticionEnNube;
  String get mensajeDeErrorDelSistema => _mensajeDeErrorDelSistema;

  /// Recopila eficientemente el catálogo público desde la conexión central.
  Future<void> cargarListadoDeTutoriasPendientes() async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    // Transporta los bloques puros crudos de Firestore a nuestra sofisticada lista nativa List<TutoriaModel>
    _tutoriasPendientesGenerales = await _motorBasesDeDatosGenuino.obtenerTutoriasPendientes();

    _apagarSenalIndicadoraDeEspera();
    
    // Alerta definitiva (notifyListeners) de que la estructura completa acaba de mutar: Reconstruye tus vistas UI, ¡el inventario cambió!
    notifyListeners();
  }

  /// Empuja de subida el prospecto de la nueva tutoría generada por el alumno hacia el sistema principal en nube.
  Future<bool> crearAperturaDeNuevaTutoria({required TutoriaModel planoFormateadoDelExamen}) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    bool huboVerdaderoExitoInformativo = await _motorBasesDeDatosGenuino.crearNuevaTutoria(modeloDeLaNuevaClase: planoFormateadoDelExamen);

    if (huboVerdaderoExitoInformativo == true) {
      // Como acabamos de plantar una clase de status 'pendiente', solicitamos sincronizar listas públicas y avisamos a la app que repinte.
      await cargarListadoDeTutoriasPendientes(); 
      return true;
    } else {
      _mensajeDeErrorDelSistema = "Las reglas del servidor han abortado la creación. Recuerda: No sugerir fechas pasadas o revisa tu conexión.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Usa el sistema de Array-Unión para clavar incisivamente el identificador del voluntario a una sesión particular.
  Future<bool> unirseAClaseMultitudinaria({
    required String identificacionGlobalDeLaClase,
    required String matriculaDeIdentidadDelEstudiante,
  }) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    String resolucionDeCargaInterna = await _motorBasesDeDatosGenuino.unirseATutoria(
      identificadorDeTutoriaEspecifica: identificacionGlobalDeLaClase,
      identificadorDeUnAlumnoFinal: matriculaDeIdentidadDelEstudiante,
    );

    if (resolucionDeCargaInterna.contains("Cupo Asegurado")) {
      // Volvemos a traer toda la lista pública para que los contadores visuales aumenten de alumnos inscritos en vivo.
      await cargarListadoDeTutoriasPendientes();
      return true;
    } else {
      _mensajeDeErrorDelSistema = resolucionDeCargaInterna;
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Reservado al Tutor: Convierte agresivamente el estado semántico de una materia abandonada 'Pendiente', haciéndola Oficial y 'Aceptada'.
  Future<bool> aceptarClaseAsignadaFormalmente({
    required String identificadorOficialDelBloque,
    required String huellaDigitalDelMaestroEntrante,
    String? URLDeConferenciaDeApoyo,
  }) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    String resolucionDeLaPeticion = await _motorBasesDeDatosGenuino.aceptarTutoria(
      identificadorDeTutoriaEspecifica: identificadorOficialDelBloque,
      maestroHerederoAlMando: huellaDigitalDelMaestroEntrante,
      linkOficialParaSesion: URLDeConferenciaDeApoyo,
    );

    if (resolucionDeLaPeticion.contains("Extraordinario")) {
      // Actualización masiva: Esa clase pasó a de la fase 'Pendiente' a 'Aceptada'. Al recargar lista Pendientes, habrá desaparecido misteriosamente y todo lucirá pulcro
      await cargarListadoDeTutoriasPendientes();
      return true;
    } else {
      _mensajeDeErrorDelSistema = resolucionDeLaPeticion;
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  // --- Herrajes y Engranajes Internos del State Manager ---

  void _iluminarSenalIndicadoraDeEspera() {
    _estaCargandoPeticionEnNube = true;
    notifyListeners();
  }

  void _apagarSenalIndicadoraDeEspera() {
    _estaCargandoPeticionEnNube = false;
  }

  void _purgarCasillasDeAdvertencias() {
    _mensajeDeErrorDelSistema = '';
  }
}
