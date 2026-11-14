import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/screens/profile/profile_date.dart';

void main() {
  test('Absent and malformed dates stay unset without throwing', () {
    for (final value in [null, '', 'null', 'unknown', '2026-02-31', '2025-02-29', '31-12-1990']) {
      expect(Care360ProfileDate.parse(value), isNull);
    }
  });
  test('Valid clinician dates preserve their exact calendar day', () {
    expect(Care360ProfileDate.parse('1990-12-31'), DateTime(1990, 12, 31));
    expect(Care360ProfileDate.parse(' 2000-02-29 '), DateTime(2000, 2, 29));
  });
}
