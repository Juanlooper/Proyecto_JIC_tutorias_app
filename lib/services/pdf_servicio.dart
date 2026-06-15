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
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    final dateFormat = DateFormat('dd/MM/yyyy');
    final fechaString = dateFormat.format(tutoria.fechaHoraSugerida);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(
                color: PdfColor.fromHex('#1CA887'),
                width: 8,
              ), // Borde verde primary
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'TUTORÍAS',
                      style: pw.TextStyle(
                        fontSize: 40,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1CA887'),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      'VECTA UTP',
                      style: pw.TextStyle(
                        fontSize: 40,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'CERTIFICADO DE PARTICIPACIÓN',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1951CB'),
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Se certifica que el estudiante',
                  style: const pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  estudiante.nombreCompleto.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Participó satisfactoriamente en la sesión de tutoría:',
                  style: const pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${tutoria.materiaOAsignatura} - ${tutoria.temaEspecifico}',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1CA887'),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Impartida por: $tutorNombre',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Text(
                        '|',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Text(
                        'Fecha: $fechaString',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Text(
                        '|',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Text(
                        'Duración: ${tutoria.duracionMinutos} minutos',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 180,
                          height: 1,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Firma del Tutor',
                          style: pw.TextStyle(color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(
                          width: 180,
                          height: 1,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'VECTA Autorización',
                          style: pw.TextStyle(color: PdfColors.grey700),
                        ),
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'certificado_vecta_${tutoria.materiaOAsignatura.replaceAll(" ", "_")}.pdf',
    );
  }
}
