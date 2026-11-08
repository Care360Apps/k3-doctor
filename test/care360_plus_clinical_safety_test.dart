import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/security/care360_prescription_validation.dart';
import 'package:doctro/security/care360_agora_join_policy.dart';

void main() {
  final validMedicine = <String, dynamic>{
    'medicine': 'Fictional medicine A',
    'days': '5',
    'morning': 1,
    'afternoon': 0,
    'night': 1,
  };

  test('Prescription rejects invalid duration, missing doses and empty drug names', () {
    expect(Care360PrescriptionValidation.validate([validMedicine]), isNull);
    expect(Care360PrescriptionValidation.validate([]), isNotNull);
    expect(Care360PrescriptionValidation.validate([
      {...validMedicine, 'days': '0'}
    ]), isNotNull);
    expect(Care360PrescriptionValidation.validate([
      {...validMedicine, 'days': '-3'}
    ]), isNotNull);
    expect(Care360PrescriptionValidation.validate([
      {...validMedicine, 'days': '366'}
    ]), isNotNull);
    expect(Care360PrescriptionValidation.validate([
      {...validMedicine, 'medicine': '   '}
    ]), isNotNull);
    expect(Care360PrescriptionValidation.validate([
      {...validMedicine, 'morning': 0, 'afternoon': 0, 'night': 0}
    ]), isNotNull);
    expect(Care360PrescriptionValidation.validate([
      {...validMedicine, 'morning': 'unknown'}
    ]), isNotNull);
  });

  test('Agora requires authenticated clinician, real token, channel and target', () {
    bool check({String? session = 'test-session', String? rtc = 'test-rtc',
      String? channel = 'test-session-channel', String? id = 'test-agora-app',
      bool outgoing = true, int? recipient = 11}) =>
      Care360AgoraJoinPolicy.canJoin(
        sessionToken: session, agoraToken: rtc, channelId: channel,
        appId: id, outgoing: outgoing, remoteUserId: recipient);
    expect(check(), isTrue);
    expect(check(session: 'N_A'), isFalse);
    expect(check(session: ''), isFalse);
    expect(check(rtc: ''), isFalse);
    expect(check(rtc: 'null'), isFalse);
    expect(check(channel: ''), isFalse);
    expect(check(id: ''), isFalse);
    expect(check(recipient: null), isFalse);
    expect(check(outgoing: false, recipient: null), isTrue);
  });

  test('Source is fail-closed before upload, notes and channel joining', () {
    final upload = File('lib/pdf_creation/report_pdf.dart').readAsStringSync();
    final notes = File('lib/screens/appointment/clinical_notes_screen.dart')
        .readAsStringSync();
    final call = File('lib/screens/videoCall/video_Call.dart').readAsStringSync();
    expect(upload, contains('Care360PrescriptionValidation.validate(pdfData)'));
    expect(upload, contains('Care360ProfessionalRole.canCreatePrescription('));
    expect(upload, contains('request.followRedirects = false;'));
    expect(notes, contains('_hasDoctorAccess'));
    expect(call, contains('Care360AgoraJoinPolicy.canJoin('));
    expect(call, contains('await engine.joinChannel('));
    expect(call, contains('await engine.muteLocalVideoStream(nextMuted)'));
    expect(call, contains('Switch to audio-only'));
    final signIn = File('lib/screens/auth/SignIn.dart').readAsStringSync();
    final firebase = File('lib/chat/providers/auth_provider.dart')
        .readAsStringSync();
    final preferences = File('lib/constant/preferences.dart').readAsStringSync();
    expect(signIn, isNot(contains('authProvider.handleSignIn(email:')));
    final loginSuccess = signIn.indexOf('if (response.success == true)');
    final identityWrite = signIn.indexOf(
        'await SharedPreferenceHelper.setString(Preferences.user_email, email.text)');
    expect(loginSuccess, greaterThanOrEqualTo(0));
    expect(identityWrite, greaterThan(loginSuccess));
    expect(signIn, contains(
        'await SharedPreferenceHelper.setString(Preferences.user_role, _loginAsProvider'));
    expect(signIn, contains(
        'await SharedPreferenceHelper.setBoolean(Preferences.is_logged_in, true)'));
    expect(preferences, contains('await _secureStorage.write(key: key, value: legacy);'));
    expect(firebase, isNot(contains('createUserWithEmailAndPassword(')));
    expect(firebase, isNot(contains('signInWithEmailAndPassword(')));
    expect(preferences, contains('await FirebaseAuth.instance.signOut();'));
    final patientDetails = File('lib/screens/home page/patient_information.dart')
        .readAsStringSync();
    final stateStart = patientDetails.indexOf(
        'class _patientDetailsScreenState extends State<patientDetailsScreen>');
    final medicineList = patientDetails.indexOf(
        'final List<Map<String, dynamic>> listOfMedicine = [];');
    expect(medicineList, greaterThan(stateStart));
    expect(patientDetails, contains('class DataTableWidget extends StatelessWidget'));
    expect(patientDetails, contains('medicines: listOfMedicine'));
    expect(patientDetails, contains('onDelete: (medicine)'));
    expect(call, isNot(contains("token: joinToken == '' ? ''")));
  });
}
