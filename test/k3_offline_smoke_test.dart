import 'package:doctro/retrofit/apis.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('API has a safe unavailable default without explicit environment', () {
    expect(Apis.baseUrl, 'http://127.0.0.1:9/api/');
  });
  test('Flutter project contains its expected source and assets', () {
    expect(File('pubspec.yaml').existsSync(), isTrue);
    expect(Directory('lib').existsSync(), isTrue);
    expect(Directory('assets').existsSync(), isTrue);
  });
}
