import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Lista privada de solicitudes desechadas o ignoradas por este tutor en su panel.
  List<String> _idsOcultosPorTutor = [];

  /// Contenedor estandarizado en donde depositaremos las razones descriptivas por el cual algo natural del flujo falló.
  String _mensajeDeErrorDelSistema = '';

  // Getters. Dan permiso a la Interfaz Gráfica para admirar el contenido actual de las listas y variables,
  // con la restricción de que es de "solo-lectura" salvaguardando así la lógica íntegra del backend.
  List<TutoriaModel> get tutoriasPendientesGenerales => _tutoriasPendientesGenerales.where((tutoria) => !_idsOcultosPorTutor.contains(tutoria.identificadorDeTutoria)).toList();
  List<TutoriaModel> get tutoriasSuscritasDelUsuario => _tutoriasSuscritasDelUsuario;
  bool get estaCargandoPeticionEnNube => _estaCargandoPeticionEnNube;
  String get mensajeDeErrorDelSistema => _mensajeDeErrorDelSistema;

  /// Requerimiento para Maiky: Calcula automáticamente el flujo de horas impartidas.
  /// No usa tildes. Recorre todas las tutorías dadas y computa el delta entre hora Inicio y Fin.
  double get totalHorasDictadas {
    double acumuladoFinal = 0.0;
    for (var claseParticular in _tutoriasSuscritasDelUsuario) {
      if (claseParticular.estadoDeLaSolicitud == 'finalizada' &&
          claseParticular.horaInicioReal != null &&
          claseParticular.horaFinReal != null) {
        acumuladoFinal += claseParticular.horaFinReal!.difference(claseParticular.horaInicioReal!).inMinutes / 60.0;
      }
    }
    return acumuladoFinal;
  }

  /// Problema de negocio que resuelve: Evita que un estudiante de Civil vea y acepte por 
  /// accidente clases super complicadas de Programacion. Al pasar una "carreraFiltro", 
  /// Maiky descarta inmediatamente todo lo que no concuerda. Si el filtro es nulo, atrae todas.
  Future<void> cargarListadoDeTutoriasPendientes([String? carreraFiltro]) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    // Transporta los bloques puros crudos de Firestore a una lista nativa transitoria
    List<TutoriaModel> lotesDeListaCompleta = await _motorBasesDeDatosGenuino.obtenerTutoriasPendientes();

    // Lógica de Maiky (Filtro Inteligente)
    if (carreraFiltro != null && carreraFiltro.trim().isNotEmpty) {
      _tutoriasPendientesGenerales = lotesDeListaCompleta
          .where((elementoTutoria) => elementoTutoria.carrera == carreraFiltro)
          .toList();
    } else {
      _tutoriasPendientesGenerales = lotesDeListaCompleta;
    }

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

  /// Oculta una solicitud para nosotros mismos actualizando la memoria efímera sin afectar a otros.
  void ocultarSolicitudParaMi(String idTutoria) {
    _idsOcultosPorTutor.add(idTutoria);
    notifyListeners();
  }

  /// Esta es la lógica crítica para asignar a un profesor al tablero de una sesión.
  /// Importancia de la Transacción Atómica: Al procesar esta operación, es vital agrupar 
  /// lectura y escritura como bloque inseparable en el servidor. Si dos maestros tocan aceptar 
  /// a la misma fracción de segundo, la transacción atómica asegura matemáticamente que uno de 
  /// ellos será rechazado, impidiendo que choquen y sobre-escriban corruptamente la tutoría.
  /// 
  /// [Fase Fan-Out Notificaciones]: NOTA TÉCNICA: En este punto exacto (al aceptar una tutoria validada), 
  /// el sistema debería/debe disparar la creación paralela de documentos en la colección 
  /// 'notificaciones'. Se extraería la "listaDeSuscritos" del tutor actual para replicar 
  /// masivamente un aviso a cada "idDestinatario", permitiendo que los alumnos sean concientes 
  /// de que su tutor favorito dictará algo pronto.
  Future<bool> aceptarTutoria(String idTutoria, String idTutor) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      // Localizamos la tutoría objetivo para validarla
      TutoriaModel? claseObjetivo = _tutoriasPendientesGenerales.firstWhere(
        (elemento) => elemento.identificadorDeTutoria == idTutoria
      );

      // Verificamos lógica de negocio:
      String nuevoEstadoDerivado = 'Aceptada';
      if (claseObjetivo.esGrupal == true && claseObjetivo.listaDeEstudiantesInscritos.length < claseObjetivo.cupoMaximo) {
         nuevoEstadoDerivado = 'Abierta';
      }

      // Este llamado debería, idealmente, conectar con un transaccional backend que acepte el estado.
      // Aquí delegamos a la función de Base de Datos.
      String resolucionDeLaPeticion = await _motorBasesDeDatosGenuino.aceptarTutoria(
        identificadorDeTutoriaEspecifica: idTutoria,
        maestroHerederoAlMando: idTutor,
        estadoPropuestoOpcional: nuevoEstadoDerivado, // Pasando el estado deducido
      );

      if (resolucionDeLaPeticion.contains("Extraordinario")) {
        await cargarListadoDeTutoriasPendientes();
        _apagarSenalIndicadoraDeEspera();
        notifyListeners();
        return true;
      } else {
        _mensajeDeErrorDelSistema = resolucionDeLaPeticion;
      }
    } catch (e) {
      _mensajeDeErrorDelSistema = "No se pudo identificar remotamente la tutoría seleccionada.";
    }

    _apagarSenalIndicadoraDeEspera();
    notifyListeners();
    return false;
  }

  /// Lógica de 'Moderación Automática' (Lazy Evaluation).
  /// Purga el inventario recorriendo la lista pública. Si una materia programada pasó de largo 
  /// (nadie la dio) por más de 30 minutos desde su hora de inicio oficial, y el cupo está 
  /// absolutamente en cero inscritos, la destituye de la base de datos mutando a "cancelada".
  Future<void> limpiarClasesVencidas() async {
    // Tolerancia militar. Permitimos 30 minutos extras por si el profesor llegó en atasco de tráfico
    DateTime rangoCritico = DateTime.now().subtract(const Duration(minutes: 30));
    bool limpiezaAutomatica = false;

    for (var materiaTemporal in _tutoriasPendientesGenerales) {
      if (materiaTemporal.estadoDeLaSolicitud == 'pendiente') {
        // Ejecucion algoritmica
        if (materiaTemporal.fechaHoraSugerida.isBefore(rangoCritico) && materiaTemporal.listaDeEstudiantesInscritos.isEmpty) {
          limpiezaAutomatica = true;
          
          try {
             // Notifica el deceso permanentemente hacia la nube de fuego (Firestore)
             await FirebaseFirestore.instance.collection('tutorias').doc(materiaTemporal.identificadorDeTutoria).update({
                'estadoDeLaSolicitud': 'cancelada'
             });
          } catch(e) {}
        }
      }
    }

    if (limpiezaAutomatica == true) {
      // Como alteramos estados silenciosamente, recargamos purificadamente el bloque principal.
      await cargarListadoDeTutoriasPendientes();
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

