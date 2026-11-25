import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Prescription upload authenticates and validates the Laravel success response',
      () {
    final source = File('lib/pdf_creation/report_pdf.dart').readAsStringSync();
    final screen =
        File('lib/screens/home page/patient_information.dart').readAsStringSync();

    expect(source, contains('Future<bool> reportView('));
    expect(source, isNot(contains('var token = Apis.baseUrl')));
    expect(source, contains(
      'SharedPreferenceHelper.getString(Preferences.auth_token).trim()'));
    expect(source, contains("token == 'N_A'"));
    expect(source, contains("token == 'null'"));
    expect(source, contains('http.MultipartFile.fromBytes('));
    expect(source, contains("if (!await _sendCare360Prescription(ctx, request)) return false;"));
    expect(source, contains('response.statusCode < 200 || response.statusCode >= 300'));
    expect(source, contains("decoded['success'] != true"));
    expect(source, contains("PdfViewerPage(bytes: pdfBytes)"));
    expect(source, isNot(contains('print(res);')));
    expect(source, isNot(contains('getExternalStorageDirectory()')));
    expect(source, isNot(contains('getApplicationDocumentsDirectory()')));
    expect(source, isNot(contains('File(')));
    expect(source, isNot(contains('writeAsBytes(')));
    expect(screen, contains('final uploaded = await reportView('));
    expect(screen, contains('if (uploaded && mounted)'));
  });

  test('Completion preview only happens after verified server acknowledgement', () {
    final code = File('lib/pdf_creation/report_pdf.dart').readAsStringSync();
    final posCheck = code.indexOf(
        'if (!await _sendCare360Prescription(ctx, request)) return false;');
    final posPreview = code.indexOf('PdfViewerPage(bytes: pdfBytes)');
    expect(posCheck, greaterThan(0));
    expect(posPreview, greaterThan(posCheck));
    expect(code, contains('if (!ctx.mounted) return false;'));
    expect(code, contains('Sign in to upload a prescription.'));
    expect(code, contains('Prescription upload failed. Please retry.'));
  });

  test('Legacy PDF screen still supports file paths while new PDFs stay memory-only', () {
    final viewer = File('lib/pdf_creation/pdf_viewer_page.dart').readAsStringSync();
    expect(viewer, contains('SfPdfViewer.memory(document)'));
    expect(viewer, contains('SfPdfViewer.file(path!)'));
  });
}
