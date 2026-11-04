import 'package:doctro/model/doctor_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appointment clinical notes preserve finalization state', () {
    final response = DoctorNotesResponse.fromJson({
      'success': true,
      'data': [
        {
          'id': 9,
          'doctor_id': 1,
          'user_id': 2,
          'appointment_id': 10,
          'title': 'Follow-up',
          'body': 'Synthetic notes only',
          'status': 'final',
          'finalized_at': '2026-11-04T09:00:00Z',
        },
      ],
    });
    expect(response.success, isTrue);
    final note = response.data!.single;
    expect(note.appointmentId, 10);
    expect(note.status, 'final');
    expect(note.finalizedAt, isNotNull);
    expect(note.toJson()['status'], 'final');
  });

  test('old note payloads without finalization metadata remain readable', () {
    final note = DoctorNote.fromJson({
      'id': 1,
      'title': 'Draft',
      'body': 'Synthetic draft',
    });
    expect(note.status, isNull);
    expect(note.finalizedAt, isNull);
  });
}
