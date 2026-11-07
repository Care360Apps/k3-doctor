import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('professional availability requires explicit consent, approved backend and expires', () {
    final ui = File('lib/screens/setting/professional_availability.dart')
        .readAsStringSync();
    final settings = File('lib/screens/setting/Setting.dart').readAsStringSync();
    final home = File('lib/screens/home page/login_home.dart')
        .readAsStringSync();
    expect(home, contains("Key('professional-availability-shortcut')"));
    expect(home, contains('ProfessionalAvailabilityScreen()'));
    expect(settings, contains('ProfessionalAvailabilityScreen()'));
    expect(ui, contains("Key('public-service-point-consent')"));
    expect(ui, contains('!_locationConsent'));
    expect(ui, contains("'confirm_public_location': 1"));
    expect(ui, contains("'minutes_on_duty': _durationMinutes"));
    expect(ui, contains("'service_radius_km': _radiusKm"));
    expect(ui, contains("'accepting_requests': accepting ? 1 : 0"));
    expect(ui, contains("if (!_backendReady || _saving) return"));
    expect(ui, contains("Key('go-offline-nearby-care')"));
    expect(ui, contains("Key('go-online-nearby-care')"));
    expect(ui, contains('This never enables continuous live GPS tracking.'));
    expect(ui, isNot(contains('Permission.location.request()')));
    expect(ui, isNot(contains('getCurrentPosition(')));
    expect(ui, isNot(contains('badCertificateCallback')));
    expect(ui, isNot(contains('print(')));
  });
}
