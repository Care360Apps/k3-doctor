import 'package:doctro/constant/app_string.dart';
import 'package:doctro/constant/prefConstatnt.dart';
import 'package:doctro/constant/preferences.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/pdf_creation/pdf_viewer_page.dart';
import 'package:doctro/retrofit/apis.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart' as material;
import 'package:pdf/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

reportView(ctx, List<Map<String, dynamic>> pdfData, int? id, int? userId, String convertMedicine) async {
  final Document pdf = Document();
  pdf.addPage(MultiPage(
      pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
      crossAxisAlignment: CrossAxisAlignment.start,
      header: (Context context) {
        return Container(
            alignment: Alignment.centerRight,
            margin: const EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
            padding: const EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
            child: Text(getTranslated(ctx, AppString.report_heading).toString(), style: Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey)));
      },
      footer: (Context context) {
        return Container(
            alignment: Alignment.centerRight,
            margin: const EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: Text('${getTranslated(ctx, AppString.report_page_heading).toString()} ${context.pageNumber} ${getTranslated(ctx, AppString.page_length).toString()} ${context.pagesCount}', style: Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey)));
      },
      build: (Context context) => <Widget>[
            Header(level: 0, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[Text('${getTranslated(ctx, AppString.prescription).toString()}', textScaleFactor: 2), PdfLogo()])),
            TableHelper.fromTextArray(
              context: context,
              data: <List<String?>>[
                // These will be your columns as Parameter X, Parameter Y etc.
                <String>[
                  '${getTranslated(ctx, AppString.medicine_name).toString()}',
                  '${getTranslated(ctx, AppString.days).toString()}',
                  '${getTranslated(ctx, AppString.morning).toString()}',
                  '${getTranslated(ctx, AppString.afternoon).toString()}',
                  '${getTranslated(ctx, AppString.night).toString()}'
                ],
                for (int i = 0; i < pdfData.length; i++)
                  <String?>[
                    // ith element will go in ith column means
                    // featureNames[i] in 1st column
                    pdfData[i]['medicine'],
                    pdfData[i]['days'].toString(),
                    pdfData[i]['morning'].toString(),
                    pdfData[i]['afternoon'].toString(),
                    pdfData[i]['night'].toString(),
                  ],
              ],
            ),
          ]));

  if (Platform.isAndroid) {
    final Directory? appDirectory = await getExternalStorageDirectory();

    final String outputDirectory = '${appDirectory!.path}/GeneratedPdf';
    await Directory(outputDirectory).create(recursive: true);
    final String currentTime = DateTime.now().millisecondsSinceEpoch.toString();
    final File file = File('$outputDirectory/$currentTime.pdf');

    Preferences.filePath = file.path;
    Preferences.fileName = "$currentTime.pdf";
    await file.writeAsBytes(await pdf.save()).then((value) async {
      var fullUrl = Uri.parse("${Apis.baseUrl}add_prescription");

      var token = SharedPreferenceHelper.getString(Preferences.auth_token);
      var request = http.MultipartRequest("POST", fullUrl);
      if (token == 'N_A' || token == 'null' || token.trim().isEmpty) {
        material.ScaffoldMessenger.of(ctx).showSnackBar(const material.SnackBar(
          content: material.Text('Sign in to upload a prescription.'),
        ));
        return;
      }
      Map<String, String> headers = {
        "Authorization": "Bearer ${token.trim()}",
        "Accept": "application/json"
      };
      try {
        request.files.add(
          await http.MultipartFile.fromPath(
            'pdf',
            Preferences.filePath,
            contentType: MediaType('application', 'pdf'),
            filename: Preferences.fileName,
          ),
        );
      } catch (_) {
        material.ScaffoldMessenger.of(ctx).showSnackBar(
          const material.SnackBar(
            content: material.Text('Could not attach prescription PDF.'),
          ),
        );
        return;
      }

      request.headers.addAll(headers);
      request.fields.addAll({"appointment_id": id.toString(), "user_id": userId.toString(), "medicines": convertMedicine});

      if (!await _sendCare360Prescription(ctx, request)) return;
    });
    material.Navigator.of(ctx).push(
      material.MaterialPageRoute(
        builder: (_) => PdfViewerPage(path: file),
      ),
    );
  } else if (Platform.isIOS) {
    final Directory? appDirectory = await getApplicationDocumentsDirectory();

    final String outputDirectory = '${appDirectory!.path}/GeneratedPdf';
    await Directory(outputDirectory).create(recursive: true);
    final String currentTime = DateTime.now().millisecondsSinceEpoch.toString();
    final File file = File('$outputDirectory/$currentTime.pdf');

    Preferences.filePath = file.path;
    Preferences.fileName = "$currentTime.pdf";
    await file.writeAsBytes(await pdf.save()).then((value) async {
      var fullUrl = Uri.parse("${Apis.baseUrl}add_prescription");

      var token = SharedPreferenceHelper.getString(Preferences.auth_token);
      var request = http.MultipartRequest("POST", fullUrl);
      if (token == 'N_A' || token == 'null' || token.trim().isEmpty) {
        material.ScaffoldMessenger.of(ctx).showSnackBar(const material.SnackBar(
          content: material.Text('Sign in to upload a prescription.'),
        ));
        return;
      }
      Map<String, String> headers = {
        "Authorization": "Bearer ${token.trim()}",
        "Accept": "application/json"
      };

      try {
        request.files.add(
          await http.MultipartFile.fromPath(
            'pdf',
            Preferences.filePath,
            contentType: MediaType('application', 'pdf'),
            filename: Preferences.fileName,
          ),
        );
      } catch (_) {
        material.ScaffoldMessenger.of(ctx).showSnackBar(
          const material.SnackBar(
            content: material.Text('Could not attach prescription PDF.'),
          ),
        );
        return;
      }

      request.headers.addAll(headers);
      request.fields.addAll({"appointment_id": id.toString(), "user_id": userId.toString(), "medicines": convertMedicine});

      if (!await _sendCare360Prescription(ctx, request)) return;
    });
    material.Navigator.of(ctx).push(
      material.MaterialPageRoute(
        builder: (_) => PdfViewerPage(path: file),
      ),
    );
  }
}


Future<bool> _sendCare360Prescription(
    material.BuildContext context, http.MultipartRequest request) async {
  try {
    final response = await request.send();
    // HTTP 200 is not enough; the Laravel API can send a JSON failure.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _showUploadFailure(context);
      return false;
    }
    final body = await response.stream.bytesToString();
    final decoded = jsonDecode(body);
    if (decoded is! Map || decoded['success'] != true) {
      _showUploadFailure(context);
      return false;
    }
    return true;
  } catch (_) {
    _showUploadFailure(context);
    return false;
  }
}

void _showUploadFailure(material.BuildContext context) {
  material.ScaffoldMessenger.of(context).showSnackBar(
    const material.SnackBar(
      content: material.Text('Prescription upload failed. Please retry.'),
    ),
  );
}
