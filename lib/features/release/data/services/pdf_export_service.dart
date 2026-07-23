import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/release_check.dart';

class PdfExportService {
  Future<void> exportReport(String projectName, int score, List<ReleaseCheck> checks, String savePath) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Release Readiness Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Project: $projectName', style: const pw.TextStyle(fontSize: 14)),
          pw.Text('Date: ${DateTime.now().toLocal().toString().split('.')[0]}', style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 20),
          
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Overall Readiness Score', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('$score/100', style: pw.TextStyle(
                  fontSize: 24, 
                  fontWeight: pw.FontWeight.bold,
                  color: score >= 80 ? PdfColors.green : (score >= 60 ? PdfColors.orange : PdfColors.red),
                )),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'Detailed Breakdown'),
          
          ...checks.map((check) => _buildCheckItem(check)).toList(),
        ],
      ),
    );

    final file = File(savePath);
    await file.writeAsBytes(await pdf.save());
  }

  pw.Widget _buildCheckItem(ReleaseCheck check) {
    PdfColor statusColor;
    String statusText;
    
    switch (check.status) {
      case ReleaseCheckStatus.pass:
        statusColor = PdfColors.green;
        statusText = 'PASS';
        break;
      case ReleaseCheckStatus.fail:
        statusColor = PdfColors.red;
        statusText = 'FAIL';
        break;
      case ReleaseCheckStatus.warning:
        statusColor = PdfColors.orange;
        statusText = 'WARN';
        break;
      case ReleaseCheckStatus.info:
        statusColor = PdfColors.blue;
        statusText = 'INFO';
        break;
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(width: 4, color: PdfColors.grey300)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(check.title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(statusText, style: pw.TextStyle(color: statusColor, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(check.description, style: const pw.TextStyle(color: PdfColors.grey700)),
        ],
      ),
    );
  }
}
