import 'package:flutter/material.dart';
import '../services/evaluacion_servicio.dart';

/// Proveedor de Estado para Evaluaciones y Reputacion.
/// Sirve como el puente que une la logica de auditoria en la nube con las vistas de Alejandra.
class EvaluacionProvider extends ChangeNotifier {
  
  /// El motor capaz de insertar y calcular calificaciones.
  final EvaluacionServicio _servicioDeEvaluacion = EvaluacionServicio();

  /// Mapa privado para la logica de Caché.
  /// Guarda temporalmente en la memoria RAM el historial de promedios para un tutor.
  /// La llave (String) es el ID del tutor y el valor (double) es su ponderacion de estrellas.
  final Map<String, double> _prestigioDeTutores = {};

  /// Booleano que usa Alejandra para saber cuando bloquear botones y evitar
  /// que pulsen repetidas veces un boton de enviar reporte.
  bool _estaCargando = false;

  bool get estaCargando => _estaCargando;

  /// Problema de negocio que resuelve: Evita sobrecargar el internet repitiendo la misma
  /// consulta a Firebase cada vez que se redibuje una pantalla para el mismo tutor. Permite 
  /// mostrar la calificacion instantaneamente gracias al cache de memoria.
  Future<double> obtenerCalificacionTutor(String idTutor) async {
    // Retornar de la memoria rapida (Maiky Cache) si ya la calculamos
    if (_prestigioDeTutores.containsKey(idTutor)) {
      return _prestigioDeTutores[idTutor]!;
    }
    
    // Si no esta en cache, mandamos la senal de carga y nos dirigimos a los servidores
    _estaCargando = true;
    notifyListeners();

    double promedioCalculado = await _servicioDeEvaluacion.obtenerPromedioDeTutor(
      identificadorEspecificoDelTutor: idTutor
    );

    // Guardamos la ponderacion obtenida en nuestra estructura de cache
    _prestigioDeTutores[idTutor] = promedioCalculado;
    
    _estaCargando = false;
    notifyListeners();

    return promedioCalculado;
  }

  /// Problema de negocio que resuelve: Empaqueta la solicitud de queja critica 
  /// controlando el indicador de carga para que la aplicacion asimile estados
  /// de "Enviando..." y no sature la plataforma.
  Future<String> enviarReporteCritico(String identificadorDelUsuarioAfectado, String descripcionCriticaDelProblema) async {
    _estaCargando = true;
    notifyListeners();

    String respuestaDescriptiva = await _servicioDeEvaluacion.reportarIncidenteOQueja(
      identificadorDelUsuarioAfectado: identificadorDelUsuarioAfectado,
      descripcionCriticaDelProblema: descripcionCriticaDelProblema,
    );

    _estaCargando = false;
    notifyListeners();

    return respuestaDescriptiva;
  }
}
