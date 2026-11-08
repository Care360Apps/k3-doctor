import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// A private, in-memory prescription preview. File bytes are never written
/// to shared Downloads, local preferences, browser history or external URLs.
class Care360ProtectedPdfViewer extends StatefulWidget {
  const Care360ProtectedPdfViewer({
    super.key,
    required this.loadPdf,
  });

  final Future<Uint8List> Function() loadPdf;

  @override
  State<Care360ProtectedPdfViewer> createState() =>
      _Care360ProtectedPdfViewerState();
}

class _Care360ProtectedPdfViewerState
    extends State<Care360ProtectedPdfViewer> {
  late Future<Uint8List> _document;

  @override
  void initState() {
    super.initState();
    _document = widget.loadPdf();
  }

  void _retry() {
    setState(() {
      _document = widget.loadPdf();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF123E4D),
        foregroundColor: Colors.white,
        title: const Text('Private prescription'),
      ),
      body: FutureBuilder<Uint8List>(
        future: _document,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF087D76)),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFF087D76), size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'Prescription not available',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check your connection or access permissions and retry.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('retry-private-prescription'),
                      onPressed: _retry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          return SfPdfViewer.memory(
            snapshot.data!,
            key: const Key('private-prescription-in-memory-viewer'),
            canShowPaginationDialog: false,
            canShowPasswordDialog: false,
            enableHyperlinkNavigation: false,
            canShowHyperlinkDialog: false,
          );
        },
      ),
    );
  }
}
