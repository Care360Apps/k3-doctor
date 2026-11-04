import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/brand/care360_professional_role.dart';

void main() {
  test('doctor permits video, not home visit; doctor-only prescription controls', () {
    expect(Care360ProfessionalRole.isProvider('doctor'), isFalse);
    expect(Care360ProfessionalRole.canOfferHomeVisit('doctor'), isFalse);
    expect(Care360ProfessionalRole.canCreatePrescription('doctor'), isTrue);
  });

  test('provider permits home visits and virtual service, but not prescriptions', () {
    expect(Care360ProfessionalRole.isProvider('provider'), isTrue);
    expect(Care360ProfessionalRole.canOfferHomeVisit('provider'), isTrue);
    expect(Care360ProfessionalRole.canCreatePrescription('provider'), isFalse);
    expect(Care360ProfessionalRole.canCreatePrescription(null), isFalse);
  });

  test('patient details profile guards prescription actions by role', () {
    final patient = File('lib/screens/home page/patient_information.dart').readAsStringSync();
    expect(patient.contains('if (_canPrescribe)'), isTrue);
    expect(patient.contains('if (!_canPrescribe)'), isTrue);
    final profile = File('lib/screens/profile/profile.dart').readAsStringSync();
    expect(profile.contains('if (_isProvider)'), isTrue);
    expect(profile.contains('"_offers_home_visit"'), isFalse);
  });
}
