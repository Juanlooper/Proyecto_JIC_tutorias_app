import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  /// Sistema de "Solicitudes Huérfanas" (Crowdsourcing de tutorías).
  /// Permite a la comunidad sugerir una tutoría que aún no cuenta con profesor ('identificadorDelTutor' está vacío).
  Future<bool> crearSolicitudHuerfana(TutoriaModel sugerencia) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final uidEstudiante = FirebaseAuth.instance.currentUser?.uid;
      if (uidEstudiante == null) {
        throw Exception("Sesión inactiva. Vuelve a ingresar para solicitar una clase.");
      }

      // 1. Inicialización Estricta (Blindaje Backend)
      // En lugar de arrastrar basura del formulario, forzamos que el array 
      // de apoyos nazca protegido con el UID del estudiante activo.
      List<String> apoyadoresIniciales = [uidEstudiante];

      final collectionRef = FirebaseFirestore.instance.collection('tutorias');
      String docId = sugerencia.identificadorDeTutoria.isEmpty 
          ? collectionRef.doc().id 
          : sugerencia.identificadorDeTutoria;

      // 1. Aplicar las reglas estrictas de la arquitectura
      TutoriaModel solicitudProcesada = sugerencia.copyWith(
        identificadorDeTutoria: docId,
        identificadorDelTutor: "", // String vacío para ser permitida
        estadoDeLaSolicitud: 'solicitada', // Distinguir de 'pendiente'
        listaDeEstudiantesInscritos: [], // El estudiante NO inicia inscrito (Regla de negocio nueva)
        estudiantesApoyando: apoyadoresIniciales,
      );

      Map<String, dynamic> datosNube = solicitudProcesada.toMap();
      datosNube['creador'] = uidEstudiante; // Guardar trazabilidad explícita del estudiante (creador original)

      // 2. Transmitir el documento a la colección en Firebase
      await collectionRef.doc(docId).set(datosNube);

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      _mensajeDeErrorDelSistema = e.toString().contains("Exception: ") ? e.toString().split("Exception: ").last : "Error al procesar la solicitud huérfana en la nube.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Permite al estudiante arrepentirse y borrar de la bolsa una solicitud huérfana que él creó.
  Future<bool> cancelarSolicitudHuerfana(String tutoriaId) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();
    try {
      // Aplicación de patrón Soft Delete para respetar políticas de seguridad en roles Estudiante.
      // La sugerencia desaparece orgánicamente de la vista gracias al StreamBuilder filtrado.
      await FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId).update({
        'estadoDeLaSolicitud': 'cancelada'
      });
      
      // Sincronizamos las listas globales por si alguien más la veía
      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      _mensajeDeErrorDelSistema = "No logramos eliminar la sugerencia de la bolsa.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Permite a la comunidad añadir su "voto" o apoyo sumándose a la listaDeEstudiantesInscritos de una sugerencia.
  Future<bool> apoyarSugerencia(String tutoriaId) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final uidUsuarioActual = FirebaseAuth.instance.currentUser?.uid;
      if (uidUsuarioActual == null) throw Exception("Debes iniciar sesión para apoyar una clase.");

      // Operación atómica y eficiente sugerida por la arquitectura Firestore
      await FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId).update({
        'estudiantesApoyando': FieldValue.arrayUnion([uidUsuarioActual])
      });

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      _mensajeDeErrorDelSistema = "Tuvimos un problema al intentar sumarte a esta tutoría comunitaria.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Permite a un estudiante darse de baja (retirar su apoyo/inscripción) de una tutoría, de manera rápida y eficiente sin mutar arrays locales manualmente.
  Future<bool> abandonarTutoria(String tutoriaId) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final uidUsuarioActual = FirebaseAuth.instance.currentUser?.uid;
      if (uidUsuarioActual == null) throw Exception("Debes iniciar sesión para realizar esta acción.");

      // Como abandonarTutoria se usaba también para retirar el apoyo, necesitamos saber si era una sugerencia
      final docSnapshot = await FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId).get();
      if (!docSnapshot.exists) throw Exception("Tutoría no encontrada.");
      
      final data = docSnapshot.data()!;
      if (data['estadoDeLaSolicitud'] == 'solicitada') {
        await FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId).update({
          'estudiantesApoyando': FieldValue.arrayRemove([uidUsuarioActual])
        });
      } else {
        await FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId).update({
          'listaDeEstudiantesInscritos': FieldValue.arrayRemove([uidUsuarioActual])
        });
      }

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      _mensajeDeErrorDelSistema = "Hubo un error al intentar retirarte de la tutoría.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }


  /// Implementación transaccional para inscribirse en tutorías, añadiendo los motivos y links.
  Future<bool> inscribirseEnTutoria(String tutoriaId, String uid, String textoMotivo, List<String> listaLinks) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final docRef = FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        if (!docSnapshot.exists) {
          throw "La tutoría no existe.";
        }
        
        final data = docSnapshot.data()!;
        List<dynamic> inscritos = data['listaDeEstudiantesInscritos'] ?? [];
        int cupoMaximo = data['cupoMaximo'] ?? 1;

        if (inscritos.length >= cupoMaximo) {
          throw "El cupo para esta tutoría está lleno.";
        }

        if (inscritos.contains(uid)) {
          throw "Ya te encuentras inscrito en esta clase.";
        }

        // Se resta capacidad mediante adición a la lista de estudiantes
        inscritos.add(uid);

        // Actualizamos los campos de motivos y adjuntos
        Map<String, dynamic> motivos = data['motivos_alumnos'] ?? {};
        motivos[uid] = textoMotivo;

        Map<String, dynamic> enlaces = data['enlaces_adjuntos'] ?? {};
        enlaces[uid] = listaLinks;

        transaction.update(docRef, {
          'listaDeEstudiantesInscritos': inscritos,
          'motivos_alumnos': motivos,
          'enlaces_adjuntos': enlaces,
        });
      });

      await cargarListadoDeTutoriasPendientes();
      return true;
    } catch (e) {
      _mensajeDeErrorDelSistema = e.toString().contains("Exception: ") ? e.toString().split("Exception: ").last : e.toString();
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

  // --- Consultas del Perfil Individual ---
  Future<void> cargarTutoriasSuscritasDelUsuario(String idUsuario) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();
    
    try {
      // Optamos por dos consultas asíncronas para unir ambos mundos: dictando y asistiendo
      final consultaTutor = FirebaseFirestore.instance.collection('tutorias')
          .where('identificadorDelTutor', isEqualTo: idUsuario)
          .get();
      
      final consultaEstudiante = FirebaseFirestore.instance.collection('tutorias')
          .where('listaDeEstudiantesInscritos', arrayContains: idUsuario)
          .get();
          
      final resultados = await Future.wait([consultaTutor, consultaEstudiante]);
      
      final Map<String, TutoriaModel> mapaUnico = {};
      
      for (var querySnapshot in resultados) {
        for (var doc in querySnapshot.docs) {
          final modelo = TutoriaModel.fromMap(doc.data());
          mapaUnico[modelo.identificadorDeTutoria] = modelo;
        }
      }
      
      _tutoriasSuscritasDelUsuario = mapaUnico.values.toList();
      // Refrescamos memoria visual de los contadores
      notifyListeners();
    } catch (e) {
      _mensajeDeErrorDelSistema = 'No se pudieron descargar tus tutorías.';
    }
    
    _apagarSenalIndicadoraDeEspera();
    notifyListeners();
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

  /// Método de asistencia de alumnos (Fase 2.1).
  /// Modifica registro de asistencia y penaliza (strike) a infractores de ausentismo.
  Future<bool> registrarAsistenciaClase(String tutoriaId, Map<String, bool> asistenciaAlumnos) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final tutoriaRef = FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId);
        
        transaction.update(tutoriaRef, {
          'registro_asistencia': asistenciaAlumnos,
          'estadoDeLaSolicitud': 'finalizada',
        });

        // Iteramos alumnos y penalizamos si tienen false (no asistieron)
        for (var entry in asistenciaAlumnos.entries) {
          if (entry.value == false) {
            final usuarioRef = FirebaseFirestore.instance.collection('usuarios').doc(entry.key);
            transaction.update(usuarioRef, {
              'strikes_inasistencia': FieldValue.increment(1),
            });
          }
        }
      });

      // Refrescar y avisar exito
      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      _mensajeDeErrorDelSistema = 'Error de conexión al procesar la asistencia.';
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Permite a un alumno retirar su inscripción de una clase previamente aceptada.
  /// Genera marcadores para advertencias de strike si cancela con menos de 12 horas.
  Future<bool> cancelarAsistenciaAlumno(String tutoriaId, String uidAlumno, String justificacion, DateTime horaClase) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final horasRestantes = horaClase.difference(DateTime.now()).inHours;
      
      if (horasRestantes < 12) {
        // Advertencia interna (Registro de Strike en el futuro)
        debugPrint("ADVERTENCIA DE STRIKE: El alumno $uidAlumno canceló con menos de 12h de anticipación.");
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final tutoriaRef = FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId);
        final snapshot = await transaction.get(tutoriaRef);
        
        if (!snapshot.exists) throw "Tutoría no encontrada en los registros.";
        final data = snapshot.data()!;
        
        List<dynamic> inscritos = data['listaDeEstudiantesInscritos'] ?? [];
        inscritos.remove(uidAlumno); // Al retirar el ID, sumamos indirectamente un cupo libre a la plataforma.

        transaction.update(tutoriaRef, {
          'listaDeEstudiantesInscritos': inscritos,
        });
      });

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      _mensajeDeErrorDelSistema = 'No se pudo retirar tu cupo de la clase.';
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Permite a un profesor disolver formalmente la clase.
  /// Modifica el estado a 'cancelada'. Abre actas de quejas automáticas ante cancelaciones injustificadas (< 12 horas).
  Future<bool> cancelarClaseTutor(String tutoriaId, String tutorId, String justificacion, DateTime horaClase) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final horasRestantes = horaClase.difference(DateTime.now()).inHours;
      final tutoriaRef = FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId);
      
      await tutoriaRef.update({
        'estadoDeLaSolicitud': 'cancelada',
        'justificacion_cancelacion': justificacion,
      });

      // Lógica de Auditoría Automática
      if (horasRestantes < 12) {
        await FirebaseFirestore.instance.collection('quejas').add({
          'tutorId': tutorId,
          'tutoriaId': tutoriaId,
          'fechaQueja': DateTime.now().toIso8601String(),
          'motivo_sistema': 'Cancelación tardía (Menos de 12h)',
          'justificacion_brindada': justificacion,
        });
      }

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      _mensajeDeErrorDelSistema = 'Hubo un error deteniendo la sesión formalmente.';
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  // /// Escudo lógico de validación algorítmica para inscripciones.
  // /// Evita auto-inscripción cruzada.
  // bool _puedeInscribirse(TutoriaModel tutoria, String uidUsuarioActual) {
  //   if (uidUsuarioActual == tutoria.identificadorDelTutor) {
  //     return false; // Cruce detectado: el maestro es el mismo alumno
  //   }
  //   return true;
  // }

  /// LÓGICA DE NEGOCIO CRÍTICA (Modelo Uber):
  /// Asigna a un tutor una petición "huérfana" elaborada por un estudiante.
  /// Contiene un escudo de Transacción Atómica contra Condición de Carrera.
  Future<bool> aceptarSolicitudSugerida(TutoriaModel modeloDefinitivo) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final uidTutor = FirebaseAuth.instance.currentUser?.uid;
      if (uidTutor == null) throw Exception("Sesión inactiva. Vuelve a ingresar.");

      final docRef = FirebaseFirestore.instance.collection('tutorias').doc(modeloDefinitivo.identificadorDeTutoria);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        
        if (!docSnapshot.exists) {
          throw Exception("La tutoría ya fue eliminada del sistema.");
        }
        
        final data = docSnapshot.data()!;
        final String? tutorAsignado = data['identificadorDelTutor'];
        
        // Bloqueo Anti-Choques Atómico: 
        if (tutorAsignado != null && tutorAsignado.trim().isNotEmpty) {
           throw Exception("Esta tutoría ya fue aceptada por otro tutor.");
        }
        
        // Inyectamos validaciones finales antes de subir
        TutoriaModel modeloAEnviar = modeloDefinitivo.copyWith(
           identificadorDelTutor: uidTutor,
           estadoDeLaSolicitud: 'pendiente', // Permanece pendiente para que los estudiantes se puedan inscribir
           esGrupal: modeloDefinitivo.cupoMaximo > 1,
        );
        
        transaction.update(docRef, modeloAEnviar.toMap());
      });

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;

    } catch (e) {
      _mensajeDeErrorDelSistema = e.toString().contains("Exception: ") ? e.toString().split("Exception: ").last : "Interrupción durante la asignación.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }
  /// Envía la evaluación de una tutoría, previniendo dobles envíos mediante operaciones atómicas 
  /// y almacenando retroalimentación de calidad nativamente dentro del perfil del tutor.
  Future<bool> enviarEvaluacionTutoria(String tutoriaId, String tutorId, double estrellas, String comentario) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final uidAlumno = FirebaseAuth.instance.currentUser?.uid;
      if (uidAlumno == null) throw Exception("Sesión inactiva. Vuelve a ingresar.");

      final db = FirebaseFirestore.instance;
      final docTutoria = db.collection('tutorias').doc(tutoriaId);
      final docTutorEval = db.collection('usuarios').doc(tutorId).collection('evaluaciones').doc();

      // Ejecución paralela cruzada bajo una sola validación de red:
      await db.runTransaction((transaction) async {
        // Transacción 1: Marcar al alumno en la matriz para que el UI deshabilite dinámicamente este evento.
        transaction.update(docTutoria, {
          'alumnosQueYaEvaluaron': FieldValue.arrayUnion([uidAlumno])
        });

        // Transacción 2: Anotamos la evaluación como una micro-pieza atómica en la subcolección del Tutor
        transaction.set(docTutorEval, {
          'estrellas': estrellas,
          'comentario': comentario,
          'fecha': DateTime.now().toIso8601String(),
          'uid_alumno': uidAlumno,
          'tutoria_id': tutoriaId,
        });
      });

      _apagarSenalIndicadoraDeEspera();
      // Delegamos la reactividad 100% al StreamBuilder. No invocamos notifyListeners() extra ni recargamos listas locales manualmente.
      return true;
    } catch (e) {
      _mensajeDeErrorDelSistema = "Fallo en la matriz de red intentando asentar la calificación.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners(); // Se necesita para mostrar el error localmente
      return false;
    }
  }
}

