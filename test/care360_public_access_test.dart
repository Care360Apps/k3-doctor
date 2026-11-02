import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/brand/care360_global_language.dart';

void main() {
  testWidgets('Language control offers all five languages on a route', (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Care360GlobalLanguageSwitch(
        onSelect: (code) async { selected = code; },
      )),
    ));
    await tester.tap(find.byKey(const Key('care360-language-every-screen')));
    await tester.pumpAndSettle();
    for (final code in ['en', 'ha', 'ig', 'yo', 'fr']) {
      expect(find.byKey(Key('language-$code')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('language-yo')));
    await tester.pumpAndSettle();
    expect(selected, 'yo');
  });

  testWidgets('Language selector opens on a narrow-screen registration route', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Stack(children: [
        const Center(child: Text('Sign up')),
        Positioned(bottom: 72, right: 10, child: Care360GlobalLanguageSwitch(
          onSelect: (code) async {},
        )),
      ])),
    ));
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.byKey(const Key('care360-language-every-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('care360-language-every-screen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('language-fr')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
