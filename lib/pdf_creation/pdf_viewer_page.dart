import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Reuses the existing viewer for local files while allowing confidential
/// newly-generated prescriptions to stay entirely in memory.
class PdfViewerPage extends StatelessWidget {
  final File? path;
  final Uint8List? bytes;

  const PdfViewerPage({super.key, this.path, this.bytes});

  @override
  Widget build(BuildContext context) {
    final document = bytes;
    return Scaffold(
      body: document != null
          ? SfPdfViewer.memory(document)
          : path != null
              ? SfPdfViewer.file(path!)
              : const Center(child: Text('PDF is unavailable.')),
    );
  }
}
