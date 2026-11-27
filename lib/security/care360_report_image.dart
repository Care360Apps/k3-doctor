import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Care360ReportImage extends StatefulWidget {
  const Care360ReportImage({
    super.key,
    required this.apiBase,
    required this.appointmentId,
    required this.url,
    required this.readToken,
    this.clientFactory,
  });
  final Uri apiBase;
  final int appointmentId;
  final String url;
  final Future<String?> Function() readToken;
  final http.Client Function()? clientFactory;
  @override
  State<Care360ReportImage> createState() => _Care360ReportImageState();
}

class _Care360ReportImageState extends State<Care360ReportImage>
    with WidgetsBindingObserver {
  bool _visible = true;
  late Future<Uint8List> _bytes;
  http.Client? _client;
  ImageProvider? _displayedProvider;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bytes = _load();
  }

  @override
  void didUpdateWidget(Care360ReportImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.appointmentId != widget.appointmentId ||
        oldWidget.apiBase != widget.apiBase) {
      _client?.close();
      unawaited(_displayedProvider?.evict() ?? Future.value(false));
      _bytes = _load();
    }
  }

  Future<Uint8List> _load() => Care360ReportImageClient(
    apiBase: widget.apiBase,
    appointmentId: widget.appointmentId,
    url: widget.url,
    readToken: widget.readToken,
    clientFactory: () {
      final client = widget.clientFactory?.call() ?? http.Client();
      _client = client;
      return client;
    },
  ).fetch();
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _visible = true;
        _bytes = _load();
      });
    } else {
      _client?.close();
      unawaited(_displayedProvider?.evict() ?? Future.value(false));
      setState(() {
        _bytes = Future.value(Uint8List(0));
        _visible = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _client?.close();
    unawaited(_displayedProvider?.evict() ?? Future.value(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !_visible
      ? const SizedBox.shrink()
      : FutureBuilder<Uint8List>(
          future: _bytes,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Report unavailable. Check your connection or sign in again.',
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _bytes = _load();
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            _displayedProvider = ResizeImage.resizeIfNeeded(
              (MediaQuery.sizeOf(context).width *
                      MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(1, 2048),
              null,
              MemoryImage(snapshot.data!),
            );
            return Image(
              image: _displayedProvider!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text('Invalid report image'),
            );
          },
        );
}

/// In-memory only, origin-scoped transport. Never follows redirects or writes medical data to disk.
class Care360ReportImageClient {
  Care360ReportImageClient({
    required this.apiBase,
    required this.appointmentId,
    required this.url,
    required this.readToken,
    http.Client Function()? clientFactory,
  }) : clientFactory = clientFactory ?? http.Client.new;
  final Uri apiBase;
  final int appointmentId;
  final String url;
  final Future<String?> Function() readToken;
  final http.Client Function() clientFactory;
  Future<Uint8List> fetch() async {
    final base = apiBase;
    final uri = Uri.parse(url);
    final id = appointmentId;
    if (id <= 0 ||
        base.scheme != 'https' ||
        uri.scheme != base.scheme ||
        uri.host != base.host ||
        uri.port != base.port ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('Invalid report URL');
    }
    final privatePath = RegExp(
      r'^/api/medical-files/appointments/([1-9][0-9]*)/reports/k3report_[a-f0-9]{40}\.png$',
    ).firstMatch(uri.path);
    final legacy = RegExp(
      r'^/images/upload/[a-zA-Z0-9_-]+\.png$',
    ).hasMatch(uri.path);
    if (privatePath == null && !legacy ||
        privatePath != null && privatePath.group(1) != id.toString()) {
      throw const FormatException('Invalid report scope');
    }
    final client = clientFactory();
    const timeout = Duration(seconds: 30);
    try {
      final request = http.Request('GET', uri)..followRedirects = false;
      request.headers['Accept'] = 'image/png';
      request.headers['Cache-Control'] = 'no-store';
      String? authorizedToken;
      if (privatePath != null) {
        final token = (await readToken().timeout(timeout))?.trim();
        if (token == null ||
            token.isEmpty ||
            token == 'null' ||
            token == 'N_A') {
          throw const FormatException('Sign in required');
        }
        request.headers['Authorization'] = 'Bearer $token';
        authorizedToken = token;
      }
      final response = await client.send(request).timeout(timeout);
      final iterator = StreamIterator<List<int>>(response.stream);
      try {
        const limit = 6 * 1024 * 1024;
        if (response.statusCode != 200 ||
            (response.contentLength ?? 0) > limit ||
            (response.headers['content-type'] ?? '').split(';').first.trim() !=
                'image/png') {
          throw const FormatException('Report unavailable');
        }
        final buffer = BytesBuilder(copy: false);
        final clock = Stopwatch()..start();
        while (true) {
          final remaining = timeout - clock.elapsed;
          if (remaining <= Duration.zero)
            throw TimeoutException('Report download');
          if (!await iterator.moveNext().timeout(remaining)) break;
          if (buffer.length + iterator.current.length > limit) {
            throw const FormatException('Report too large');
          }
          buffer.add(iterator.current);
        }
        final bytes = buffer.takeBytes();
        const signature = [137, 80, 78, 71, 13, 10, 26, 10];
        if (bytes.length < 24) throw const FormatException('Invalid PNG');
        for (var i = 0; i < signature.length; i++) {
          if (bytes[i] != signature[i])
            throw const FormatException('Invalid PNG');
        }
        final data = ByteData.sublistView(bytes);
        final width = data.getUint32(16), height = data.getUint32(20);
        if (bytes.length < 33 ||
            String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR' ||
            width == 0 ||
            height == 0 ||
            width > 10000 ||
            height > 10000 ||
            width * height > 16000000) {
          throw const FormatException('Unsupported report dimensions');
        }
        if (authorizedToken != null &&
            (await readToken().timeout(timeout))?.trim() != authorizedToken) {
          throw const FormatException('Session changed');
        }
        return bytes;
      } finally {
        await iterator.cancel();
      }
    } finally {
      client.close();
    }
  }
}
