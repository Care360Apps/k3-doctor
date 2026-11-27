import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Care360ReportImage extends StatefulWidget {
  const Care360ReportImage({super.key, required this.apiBase,
    required this.appointmentId, required this.url, required this.readToken});
  final Uri apiBase;
  final int appointmentId;
  final String url;
  final Future<String?> Function() readToken;
  @override
  State<Care360ReportImage> createState() => _Care360ReportImageState();
}

class _Care360ReportImageState extends State<Care360ReportImage> {
  late Future<Uint8List> _bytes;
  http.Client? _client;
  @override
  void initState() {
    super.initState();
    _bytes = _load();
  }
  @override
  void didUpdateWidget(Care360ReportImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.appointmentId != widget.appointmentId ||
        oldWidget.apiBase != widget.apiBase) {
      _client?.close();
      _bytes = _load();
    }
  }
  Future<Uint8List> _load() async {
    final base = widget.apiBase;
    final uri = Uri.parse(widget.url);
    final id = widget.appointmentId;
    if (id <= 0 || base.scheme != 'https' || uri.scheme != base.scheme ||
        uri.host != base.host || uri.port != base.port ||
        uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      throw const FormatException('Invalid report URL');
    }
    final privatePath = RegExp(r'^/api/medical-files/appointments/([1-9][0-9]*)/reports/k3report_[a-f0-9]{40}\.png$').firstMatch(uri.path);
    final legacy = RegExp(r'^/images/upload/[a-zA-Z0-9_-]+\.png$').hasMatch(uri.path);
    if (privatePath == null && !legacy ||
        privatePath != null && privatePath.group(1) != id.toString()) {
      throw const FormatException('Invalid report scope');
    }
    final client = http.Client();
    _client = client;
    const timeout = Duration(seconds: 30);
    try {
      final request = http.Request('GET', uri)..followRedirects = false;
      request.headers['Accept'] = 'image/png';
      if (privatePath != null) {
        final token = (await widget.readToken().timeout(timeout))?.trim();
        if (token == null || token.isEmpty || token == 'null' || token == 'N_A') {
          throw const FormatException('Sign in required');
        }
        request.headers['Authorization'] = 'Bearer $token';
      }
      final response = await client.send(request).timeout(timeout);
      final iterator = StreamIterator<List<int>>(response.stream);
      try {
        const limit = 6 * 1024 * 1024;
        if (response.statusCode != 200 || (response.contentLength ?? 0) > limit ||
            (response.headers['content-type'] ?? '').split(';').first.trim() != 'image/png') {
          throw const FormatException('Report unavailable');
        }
        final buffer = BytesBuilder(copy: false);
        final clock = Stopwatch()..start();
        while (true) {
          final remaining = timeout - clock.elapsed;
          if (remaining <= Duration.zero) throw TimeoutException('Report download');
          if (!await iterator.moveNext().timeout(remaining)) break;
          if (buffer.length + iterator.current.length > limit) {
            throw const FormatException('Report too large');
          }
          buffer.add(iterator.current);
        }
        final bytes = buffer.takeBytes();
        const signature = [137,80,78,71,13,10,26,10];
        if (bytes.length < 24) throw const FormatException('Invalid PNG');
        for (var i = 0; i < signature.length; i++) {
          if (bytes[i] != signature[i]) throw const FormatException('Invalid PNG');
        }
        return bytes;
      } finally {
        await iterator.cancel();
      }
    } finally {
      client.close();
    }
  }
  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _bytes,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.hasError) {
        return const Center(child: Text('Report unavailable'));
      }
      return Image.memory(snapshot.data!, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text('Invalid report image'));
    },
  );
}
