import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/model/course_model.dart';
import '../lib/trains/trains_catalogue.dart';

void main() {
  CourseData c(
    String name, {
    String provider = 'cnu',
    num? amount,
    String? link,
  }) => CourseData(
    title: name,
    provider: provider,
    amount: amount,
    duration: 'Two weeks',
    summary: 'Synthetic summary',
    details: 'Synthetic details',
    link: link,
  );
  test('unknown, zero and invalid CNU tuition are never free', () {
    for (final value in [null, 0, -1, double.nan]) {
      expect(c('CNU', amount: value).tuitionLabel, 'Contact for tuition');
    }
    expect(c('CNU', amount: 12000).tuitionLabel, 'NGN 12,000.00');
    expect(
      c('SpeakOut', provider: 'speakout', amount: 900).tuitionLabel,
      '100% free',
    );
    expect(
      CourseData.fromJson({'provider': 'cnu', 'amount': null}).tuitionLabel,
      'Contact for tuition',
    );
  });
  test('external actions reject unsafe links and wrong SpeakOut hosts', () {
    for (final link in [
      'http://example.org',
      'javascript:alert(1)',
      'https://user:pass@example.org',
      'https://127.0.0.1/',
      'https://example.local/',
    ]) {
      expect(c('Test', link: link).applicationUri, isNull);
    }
    expect(
      c(
        'Test',
        provider: 'speakout',
        link: 'https://speakoutmentalhealth.org.evil.com/',
      ).applicationUri,
      isNull,
    );
    expect(
      c(
        'Test',
        provider: 'speakout',
        link: 'https://www.speakoutmentalhealth.org/courses',
      ).applicationUri,
      isNotNull,
    );
  });
  testWidgets(
    'search filters catalogue and opens details with safe external action',
    (tester) async {
      Uri? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: TrainsCatalogue(
            loader: () async => [
              c('Nursing', amount: 1000),
              c(
                'Wellbeing',
                provider: 'speakout',
                link: 'https://www.speakoutmentalhealth.org/apply',
              ),
            ],
            opener: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('trains-search')),
        'Wellbeing',
      );
      await tester.pump();
      expect(find.text('Nursing'), findsNothing);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Wellbeing').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wellbeing').last);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Registration and approval are required'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const Key('trains-apply')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('trains-apply')));
      await tester.pumpAndSettle();
      expect(opened.toString(), 'https://www.speakoutmentalhealth.org/apply');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'provider and tuition filters work without workforce membership',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TrainsCatalogue(
            loader: () async => [
              c('Nursing', amount: 1000),
              c('Wellbeing', provider: 'speakout'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SpeakOut').last);
      await tester.pumpAndSettle();
      expect(find.text('Nursing'), findsNothing);
      expect(find.text('Wellbeing').last, findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paid').last);
      await tester.pumpAndSettle();
      expect(find.text('No courses match these filters.'), findsOneWidget);
    },
  );
  testWidgets(
    'refresh reflects publication changes and errors can be retried',
    (tester) async {
      var fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: TrainsCatalogue(
            loader: () async {
              if (fail) throw Exception();
              return [];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(
        find.text('No published courses yet. Please check back soon.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'narrow enlarged text remains readable and missing links are disabled',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 740),
              textScaler: TextScaler.linear(1.8),
            ),
            child: TrainsCourseDetail(
              course: c('A longer professional course title'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('trains-apply')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('trains-apply')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
