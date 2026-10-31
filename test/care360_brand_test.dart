import 'package:doctro/screens/onboarding/care360_master_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Care360 Plus uses the shared master brand image and doctor label',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: Care360MasterBrand(logoSize: 60)),
      ),
    ));

    expect(find.text('Care360 Plus'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == 'assets/images/care360_master_logo.webp'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
