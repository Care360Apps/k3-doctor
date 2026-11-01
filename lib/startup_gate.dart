import 'dart:async';
import 'package:flutter/material.dart';

/// Runs required initialization while rendering a visible, recoverable screen.
/// Optional network services belong in [onReady], after the actual app's frame.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.initialize,
    this.onReady,
    this.timeout = const Duration(seconds: 20),
  });

  final Future<Widget> Function() initialize;
  final VoidCallback? onReady;
  final Duration timeout;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<Widget> _initialization;
  bool _readyReported = false;
  final Stopwatch _clock = Stopwatch();

  @override
  void initState() {
    super.initState();
    _begin();
  }

  void _begin() {
    _readyReported = false;
    _clock.reset();
    _clock.start();
    _initialization = Future<Widget>.sync(widget.initialize).timeout(widget.timeout);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (!_readyReported) {
            _readyReported = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              debugPrint('K3_STARTUP: app ready after ${_clock.elapsedMilliseconds} ms');
              widget.onReady?.call();
            });
          }
          return snapshot.data!;
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: snapshot.hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Care360 could not start. Please try again.'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => setState(_begin),
                              child: const Text('Try again'),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Starting Care360…'),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
