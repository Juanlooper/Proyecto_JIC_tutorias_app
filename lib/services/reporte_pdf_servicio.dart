import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/admin_provider.dart';

class ReportePdfServicio {
  static Future<void> generarPdf(AdminProvider admin) async {
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    final pdf = pw.Document(
      title: 'Reporte de Métricas Globales Vecta',
      author: 'Administración Vecta',
      creator: 'Sistema Vecta',
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    // Primary Colors from Vecta Theme
    final primaryGreen = PdfColor.fromHex('#1CA887');
    final primaryBlue = PdfColor.fromHex('#1951CB');
    final darkText = PdfColor.fromHex('#1E293B');

    // Page 1: Resumen General
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(
              'Reporte Global de Métricas - Vecta',
              style: pw.TextStyle(
                color: primaryGreen,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(color: PdfColors.grey, fontSize: 10),
            ),
          );
        },
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Análisis de Plataforma',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                pw.Text(
                  'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: pw.TextStyle(fontSize: 12, color: darkText),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Text(
            '1. Rendimiento y Bienestar Estudiantil',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: darkText,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildInfoCard(
                  'Horas Impartidas',
                  '${admin.totalHorasImpartidas.toStringAsFixed(1)} hrs',
                  primaryGreen,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildInfoCard(
                  'SLA Promedio',
                  '${admin.slaPromedioGlobal.inHours} hrs',
                  primaryBlue,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildInfoCard(
                  'Índice Deserción',
                  '${admin.indiceDesercionGlobal.toStringAsFixed(1)}%',
                  PdfColors.orange,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Text(
            'Materias Cuello de Botella (Top 5)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildTable(
            ['Materia', 'Solicitudes Huérfanas'],
            admin.materiasCuelloDeBotella
                .map((e) => [e.key, e.value.toString()])
                .toList(),
          ),

          pw.SizedBox(height: 20),
          pw.Text(
            '2. Auditoría Estricta de Tutores',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: darkText,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildTable(
            [
              'Tutor ID',
              'Horas Impartidas',
              'Retención (%)',
              'Cancelación Tardía (%)',
            ],
            admin.horasPorTutor.entries
                .map(
                  (e) => [
                    e.key.length > 8 ? e.key.substring(0, 8) : e.key,
                    e.value.toStringAsFixed(1),
                    (admin.tasaRetencionTutor[e.key] ?? 0.0).toStringAsFixed(1),
                    (admin.tasaCancelacionTardiaTutor[e.key] ?? 0.0)
                        .toStringAsFixed(1),
                  ],
                )
                .toList(),
          ),

          pw.SizedBox(height: 20),
          pw.Text(
            '3. Demografía, Usuarios y Evaluaciones',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: darkText,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Distribución de Estrellas Globales:',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Wrap(
            spacing: 10,
            children: List.generate(5, (index) {
              int estrella = 5 - index;
              int count = admin.distribucionEstrellasGlobal[estrella] ?? 0;
              return pw.Text('$estrella Estrellas: $count valoraciones');
            }),
          ),
          pw.SizedBox(height: 15),
          _buildTable(
            ['Alumno', 'Facultad', 'Horas Totales', 'Riesgo'],
            admin.heavyUsers.map((e) {
              double hrs = double.tryParse(e['horas'].toString()) ?? 0.0;
              String riesgo = hrs >= 10 ? 'ALTO' : 'MODERADO';
              return [
                e['nombre'].toString(),
                e['facultad'].toString(),
                hrs.toStringAsFixed(1),
                riesgo,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Vecta_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildInfoCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor(color.red, color.green, color.blue, 0.1),
        border: pw.Border.all(color: color),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(List<String> headers, List<List<String>> data) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1CA887')),
      rowDecoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: .5),
        ),
      ),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }
}
