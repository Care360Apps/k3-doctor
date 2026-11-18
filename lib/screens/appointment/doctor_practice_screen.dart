import 'clinical_encounter_register.dart';
import 'critical_results_screen.dart';
import 'package:flutter/material.dart';
import '../../brand/care360_professional_role.dart';
import '../../constant/preferences.dart';
import '../../constant/prefConstatnt.dart';
import '../setting/professional_availability.dart';

/// Doctor-only entry point into the existing practice and appointment workflows.
class DoctorPracticeScreen extends StatelessWidget {
  const DoctorPracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctor = Care360ProfessionalRole.canCreatePrescription(
      SharedPreferenceHelper.getString(Preferences.user_role),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('My medical practice')),
      body: !doctor
          ? const Center(child: Text('This workspace is available to doctors.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Set up your practice',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep your qualifications, services, consultation fees and practice details current. Set appointment times before accepting bookings.',
                ),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Professional profile and practice'),
                  subtitle: const Text(
                    'Qualifications, expertise, services and fees',
                  ),
                  onTap: () => Navigator.pushNamed(context, 'profile'),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Consultation schedule'),
                  subtitle: const Text('Set the times patients can book'),
                  onTap: () => Navigator.pushNamed(context, 'Schedule Timings'),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Availability and service area'),
                  subtitle: const Text(
                    'Publish your current availability with your consent',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfessionalAvailabilityScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.priority_high),
                  title: const Text('Critical result acknowledgements'),
                  subtitle: const Text(
                    'Review manually flagged results and record follow-up',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CriticalResultsScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_shared_outlined),
                  title: const Text('Clinical encounter register'),
                  subtitle: const Text(
                    'Search assigned appointments and open allergies, vitals and requests',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ClinicalEncounterRegisterScreen(),
                    ),
                  ),
                ),
                const Divider(),
                const Text(
                  'Manage a consultation',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Open the correct appointment, confirm the patient, review their history, record your findings, then prepare the prescription and follow-up plan. Clinical notes belong to an appointment.',
                ),
                ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: const Text('Appointments and clinical records'),
                  subtitle: const Text(
                    'Patient history, consultation notes and prescriptions',
                  ),
                  onTap: () =>
                      Navigator.pushNamed(context, 'AppointmentHistoryScreen'),
                ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Patient messages'),
                  subtitle: const Text('Open existing care conversations'),
                  onTap: () => Navigator.pushNamed(context, 'ChatHome'),
                ),
              ],
            ),
    );
  }
}
