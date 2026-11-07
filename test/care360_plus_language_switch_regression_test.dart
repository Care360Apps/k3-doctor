import 'dart:io';

import 'package:doctro/brand/care360_global_language.dart';
import 'package:doctro/localization/care360_framework_locale_fallback.dart';
import 'package:doctro/localization/language_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Plus switches from English to Hausa without a Flutter overlay error',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var locale = const Locale('en', 'US');
    var changes = 0;

    await tester.pumpWidget(StatefulBuilder(
      builder: (context, updateRoot) => MaterialApp(
        navigatorKey: navigatorKey,
        locale: locale,
        supportedLocales: const [
          Locale('en', 'US'), Locale('ha', 'NG'), Locale('ig', 'NG'),
          Locale('yo', 'NG'), Locale('fr', 'FR'),
        ],
        localizationsDelegates: const [
          LanguageLocalization.delegate,
          Care360MaterialFallbackDelegate(),
          Care360WidgetsFallbackDelegate(),
          Care360CupertinoFallbackDelegate(),
        ],
        builder: (context, navigatorChild) => Stack(children: [
          if (navigatorChild != null) navigatorChild,
          PositionedDirectional(
            end: 10, bottom: 64,
            child: Care360GlobalLanguageSwitch(
              rootNavigatorKey: navigatorKey,
              onSelect: (code) async {
                changes += 1;
                updateRoot(() => locale = Locale(code));
              },
            ),
          ),
        ]),
        home: Scaffold(body: Builder(
          builder: (context) => Text(
            'Locale: ${Localizations.localeOf(context).languageCode}'),
        )),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Locale: en'), findsOneWidget);
    await tester.tap(find.byKey(const Key('care360-language-every-screen')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hausa'));
    await tester.pumpAndSettle();
    expect(find.text('Locale: ha'), findsOneWidget);
    expect(changes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Plus language menu can close without mutating current screen',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var selections = 0;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      builder: (context, navigatorChild) => Stack(children: [
        if (navigatorChild != null) navigatorChild,
        PositionedDirectional(end: 10, bottom: 64,
          child: Care360GlobalLanguageSwitch(
            rootNavigatorKey: navigatorKey,
            onSelect: (_) async { selections += 1; },
          )),
      ]),
      home: const Scaffold(body: Text('Clinical dashboard')),
    ));
    await tester.tap(find.byKey(const Key('care360-language-every-screen')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(selections, 0);
    expect(find.text('Clinical dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Professional Settings awaits route completion before locale rebuild', () {
    final settings = File('lib/screens/setting/changeLanguage.dart')
        .readAsStringSync();
    final root = File('lib/main.dart').readAsStringSync();
    expect(settings, contains('await exiting?.completed'));
    expect(settings, contains('MyApp.setLocale(rootContext, locale)'));
    expect(root, contains('Care360MaterialFallbackDelegate()'));
    expect(root, contains('Care360WidgetsFallbackDelegate()'));
    expect(root, contains('Care360CupertinoFallbackDelegate()'));
  });
}
