import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/tutoria_model.dart';
import '../models/usuario_model.dart';

class PdfServicio {
  /// Genera y permite descargar/imprimir un certificado de asistencia.
  static Future<void> generarCertificadoAsistencia({
    required UsuarioModel estudiante,
    required TutoriaModel tutoria,
    required String tutorNombre,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy');
    final fechaString = dateFormat.format(tutoria.fechaHoraSugerida);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue900, width: 4),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'CERTIFICADO DE ASISTENCIA',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'VECTA Tutorías JIC',
                  style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Se certifica que el estudiante',
                  style: const pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  estudiante.nombreCompleto.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Participó satisfactoriamente en la sesión de tutoría:',
                  style: const pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${tutoria.materiaOAsignatura} - ${tutoria.temaEspecifico}',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Impartida por: $tutorNombre',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'Fecha: $fechaString',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'Duración: ${tutoria.duracionMinutos} minutos',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(width: 150, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 5),
                        pw.Text('Firma del Tutor'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 150, height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 5),
                        pw.Text('VECTA Autorización'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'certificado_${tutoria.materiaOAsignatura.replaceAll(" ", "_")}.pdf',
    );
  }
}
