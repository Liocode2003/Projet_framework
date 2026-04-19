import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/orientation_result_model.dart';

class PdfExportService {
  /// Generates a PDF report and returns the saved file path.
  Future<String> exportReport({
    required OrientationResultModel result,
    required String studentName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          _buildHeader(studentName, result),
          pw.SizedBox(height: 20),
          _buildSummaryRow(result),
          pw.SizedBox(height: 20),
          _buildScoresTable(result),
          pw.SizedBox(height: 20),
          _buildRecommendation(result),
          pw.SizedBox(height: 16),
          _buildAnalysis(result),
          pw.SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );

    // Save to app documents directory
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/loniya_reports');
    if (!folder.existsSync()) folder.createSync(recursive: true);

    final file =
        File('${folder.path}/orientation_${result.id.substring(0, 8)}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  /// Opens the system share sheet with the generated PDF.
  Future<void> sharePdf(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Orientation_LONIYA.pdf',
    );
  }

  // ─── PDF sections ──────────────────────────────────────────────────────────

  pw.Widget _buildHeader(
    String studentName,
    OrientationResultModel result,
  ) {
    final date = DateTime.parse(result.createdAt);
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('6A1B9A'),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LONIYA V2 — Rapport d\'Orientation',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Élève : $studentName',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                ),
              ),
              pw.Text(
                'Date : $dateStr',
                style: const pw.TextStyle(
                  color: PdfColors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.white24,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              result.examType,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryRow(OrientationResultModel result) {
    return pw.Row(
      children: [
        _statBox('Moyenne',
            '${result.average.toStringAsFixed(1)}/20', PdfColor.fromHex('2D7D32')),
        pw.SizedBox(width: 12),
        _statBox('Probabilité',
            '${(result.successProbability * 100).toInt()}%',
            PdfColor.fromHex('E8A020')),
        pw.SizedBox(width: 12),
        _statBox('Matières',
            '${result.scores.length}', PdfColor.fromHex('0277BD')),
      ],
    );
  }

  pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                )),
            pw.Text(label,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                )),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildScoresTable(OrientationResultModel result) {
    final rows = result.scores.entries.map((e) {
      final score   = e.value;
      final mention = score >= 16 ? 'TB' :
                      score >= 14 ? 'B'  :
                      score >= 12 ? 'AB' :
                      score >= 10 ? 'P'  : 'RI';
      final color   = score >= 14 ? PdfColor.fromHex('2E7D32')
                    : score >= 10 ? PdfColor.fromHex('E65100')
                    : PdfColor.fromHex('B71C1C');
      return pw.TableRow(children: [
        _cell(e.key),
        _cell('${score.toStringAsFixed(1)}/20', color: color),
        _cell(mention, color: color),
      ]);
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Notes par matière',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            )),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F5F0E8')),
              children: [
                _cell('Matière', bold: true),
                _cell('Note',    bold: true),
                _cell('Mention', bold: true),
              ],
            ),
            ...rows,
          ],
        ),
      ],
    );
  }

  pw.Widget _cell(String text, {PdfColor? color, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          color: color ?? PdfColors.black,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildRecommendation(OrientationResultModel result) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('E8F5E9'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor.fromHex('2E7D32'), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Filière recommandée',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColor.fromHex('2E7D32'),
              )),
          pw.SizedBox(height: 4),
          pw.Text(
            result.recommendedFiliere,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('1B5E20'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            result.successLabel,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('2E7D32'),
            ),
          ),
          if (result.alternativeFilières.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Alternatives : ${result.alternativeFilières.join(' · ')}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildAnalysis(OrientationResultModel result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Analyse',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            )),
        pw.SizedBox(height: 6),
        pw.Text(
          result.analysisText.replaceAll('**', ''),
          style: const pw.TextStyle(fontSize: 10, lineSpacing: 4),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border:
            pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
      child: pw.Text(
        'Généré par LONIYA V2 · Plateforme éducative offline · Burkina Faso',
        style: const pw.TextStyle(
            fontSize: 8, color: PdfColors.grey500),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
