// ignore_for_file: empty_catches
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tutoria_model.dart';
import '../services/base_de_datos_servicio.dart';
import '../services/firebase_storage_servicio.dart';

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
  final List<String> _idsOcultosPorTutor = [];

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
        fecha_creacion_solicitud: DateTime.now(), // SLA Timestamp
      );

      Map<String, dynamic> datosNube = solicitudProcesada.toMap();
      datosNube['creador'] = uidEstudiante; // Guardar trazabilidad explícita del estudiante (creador original)

      // 2. Transmitir el documento a la colección en Firebase
      await collectionRef.doc(docId).set(datosNube);

      // Notificar a TODOS los tutores registrados que hay una nueva sugerencia en la bolsa
      final tutoresSnapshot = await FirebaseFirestore.instance.collection('usuarios')
          .where('rolEnElSistema', isEqualTo: 'tutor').get();
      final uidsTutores = tutoresSnapshot.docs.map((d) => d.id).toList();
      await _notificarMultiples(
        uids: uidsTutores,
        titulo: 'Nueva Sugerencia en la Bolsa 📋',
        mensaje: 'Un estudiante ha sugerido una clase de ${sugerencia.materiaOAsignatura}. ¡Revisa la bolsa de solicitudes!',
        tipo: 'info',
      );

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) { debugPrint(e.toString());
      _mensajeDeErrorDelSistema = e.toString().contains("Exception: ") ? e.toString().split("Exception: ").last : "Error al procesar la solicitud huérfana en la nube.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Sistema de "Sugerencia Directa".
  /// Permite al estudiante sugerir una tutoría directamente a un tutor específico.
  Future<bool> crearSugerenciaDirecta(TutoriaModel sugerencia, String idTutor) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final uidEstudiante = FirebaseAuth.instance.currentUser?.uid;
      if (uidEstudiante == null) {
        throw Exception("Sesión inactiva. Vuelve a ingresar para solicitar una clase.");
      }

      List<String> apoyadoresIniciales = [uidEstudiante];
      final collectionRef = FirebaseFirestore.instance.collection('tutorias');
      String docId = sugerencia.identificadorDeTutoria.isEmpty 
          ? collectionRef.doc().id 
          : sugerencia.identificadorDeTutoria;

      TutoriaModel solicitudProcesada = sugerencia.copyWith(
        identificadorDeTutoria: docId,
        identificadorDelTutor: idTutor, // Tutor asignado
        estadoDeLaSolicitud: 'sugerida_directa', // Nuevo estado
        listaDeEstudiantesInscritos: [], 
        estudiantesApoyando: apoyadoresIniciales,
        fecha_creacion_solicitud: DateTime.now(),
      );

      Map<String, dynamic> datosNube = solicitudProcesada.toMap();
      datosNube['creador'] = uidEstudiante;

      await collectionRef.doc(docId).set(datosNube);

      // Notificar SOLO al tutor asignado
      await _crearNotificacion(
        usuarioId: idTutor,
        titulo: 'Nueva Sugerencia Directa 🎯',
        mensaje: 'Un estudiante te ha sugerido directamente dar una clase de ${sugerencia.materiaOAsignatura}.',
        tipo: 'info',
      );

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) { 
      debugPrint(e.toString());
      _mensajeDeErrorDelSistema = "Error al procesar la sugerencia directa.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Permite al tutor rechazar una sugerencia directa.
  Future<bool> rechazarSugerenciaDirecta(String idTutoria, String razon) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final docRef = FirebaseFirestore.instance.collection('tutorias').doc(idTutoria);
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) throw Exception("Tutoría no encontrada.");
      final data = docSnapshot.data()!;

      await docRef.update({
        'estadoDeLaSolicitud': 'rechazada_directa',
        'justificacion_cancelacion': razon,
      });

      final creador = data['creador'] ?? '';
      if (creador.isNotEmpty) {
        await _crearNotificacion(
          usuarioId: creador,
          titulo: 'Sugerencia Rechazada ❌',
          mensaje: 'El tutor no pudo aceptar tu sugerencia de ${data['materiaOAsignatura']}. Motivo: $razon',
          tipo: 'alerta_amarilla',
        );
      }

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      _mensajeDeErrorDelSistema = "Error al rechazar la sugerencia.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Permite al tutor aceptar una sugerencia directa.
  Future<bool> aceptarSugerenciaDirecta(String idTutoria) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final docRef = FirebaseFirestore.instance.collection('tutorias').doc(idTutoria);
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) throw Exception("Tutoría no encontrada.");
      
      final data = docSnapshot.data()!;
      // Si la tutoría era grupal y tiene cupo > 1, el estado es abierta. Sino, aceptada.
      String nuevoEstado = 'aceptada';
      int cupoMaximo = data['cupoMaximo'] ?? 1;
      bool esGrupal = data['esGrupal'] ?? false;
      if (esGrupal && cupoMaximo > 1) {
        nuevoEstado = 'abierta';
      }

      await docRef.update({
        'estadoDeLaSolicitud': nuevoEstado,
        'fecha_aceptacion_solicitud': DateTime.now(),
      });

      final creador = data['creador'] ?? '';
      if (creador.isNotEmpty) {
        await _crearNotificacion(
          usuarioId: creador,
          titulo: '¡Sugerencia Aceptada! 🎉',
          mensaje: 'El tutor ha aceptado tu sugerencia de ${data['materiaOAsignatura']}.',
          tipo: 'info',
        );
      }

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      _mensajeDeErrorDelSistema = "Error al aceptar la sugerencia.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }
  
  /// Permite convertir una sugerencia rechazada a la bolsa pública.
  Future<bool> republicarSugerenciaEnBolsa(String idTutoria) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final docRef = FirebaseFirestore.instance.collection('tutorias').doc(idTutoria);
      
      await docRef.update({
        'estadoDeLaSolicitud': 'solicitada',
        'identificadorDelTutor': '', // Lo liberamos
        'justificacion_cancelacion': null, // Borramos justificación
      });

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      _mensajeDeErrorDelSistema = "Error al republicar.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Permite a un tutor crear y publicar su propia clase.
  Future<bool> tutorCreaClase(TutoriaModel claseNueva) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final uidTutor = FirebaseAuth.instance.currentUser?.uid;
      if (uidTutor == null) throw Exception("Sesión inactiva.");

      final collectionRef = FirebaseFirestore.instance.collection('tutorias');
      String docId = claseNueva.identificadorDeTutoria.isEmpty 
          ? collectionRef.doc().id 
          : claseNueva.identificadorDeTutoria;

      TutoriaModel claseProcesada = claseNueva.copyWith(
        identificadorDeTutoria: docId,
        identificadorDelTutor: uidTutor,
        estadoDeLaSolicitud: 'aceptada', // Ya nace aceptada por el propio tutor
        fecha_aceptacion_solicitud: DateTime.now(),
        fecha_creacion_solicitud: DateTime.now(),
      );

      await collectionRef.doc(docId).set(claseProcesada.toMap());

      await cargarListadoDeTutoriasPendientes();
      await cargarTutoriasSuscritasDelUsuario(uidTutor);
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      _mensajeDeErrorDelSistema = "Error al crear tu clase.";
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
    } catch (e) { debugPrint(e.toString());
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
    } catch (e) { debugPrint(e.toString());
      _mensajeDeErrorDelSistema = "Tuvimos un problema al intentar sumarte a esta tutoría comunitaria.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Permite a un estudiante darse de baja (retirar su apoyo/inscripción) de una tutoría, de manera rápida y eficiente sin mutar arrays locales manualmente.
  Future<bool> abandonarTutoria(String tutoriaId, {String? excusa}) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final uidUsuarioActual = FirebaseAuth.instance.currentUser?.uid;
      if (uidUsuarioActual == null) throw Exception("Debes iniciar sesión para realizar esta acción.");

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

      // Si hay una excusa por cancelación tardía, la reportamos al tribunal
      if (excusa != null && excusa.trim().isNotEmpty) {
        await FirebaseFirestore.instance.collection('reportes_tribunal').add({
          'alumnoId': uidUsuarioActual,
          'tutoriaId': tutoriaId,
          'materia': data['materiaOAsignatura'] ?? 'Desconocida',
          'fechaTutoria': data['fechaHoraSugerida'] ?? '',
          'excusa': excusa.trim(),
          'fechaReporte': DateTime.now().toIso8601String(),
          'estado': 'pendiente', // pendiente, perdonado, penalizado
        });

        // Notificar a los administradores sobre el nuevo caso en el tribunal
        await notificarAdministradores(
          'Nueva Excusa en Tribunal ⚖️',
          'Un estudiante canceló tardíamente la clase de ${data['materiaOAsignatura'] ?? 'una materia'} y ha enviado una justificación.',
        );
      }

      // Notificar al tutor que un estudiante abandonó
      final tutorId = data['identificadorDelTutor'] ?? '';
      final materia = data['materiaOAsignatura'] ?? 'una clase';
      if (tutorId.isNotEmpty) {
        await _crearNotificacion(
          usuarioId: tutorId,
          titulo: 'Estudiante se retiró 🚪',
          mensaje: 'Un estudiante ha abandonado tu clase de $materia.',
          tipo: 'alerta_amarilla',
        );
      }

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) { debugPrint(e.toString());
      _mensajeDeErrorDelSistema = "Hubo un error al intentar retirarte de la tutoría.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }


  /// Permite al tutor cancelar la tutoría (ya sea por fuerza mayor u otro motivo).
  /// Esto marca el estado de la solicitud como 'cancelada'.
  Future<bool> cancelarTutoriaComoTutor(String tutoriaId, String motivoCancelacion) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final uidUsuarioActual = FirebaseAuth.instance.currentUser?.uid;
      if (uidUsuarioActual == null) throw Exception("Debes iniciar sesión.");

      // Obtenemos la tutoría para saber quiénes están inscritos
      final docSnapshot = await FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId).get();
      if (!docSnapshot.exists) throw Exception("Tutoría no encontrada.");
      final data = docSnapshot.data()!;

      await FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId).update({
        'estadoDeLaSolicitud': 'cancelada',
        'motivoDeCancelacion': motivoCancelacion,
      });

      // Reportarlo silenciosamente a quejas como cancelación de tutor para trackeo del admin
      await FirebaseFirestore.instance.collection('quejas').add({
        'tutorId': uidUsuarioActual,
        'tutoriaId': tutoriaId,
        'fechaRegistro': DateTime.now().toIso8601String(),
        'justificacion': motivoCancelacion,
      });

      // Crear notificaciones para los estudiantes afectados
      final Set<String> afectados = {};
      final List<dynamic> inscritos = data['listaDeEstudiantesInscritos'] ?? [];
      final List<dynamic> apoyando = data['estudiantesApoyando'] ?? [];
      
      for (var uid in inscritos) { afectados.add(uid.toString()); }
      for (var uid in apoyando) { afectados.add(uid.toString()); }

      final nombreMateria = data['materiaOAsignatura'] ?? 'Una clase';
      final fechaDeCancelacion = DateTime.now().toIso8601String();

      for (var uidAlumno in afectados) {
        await FirebaseFirestore.instance.collection('notificaciones').add({
          'usuarioId': uidAlumno,
          'titulo': 'Tutoría Cancelada',
          'mensaje': 'El tutor ha cancelado la clase de $nombreMateria. Motivo: $motivoCancelacion',
          'fecha': fechaDeCancelacion,
          'leida': false,
          'tipo': 'alerta_roja',
        });
      }

      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      _mensajeDeErrorDelSistema = "Hubo un error al intentar cancelar la tutoría.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Implementación transaccional para inscribirse en tutorías, añadiendo los motivos, links y nombres de archivos.
  Future<bool> inscribirseEnTutoria(String tutoriaId, String uid, String textoMotivo, List<String> listaLinks, List<String> listaNombres) async {
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

        Map<String, dynamic> nombresAdjuntos = data['nombres_adjuntos'] ?? {};
        nombresAdjuntos[uid] = listaNombres;

        transaction.update(docRef, {
          'listaDeEstudiantesInscritos': inscritos,
          'motivos_alumnos': motivos,
          'enlaces_adjuntos': enlaces,
          'nombres_adjuntos': nombresAdjuntos,
        });
      });

      // Notificar al tutor que un estudiante se inscribió
      final tutoriaDoc = await docRef.get();
      if (tutoriaDoc.exists) {
        final tutoriaData = tutoriaDoc.data()!;
        final tutorId = tutoriaData['identificadorDelTutor'] ?? '';
        final materia = tutoriaData['materiaOAsignatura'] ?? 'una clase';
        final inscritosActuales = (tutoriaData['listaDeEstudiantesInscritos'] as List?)?.length ?? 0;
        final cupoMax = tutoriaData['cupoMaximo'] ?? 1;
        if (tutorId.isNotEmpty) {
          await _crearNotificacion(
            usuarioId: tutorId,
            titulo: 'Nuevo Estudiante Inscrito 📝',
            mensaje: 'Un estudiante se ha inscrito en tu clase de $materia ($inscritosActuales/$cupoMax cupos).',
            tipo: 'info',
          );
        }
        // Si el cupo está lleno, notificar a los que estaban apoyando
        if (inscritosActuales >= cupoMax) {
          final apoyando = List<String>.from(tutoriaData['estudiantesApoyando'] ?? []);
          await _notificarMultiples(
            uids: apoyando,
            titulo: 'Cupo Lleno ⚠️',
            mensaje: 'La clase de $materia ha alcanzado su cupo máximo.',
            tipo: 'alerta_amarilla',
          );
        }
      }

      await cargarListadoDeTutoriasPendientes();
      return true;
    } catch (e) { debugPrint(e.toString());
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
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) await cargarTutoriasSuscritasDelUsuario(uid);
        _apagarSenalIndicadoraDeEspera();
        notifyListeners();
        return true;
      } else {
        _mensajeDeErrorDelSistema = resolucionDeLaPeticion;
      }
    } catch (e) { debugPrint(e.toString());
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
    } catch (e) { debugPrint(e.toString());
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

  /// Helper interno para crear notificaciones in-app (campanita).
  Future<void> _crearNotificacion({
    required String usuarioId,
    required String titulo,
    required String mensaje,
    String tipo = 'info',
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notificaciones').add({
        'usuarioId': usuarioId,
        'titulo': titulo,
        'mensaje': mensaje,
        'fecha': DateTime.now().toIso8601String(),
        'leida': false,
        'tipo': tipo,
      });
    } catch (_) {}
  }

  /// Envía notificación a múltiples usuarios a la vez.
  Future<void> _notificarMultiples({
    required List<String> uids,
    required String titulo,
    required String mensaje,
    String tipo = 'info',
  }) async {
    for (var uid in uids) {
      await _crearNotificacion(usuarioId: uid, titulo: titulo, mensaje: mensaje, tipo: tipo);
    }
  }

  /// Método combinado: Toma de Asistencia y Expediente Clínico Académico (Módulo 3).
  /// Penaliza a los alumnos faltistas y añade feedback formativo a los que sí asistieron.
  Future<bool> registrarAsistenciaClase(String tutoriaId, Map<String, Map<String, dynamic>> asistenciasYFeedback) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      // 1. Borrar archivos físicos de Storage para optimizar espacio
      final docActual = await FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId).get();
      if (docActual.exists) {
        final data = docActual.data()!;
        final enlacesMap = data['enlaces_adjuntos'] as Map<String, dynamic>?;
        if (enlacesMap != null) {
          final storageSvc = FirebaseStorageServicio();
          for (var enlacesDeAlumno in enlacesMap.values) {
            for (var urlArchivo in enlacesDeAlumno) {
              await storageSvc.eliminarArchivoFisico(urlArchivo.toString());
            }
          }
        }
      }

      final tutorId = FirebaseAuth.instance.currentUser?.uid;

      // Extraer solo la asistencia en un mapa plano para guardarlo en la tutoría (Retrocompatibilidad UI)
      Map<String, bool> asistenciaPlana = {};
      for (var entry in asistenciasYFeedback.entries) {
        asistenciaPlana[entry.key] = entry.value['asistio'] as bool? ?? false;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final tutoriaRef = FirebaseFirestore.instance.collection('tutorias').doc(tutoriaId);
        
        transaction.update(tutoriaRef, {
          'registro_asistencia': asistenciaPlana,
          'estadoDeLaSolicitud': 'finalizada',
        });

        // Iteramos alumnos: penalizamos inasistencias o agregamos receta médica académica
        for (var entry in asistenciasYFeedback.entries) {
          final uidAlumno = entry.key;
          final asistio = entry.value['asistio'] as bool? ?? false;
          final feedback = entry.value['feedback'] as String? ?? '';
          
          final usuarioRef = FirebaseFirestore.instance.collection('usuarios').doc(uidAlumno);
          
          if (!asistio) {
            final usuarioSnapshot = await transaction.get(usuarioRef);
            if (usuarioSnapshot.exists) {
              final datosUsuario = usuarioSnapshot.data()!;
              final strikesActuales = datosUsuario['strikes_inasistencia'] ?? 0;
              final nuevosStrikes = strikesActuales + 1;
              
              Map<String, dynamic> actualizacion = {
                'strikes_inasistencia': nuevosStrikes,
              };
              
              if (nuevosStrikes >= 3) actualizacion['esta_baneado'] = true;
              
              transaction.update(usuarioRef, actualizacion);
            }
          } else if (feedback.isNotEmpty) {
            // Guardar en el Expediente Clínico Académico del alumno
            final expedienteRef = usuarioRef.collection('expediente_academico').doc();
            transaction.set(expedienteRef, {
              'tutoria_id': tutoriaId,
              'tutor_id': tutorId,
              'fecha': DateTime.now().toIso8601String(),
              'receta_academica': feedback,
            });
          }
        }
      });

      // Notificar a los administradores sobre los strikes
      final uidsPenalizados = asistenciaPlana.entries.where((e) => !e.value).map((e) => e.key).toList();
      if (uidsPenalizados.isNotEmpty) {
        final adminsSnapshot = await FirebaseFirestore.instance.collection('usuarios').where('rolEnElSistema', isEqualTo: 'admin').get();
        final adminUids = adminsSnapshot.docs.map((e) => e.id).toList();
        for (var alumnoUid in uidsPenalizados) {
          await _notificarMultiples(
            uids: adminUids,
            titulo: 'Alerta Administrativa: Strike',
            mensaje: 'El alumno $alumnoUid recibió un strike por inasistencia en tutoría de id: $tutoriaId.',
            tipo: 'alerta_roja',
          );
        }
      }
      
      // Notificar a los alumnos asistentes que recibieron feedback clínico
      final uidsAsistentesConFeedback = asistenciasYFeedback.entries
          .where((e) => (e.value['asistio'] == true) && (e.value['feedback'] != null && e.value['feedback'].toString().isNotEmpty))
          .map((e) => e.key).toList();
          
      if (uidsAsistentesConFeedback.isNotEmpty) {
        await _notificarMultiples(
          uids: uidsAsistentesConFeedback,
          titulo: 'Nuevo Reporte Académico 📋',
          mensaje: 'Tu tutor ha dejado recomendaciones personalizadas para tu estudio. Revísalo en tu expediente.',
          tipo: 'info',
        );
      }

      // Refrescar y avisar exito
      await cargarListadoDeTutoriasPendientes();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) await cargarTutoriasSuscritasDelUsuario(uid);
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) { debugPrint(e.toString());
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
      if (FirebaseAuth.instance.currentUser != null) {
        await cargarTutoriasSuscritasDelUsuario(FirebaseAuth.instance.currentUser!.uid);
      }
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) { debugPrint(e.toString());
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
      
      // 1. Borrar archivos físicos de Storage
      final docActual = await tutoriaRef.get();
      if (docActual.exists) {
        final data = docActual.data()!;
        final enlacesMap = data['enlaces_adjuntos'] as Map<String, dynamic>?;
        if (enlacesMap != null) {
          final storageSvc = FirebaseStorageServicio();
          for (var enlacesDeAlumno in enlacesMap.values) {
            for (var urlArchivo in enlacesDeAlumno) {
              await storageSvc.eliminarArchivoFisico(urlArchivo.toString());
            }
          }
        }
      }

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

      // Notificar a los estudiantes inscritos que la clase fue cancelada
      if (docActual.exists) {
        final tutoriaData = docActual.data()!;
        final inscritosNotif = List<String>.from(tutoriaData['listaDeEstudiantesInscritos'] ?? []);
        final materiaNotif = tutoriaData['materiaOAsignatura'] ?? 'una clase';
        await _notificarMultiples(
          uids: inscritosNotif,
          titulo: 'Tutoría Cancelada ❌',
          mensaje: 'El tutor canceló la clase de $materiaNotif. Motivo: $justificacion',
          tipo: 'alerta_roja',
        );
      }

      await cargarListadoDeTutoriasPendientes();
      if (FirebaseAuth.instance.currentUser != null) {
        await cargarTutoriasSuscritasDelUsuario(FirebaseAuth.instance.currentUser!.uid);
      }
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) { debugPrint(e.toString());
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
           esGrupal: true,
           cupoMaximo: 10,
           fecha_aceptacion_solicitud: DateTime.now(), // SLA Timestamp
        );
        
        transaction.update(docRef, modeloAEnviar.toMap());
      });

      // Notificar a los estudiantes que apoyaron la sugerencia: ¡un tutor la aceptó!
      final docActualizado = await docRef.get();
      if (docActualizado.exists) {
        final dataActualizada = docActualizado.data()!;
        final apoyando = List<String>.from(dataActualizada['estudiantesApoyando'] ?? []);
        final materia = dataActualizada['materiaOAsignatura'] ?? 'una clase';
        await _notificarMultiples(
          uids: apoyando,
          titulo: '¡Tu sugerencia fue aceptada! 🎉',
          mensaje: 'Un tutor ha aceptado impartir la clase de $materia. Inscríbete oficialmente desde la Cartelera para reservar tu cupo.',
          tipo: 'alerta_verde',
        );
      }

      await cargarListadoDeTutoriasPendientes();
      await cargarTutoriasSuscritasDelUsuario(uidTutor);
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;

    } catch (e) { debugPrint(e.toString());
      _mensajeDeErrorDelSistema = e.toString().contains("Exception: ") ? e.toString().split("Exception: ").last : "Interrupción durante la asignación.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }
  bool _contienePalabrasProhibidas(String texto) {
    if (texto.isEmpty) return false;
    final prohibidas = [
      'mierda', 'estupido', 'estúpido', 'idiota', 'imbecil', 'imbécil', 
      'puta', 'puto', 'cabron', 'cabrón', 'pendejo', 'pendeja', 'verga',
      'zorra', 'maricon', 'maricón', 'maldito', 'maldita'
    ];
    final textoNormalizado = texto.toLowerCase();
    for (var palabra in prohibidas) {
      // Usamos regex simple para evitar falsos positivos si la palabra está dentro de otra?
      // Por simplicidad, un contains() bastará para este prototipo.
      if (textoNormalizado.contains(palabra)) {
        return true;
      }
    }
    return false;
  }

  /// Envía la evaluación de una tutoría, previniendo dobles envíos mediante operaciones atómicas 
  /// y almacenando retroalimentación de calidad nativamente dentro del perfil del tutor.
  Future<bool> enviarEvaluacionTutoria(
      String tutoriaId, 
      String tutorId, 
      double puntualidad, 
      double dominio, 
      double empatia, 
      List<String> etiquetas, 
      String comentarioPrivado,
      String comentarioPublico) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      if (_contienePalabrasProhibidas(comentarioPublico)) {
        throw Exception("El comentario público contiene palabras no permitidas. Mantén el respeto en la comunidad.");
      }

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
        // Guardamos promedio como compatibilidad para la UI antigua si hay partes que aún lo usan.
        double promedio = (puntualidad + dominio + empatia) / 3;
        
        transaction.set(docTutorEval, {
          'estrellas': promedio, // Retrocompatibilidad
          'dim_puntualidad': puntualidad,
          'dim_dominio': dominio,
          'dim_empatia': empatia,
          'etiquetas': etiquetas,
          'comentario_admin': comentarioPrivado,
          'comentario_publico': comentarioPublico,
          'fecha': DateTime.now().toIso8601String(),
          'uid_alumno': uidAlumno,
          'tutoria_id': tutoriaId,
        });
      });

      // Notificar al tutor que recibió una nueva evaluación (sin revelar el comentario privado)
      double promedioMostrar = (puntualidad + dominio + empatia) / 3;
      await _crearNotificacion(
        usuarioId: tutorId,
        titulo: 'Nueva Evaluación Recibida ⭐',
        mensaje: 'Un estudiante te ha evaluado. Promedio: ${promedioMostrar.toStringAsFixed(1)} estrellas.',
        tipo: 'info',
      );

      // Notificar a los administradores sobre la reseña
      final adminsSnapshot = await db.collection('usuarios').where('rolEnElSistema', isEqualTo: 'admin').get();
      final adminUids = adminsSnapshot.docs.map((e) => e.id).toList();
      await _notificarMultiples(
        uids: adminUids,
        titulo: 'Alerta Administrativa: Nueva Reseña',
        mensaje: 'Tutor: $tutorId | Calificación: ${promedioMostrar.toStringAsFixed(1)} | Comentario Privado: ${comentarioPrivado.isEmpty ? "N/A" : comentarioPrivado}',
        tipo: promedioMostrar <= 2.5 ? 'alerta_roja' : 'info',
      );

      _apagarSenalIndicadoraDeEspera();
      // Delegamos la reactividad 100% al StreamBuilder. No invocamos notifyListeners() extra ni recargamos listas locales manualmente.
      return true;
    } catch (e) { debugPrint(e.toString());
      _mensajeDeErrorDelSistema = "Fallo en la matriz de red intentando asentar la calificación: ${e.toString()}";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners(); // Se necesita para mostrar el error localmente
      return false;
    }
  }

  /// Elimina un comentario público de una evaluación por considerarse inapropiado (Solo Admin)
  Future<bool> eliminarComentarioPublico(String tutorId, String evaluacionId) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(tutorId)
          .collection('evaluaciones')
          .doc(evaluacionId)
          .update({'comentario_publico': '[Eliminado por Moderación]'});
          
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      _mensajeDeErrorDelSistema = "No se pudo eliminar el comentario.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Permite al tutor evaluar a un estudiante. (Uso interno/administrativo).
  Future<bool> enviarEvaluacionEstudiante(String tutoriaId, String estudianteId, double estrellas, String comentario) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();

    try {
      final uidTutor = FirebaseAuth.instance.currentUser?.uid;
      if (uidTutor == null) throw Exception("Sesión inactiva. Vuelve a ingresar.");

      final db = FirebaseFirestore.instance;
      final docTutoria = db.collection('tutorias').doc(tutoriaId);
      final docEval = db.collection('evaluaciones_estudiantes').doc();

      await db.runTransaction((transaction) async {
        transaction.update(docTutoria, {
          'alumnosEvaluadosPorTutor': FieldValue.arrayUnion([estudianteId])
        });

        transaction.set(docEval, {
          'tutorId': uidTutor,
          'estudianteId': estudianteId,
          'tutoriaId': tutoriaId,
          'estrellas': estrellas,
          'comentario': comentario,
          'fecha': DateTime.now().toIso8601String(),
        });
      });

      // Notificar a los administradores para seguimiento
      await notificarAdministradores(
        'Evaluación a Estudiante',
        'Tutor calificó al alumno $estudianteId con ${estrellas.toStringAsFixed(0)} estrellas. ${comentario.isNotEmpty ? 'Comentario: $comentario' : ''}',
        tipo: estrellas <= 2 ? 'alerta_roja' : 'info',
      );

      _apagarSenalIndicadoraDeEspera();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      _mensajeDeErrorDelSistema = "Error al enviar la evaluación del estudiante.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Permite a un tutor crear una clase fija propia, desde cero.
  Future<bool> crearClaseFijaTutor(TutoriaModel claseFija) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();
    try {
      final collectionRef = FirebaseFirestore.instance.collection('tutorias');
      String docId = collectionRef.doc().id;
      TutoriaModel aGuardar = claseFija.copyWith(
        identificadorDeTutoria: docId,
        estadoDeLaSolicitud: 'pendiente',
        cupoMaximo: claseFija.cupoMaximo < 10 ? 10 : claseFija.cupoMaximo,
      );
      await collectionRef.doc(docId).set(aGuardar.toMap());
      await cargarListadoDeTutoriasPendientes();
      final uidTutor = FirebaseAuth.instance.currentUser?.uid;
      if (uidTutor != null) {
        await cargarTutoriasSuscritasDelUsuario(uidTutor);
      }
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch (e) { debugPrint(e.toString());
      _mensajeDeErrorDelSistema = "Error al crear la clase fija.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }

  /// Permite a un tutor editar el cupo máximo de una clase existente.
  Future<bool> editarCupoMaximo(String idTutoria, int nuevoCupoMaximo) async {
    _iluminarSenalIndicadoraDeEspera();
    _purgarCasillasDeAdvertencias();
    try {
      if (nuevoCupoMaximo < 1) throw "El cupo no puede ser menor a 1.";
      await FirebaseFirestore.instance.collection('tutorias').doc(idTutoria).update({
         'cupoMaximo': nuevoCupoMaximo,
      });
      final uidTutor = FirebaseAuth.instance.currentUser?.uid;
      if (uidTutor != null) {
        await cargarTutoriasSuscritasDelUsuario(uidTutor);
      }
      await cargarListadoDeTutoriasPendientes();
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return true;
    } catch(e) {
      _mensajeDeErrorDelSistema = "Error editando cupo.";
      _apagarSenalIndicadoraDeEspera();
      notifyListeners();
      return false;
    }
  }
  /// Envía una notificación a todos los administradores del sistema.
  Future<void> notificarAdministradores(String titulo, String mensaje, {String tipo = 'alerta_admin'}) async {
    try {
      final adminsSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rolEnElSistema', isEqualTo: 'admin')
          .get();

      final fechaIso = DateTime.now().toIso8601String();
      for (var doc in adminsSnapshot.docs) {
        await FirebaseFirestore.instance.collection('notificaciones').add({
          'usuarioId': doc.id,
          'titulo': titulo,
          'mensaje': mensaje,
          'fecha': fechaIso,
          'leida': false,
          'tipo': tipo,
        });
      }
    } catch (e) {
      debugPrint('Error al notificar administradores: $e');
    }
  }
}
