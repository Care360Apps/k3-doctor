import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/brand/care360_public_access.dart';

void main() {
  testWidgets('Five languages are accessible before sign-in', (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Care360PublicAccess(
        onLanguageSelected: (code) async { selected = code; },
      )),
    ));

    expect(find.byKey(const Key('care360-public-access')), findsOneWidget);
    await tester.tap(find.byKey(const Key('care360-public-language')));
    await tester.pumpAndSettle();
    for (final name in ['English', 'Hausa', 'Igbo', 'Yorùbá', 'Français']) {
      expect(find.text(name), findsWidgets);
    }
    await tester.tap(find.text('Yorùbá').last);
    await tester.pumpAndSettle();
    expect(selected, 'yo');
  });

  testWidgets('MindCheck opens only approved HTTPS URL without user data',
      (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Care360PublicAccess(
        openExternal: (uri) async { opened = uri; return true; },
      )),
    ));
    await tester.tap(find.byKey(const Key('care360-public-mindcheck')));
    await tester.pumpAndSettle();
    expect(opened.toString(), 'https://mindcheck.speakoutmentalhealth.org/');
    expect(opened!.query, isEmpty);
    expect(opened!.fragment, isEmpty);
    expect(find.text('MindCheck · SpeakOut'), findsOneWidget);
  });

  testWidgets('Public controls fit narrow Android phone width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: Care360PublicAccess(),
      )),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('care360-public-language')), findsOneWidget);
    expect(find.byKey(const Key('care360-public-mindcheck')), findsOneWidget);
  });
}
