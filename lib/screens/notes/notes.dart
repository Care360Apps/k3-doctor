import 'package:doctro/screens/appointment/clinical_notes_screen.dart';
import 'package:flutter/material.dart';

/// Former generic Notes drawer destination.
/// Clinical notes must belong to a real appointment and can only be accessed
/// after the backend verifies ownership by the approved treating doctor.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key, this.appointmentId});

  final int? appointmentId;

  @override
  Widget build(BuildContext context) {
    if (appointmentId != null) {
      return ClinicalNotesScreen(appointmentId: appointmentId!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Clinical notes')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 52, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Notes belong to a consultation',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Text(
                    'Open an appointment and select Clinical encounter notes. '
                    'Your drafts and finalized notes will be linked to that '
                    'specific patient encounter and protected by doctor access controls.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.event_note),
                    label: const Text('View appointments'),
                    onPressed: () => Navigator.pushNamed(
                      context, 'AppointmentHistoryScreen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
