import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Central de Metricas Globales para uso del rol de Administracion JIC.
/// Conecta a Alejandra (UX) con los numeros crudos para dibujar el Dashboard de desempeño.
class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _baseDeDatosOperativa = FirebaseFirestore.instance;

  /// Le confirma a Alejandra que no pinte numeros a cero, sino que muestre una animacion 
  /// de carga porque hay consultas en progreso.
  bool _estaCargando = false;

  bool get estaCargando => _estaCargando;

  // Repositorios numericos de Estado local.
  int totalAlumnos = 0;
  int totalTutorias = 0;
  int totalQuejas = 0;

  /// Lógica Pro para el cargado rapido de información pesada.
  /// 
  /// Documentación para Maiky (Optimización y DevOps): Descargar millones de expedientes 
  /// usando ".get()" normal agotaría la cuota comercial del mes causando caídas en Firebase.
  /// Utilizar el poderoso ".count().get()" ahorra dinero en la factura ya que Firebase no descarga 
  /// cada documento gigabyte por gigabyte, sino que desde su servidor matriz cuenta las llaves
  /// indexadas y devuelve un único peso byte diminuto.
  Future<void> cargarEstadisticasGlobales() async {
    _estaCargando = true;
    notifyListeners();

    try {
      // Metrica 1: Alumnado incrito operante
      AggregateQuerySnapshot conteoNativoGente = await _baseDeDatosOperativa.collection('usuarios').count().get();
      int conteoAlumnos = conteoNativoGente.count ?? 0;

      // Metrica 2: Tutorias totales que han circulado (Pendientes, activas o canceladas)
      AggregateQuerySnapshot conteoNativoClases = await _baseDeDatosOperativa.collection('tutorias').count().get();
      int conteoAcumuladoTutorias = conteoNativoClases.count ?? 0;

      // Metrica 3: Buzon Critico (Para enviar notificaciones de alerta humanitarias)
      AggregateQuerySnapshot conteoNativoReportes = await _baseDeDatosOperativa.collection('quejas').count().get();
      int conteoQuejas = conteoNativoReportes.count ?? 0;

      // Solidificamos informacion bajada y enviamos inyeccion a Alejandra
      totalAlumnos = conteoAlumnos;
      totalTutorias = conteoAcumuladoTutorias;
      totalQuejas = conteoQuejas;

    } catch (e) {
      // Ante caida abrupta de red, sostenemos variables graficas en memoria (no bajan a cero, por logica)
    }

    _estaCargando = false;
    notifyListeners();
  }
}
