import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import '../providers/admin_provider.dart';

class ExportacionExcelServicio {
  static Future<void> exportarDatosGlobales(AdminProvider admin) async {
    try {
      List<List<dynamic>> rows = [];

      // Cabeceras
      rows.add([
        'Nombre',
        'Facultad',
        'Carrera',
        'Año Cursando',
        'Horas Totales',
      ]);

      // Datos
      for (var e in admin.todosLosEstudiantesConHoras) {
        rows.add([
          e['nombre'] ?? 'Desconocido',
          e['facultad'] ?? 'No especificada',
          e['carrera'] ?? 'No especificada',
          e['anoCursando'] ?? 'N/A',
          double.tryParse(e['horas'].toString()) ?? 0.0,
        ]);
      }

      String csvData = rows
          .map((row) {
            return row
                .map((field) {
                  String val = field.toString().replaceAll('"', '""');
                  return '"$val"';
                })
                .join(',');
          })
          .join('\n');

      // BOM para que Excel (en español/inglés) lo lea correctamente como UTF-8
      List<int> bytes = [0xEF, 0xBB, 0xBF];
      bytes.addAll(utf8.encode(csvData));

      String filename =
          'Demografia_Estudiantil_${DateTime.now().millisecondsSinceEpoch}';

      await FileSaver.instance.saveFile(
        name: filename,
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
    } catch (e) {
      debugPrint('Error exportando CSV: $e');
      rethrow;
    }
  }
}
