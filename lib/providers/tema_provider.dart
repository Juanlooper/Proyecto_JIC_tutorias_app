import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proveedor del Estado Visual de la Aplicación.
/// Se encarga de alternar entre modo claro y oscuro, y guardar la preferencia
/// en el almacenamiento local del dispositivo.
class TemaProvider extends ChangeNotifier {
  bool _esModoOscuro = false;

  /// Llave utilizada para almacenar el dato en SharedPreferences
  final String _llavePreferenciaTema = 'preferencia_modo_oscuro';

  bool get esModoOscuro => _esModoOscuro;

  TemaProvider() {
    _cargarPreferenciaDeTema();
  }

  /// Alterna el estado actual del tema y lo guarda en memoria.
  Future<void> alternarTema(bool valorEntrante) async {
    _esModoOscuro = valorEntrante;
    notifyListeners();

    final almacenamientoLocal = await SharedPreferences.getInstance();
    await almacenamientoLocal.setBool(_llavePreferenciaTema, _esModoOscuro);
  }

  /// Busca en el disco duro del teléfono si el usuario ya había elegido un tema antes.
  Future<void> _cargarPreferenciaDeTema() async {
    final almacenamientoLocal = await SharedPreferences.getInstance();
    _esModoOscuro = almacenamientoLocal.getBool(_llavePreferenciaTema) ?? false;
    notifyListeners();
  }
}
