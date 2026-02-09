import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Generates a PDF from the provided history data and triggers a Firebase Cloud Function
  /// to send it as an email attachment.
  ///
  /// Throws a [FirebaseFunctionsException] if the cloud function fails.
  Future<void> generateAndSendPdf(List<Map<String, dynamic>> tomas, String emailAddress) async {
    // 1. Generate the PDF in memory
    final Uint8List pdfBytes = await _generatePdf(tomas);

    // 2. Convert PDF bytes to a Base64 string
    final String pdfBase64 = base64Encode(pdfBytes);

    // 3. Prepare the data for the Cloud Function
    final HttpsCallable callable = _functions.httpsCallable('sendEmail');
    final data = <String, dynamic>{
      'to': emailAddress,
      'pdfBase64': pdfBase64,
      'subject': 'Historial de Tomas de Medicamentos',
      'body': 'Adjunto encontrarás tu historial de tomas de medicamentos.',
    };

    // 4. Call the Cloud Function and handle potential errors
    try {
      print('Calling sendEmail cloud function...');
      await callable.call(data);
      print('Cloud function executed successfully.');
    } on FirebaseFunctionsException catch (e) {
      print('Error calling cloud function: ${e.code} - ${e.message}');
      // Re-throw the exception to be caught by the UI
      throw Exception('Error al enviar el correo: ${e.message}');
    } catch (e) {
      print('An unexpected error occurred: $e');
      // Re-throw a generic exception
      throw Exception('Ocurrió un error inesperado al enviar el correo.');
    }
  }

  /// Private helper to generate the PDF document.
  Future<Uint8List> _generatePdf(List<Map<String, dynamic>> tomas) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Historial de Tomas', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(_formatDate(DateTime.now()), style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
            headers: ['Medicamento', 'Fecha', 'Hora', 'Estado'],
            data: tomas.map((toma) {
              final timestamp = toma['timestamp'] as Timestamp?;
              final fecha = timestamp?.toDate() ?? DateTime.now();

              return [
                toma['nombreMedicamento'] ?? 'N/A',
                _formatDate(fecha),
                toma['horaFormato'] ?? _formatTime(fecha),
                toma['estado'] ?? 'N/A',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
