import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'workforce_api.dart';

class CareerPickedDocument {
  const CareerPickedDocument(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

Future<CareerPickedDocument?> pickCareerDocument() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    withData: false,
    allowMultiple: false,
  );
  if (result == null) return null;
  final picked = result.files.single;
  if (picked.size <= 0 || picked.size > 5 * 1024 * 1024 || picked.path == null)
    throw const WorkforceApiException(
      'Choose a PDF, JPEG or PNG of 5 MB or less.',
    );
  final file = File(picked.path!);
  if (await file.length() > 5 * 1024 * 1024)
    throw const WorkforceApiException('The selected document exceeds 5 MB.');
  return CareerPickedDocument(picked.name, await file.readAsBytes());
}

Future<bool> saveCareerDocument(Uint8List bytes) async {
  final ext =
      bytes.length >= 5 && String.fromCharCodes(bytes.take(5)) == '%PDF-'
      ? 'pdf'
      : bytes.length >= 2 && bytes[0] == 255 && bytes[1] == 216
      ? 'jpg'
      : 'png';
  return await FilePicker.saveFile(
        dialogTitle: 'Save private Care360 document',
        fileName: 'care360-document.$ext',
        type: FileType.custom,
        allowedExtensions: [ext],
        bytes: bytes,
      ) !=
      null;
}

Future<bool> saveCareerExport(String json) async =>
    await FilePicker.saveFile(
      dialogTitle: 'Save your private career data',
      fileName: 'care360-career-export.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(utf8.encode(json)),
    ) !=
    null;
