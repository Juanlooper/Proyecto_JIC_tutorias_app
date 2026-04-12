import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tutoria_model.dart'; // Importación obligatoria del Modelo que creamos anteriormente

/// Servicio especialista en el manejo de Datos y Estadísticas en la Nube.
/// Esta clase orquesta todo el control de tráfico dentro de Firestore asociado a las Clases/Tutorías.
class BaseDeDatosServicio {
  
  /// Instancia pre-configurada apuntando directamente a nuestra gran bodega online (Firebase Firestore).
  final FirebaseFirestore _bodegaDeConocimiento = FirebaseFirestore.instance;

  /// Registra una petición "desde cero" almacenando todo el detalle de la tutoría elaborada en nuestra base de datos.
  /// El bloque 'try' es un escudo anti-cortes de internet, validando que solo retorne "verdadero" si hubo un impacto real en DB.
  Future<bool> crearNuevaTutoria({required TutoriaModel modeloDeLaNuevaClase}) async {
    try {
      // 1. Apuntamos al pasillo "tutorias". Usamos de etiqueta de la carpeta el mismo 'identificadorDeTutoria'.
      // 2. .set() esparcirá el resultado nativo extraído de .toMap() directamente al servidor de la JIC.
      await _bodegaDeConocimiento
          .collection('tutorias')
          .doc(modeloDeLaNuevaClase.identificadorDeTutoria)
          .set(modeloDeLaNuevaClase.toMap());
          
      return true; // Retornal al UI un éxito transparente
    } catch (errorSilencioso) {
      // Control de pérdidas. No "romperá" la app si hay error conectivo o denegación de reglas
      return false; 
    }
  }

  /// Realiza una "lectura eficiente" recuperando SOLO aquellas sesiones vírgenes solicitando profesores.
  /// Es clave hacer el filtro .where('pendiente') en Cloud (lado servidor) para jamás exceder cuotas de descargas en Firebase.
  Future<List<TutoriaModel>> obtenerTutoriasPendientes() async {
    try {
      // La solicitud a Firebase. Retornará únicamente los paquetes alineados con nuestro requerimiento.
      QuerySnapshot lecturaOptimizada = await _bodegaDeConocimiento
          .collection('tutorias')
          .where('estadoDeLaSolicitud', isEqualTo: 'pendiente')
          .get();

      // Transformamos ('map') el montón crudo de registros a una lista formal de nuestro prestigioso modelo
      List<TutoriaModel> listadoResultante = lecturaOptimizada.docs.map((hojaDocumental) {
        var informaciónBruta = hojaDocumental.data() as Map<String, dynamic>?;
        // Aquí pasamos los datos por el colador super-protegido del fromMap que diseñamos antes
        return TutoriaModel.fromMap(informaciónBruta); 
      }).toList();

      return listadoResultante;

    } catch (errorEnFlujoLectura) {
      // Respuesta resiliente: si colapsamos, entregamos lista vacía [] para no asustar al usuario ni romper gráficas de Alejandra.
      return []; 
    }
  }

  /// Añade el nombre/cédula del Estudiante a un registro masivo en clases grandes.
  /// Por órdenes lógicas, usamos arrayUnion: es el método definitivo para apilar datos sin sobreescribir ni re-descargar todo.
  Future<String> unirseATutoria({
    required String identificadorDeTutoriaEspecifica,
    required String identificadorDeUnAlumnoFinal,
  }) async {
    try {
      // Update solo hace "parches".
      // Con FieldValue.arrayUnion estamos diciendo: "añade este Alumno justo al final de la lista existente evitando que se duplique".
      await _bodegaDeConocimiento
          .collection('tutorias')
          .doc(identificadorDeTutoriaEspecifica)
          .update({
             'listaDeEstudiantesInscritos': FieldValue.arrayUnion([identificadorDeUnAlumnoFinal])
          });

      return "Cupo Asegurado: Ya te encuentras en lista";
    } catch (errorDeIntegracion) {
      return "Sucedió un colapso en la nube intentando ingresar tu registro.";
    }
  }

  /// Es el gran comando que pulsa un profesor experto cuando reclama enseñar una de las materias libres.
  /// Transiciona el negocio inyectándole vida: pasamos a 'aceptada', plantamos el nombre del sensei, y su link Zoom.
  Future<String> aceptarTutoria({
    required String identificadorDeTutoriaEspecifica,
    required String maestroHerederoAlMando,
    String? linkOficialParaSesion,
  }) async {
    try {
      // Carga útil ultra-liviana. Preparamos el sobre de correo nada más con lo que es imperioso cambiar por ahorro.
      Map<String, dynamic> parchesLigeros = {
        'estadoDeLaSolicitud': 'aceptada',
        'identificadorDelTutor': maestroHerederoAlMando,
      };

      // Si el Tutor adjuntó un link para conectarse o aula física, inyectalo al parche.
      if (linkOficialParaSesion != null && linkOficialParaSesion.trim().isNotEmpty) {
        parchesLigeros['enlaceOReunion'] = linkOficialParaSesion;
      }

      await _bodegaDeConocimiento
          .collection('tutorias')
          .doc(identificadorDeTutoriaEspecifica)
          .update(parchesLigeros);

      return "¡Extraordinario! Oficialmente serás el tutor de esta sesión.";
    } catch (errorAsignacional) {
      // Fallback seguro si hubo denegaciones de accesos
      return "La nube interrumpió el proceso de tu asignación como tutor actual.";
    }
  }
}
