import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Both platforms upload prescriptions using the actual secure user token',
      () {
    final src = File('lib/pdf_creation/report_pdf.dart').readAsStringSync();

    // iOS used to send the API URL as the Bearer token; this is never valid.
    expect(src, isNot(contains('var token = Apis.baseUrl')));
    expect(
      'var token = SharedPreferenceHelper.getString(Preferences.auth_token)'
          .allMatches(src).length,
      2,
    );
    expect('Bearer ${token.trim()}'.allMatches(src).length, 2);
    expect('if (res.statusCode < 200 || res.statusCode >= 300)'
        .allMatches(src).length, 2);
    expect(src, isNot(contains('print(res);')));
    expect(src, isNot(contains('"content-type": "multipart/form-data"')));
    expect(src, contains('http.MultipartFile.fromPath('));
    expect(src, contains('PdfViewerPage(path: file)'));
  });

  test('Upload cannot proceed with a missing or placeholder session', () {
    final code = File('lib/pdf_creation/report_pdf.dart').readAsStringSync();
    expect("token == 'N_A'".allMatches(code).length, 2);
    expect("token == 'null'".allMatches(code).length, 2);
    expect(code, contains('Sign in to upload a prescription.'));
    expect(code, contains('Prescription upload failed. Please retry.'));
  });
}
