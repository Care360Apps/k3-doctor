import 'package:flutter/material.dart';

/// Quick professional workflows inside the existing authenticated Doctor and
/// Provider dashboard. This widget never fetches patient details, bypasses
/// role approval, or changes clinical endpoint permissions.
class Care360ProfessionalQuickActions extends StatelessWidget {
  const Care360ProfessionalQuickActions({
    super.key,
    required this.onAppointments,
    required this.onAvailability,
    required this.onNotes,
    required this.onMessages,
  });

  final VoidCallback onAppointments;
  final VoidCallback onAvailability;
  final VoidCallback onNotes;
  final VoidCallback onMessages;

  static const _navy = Color(0xFF123E4D);
  static const _teal = Color(0xFF087D76);

  @override
  Widget build(BuildContext context) {
    final actions = <_ProfessionalAction>[
      _ProfessionalAction('Appointments', Icons.event_available_outlined, onAppointments),
      _ProfessionalAction('Availability', Icons.calendar_month_outlined, onAvailability),
      _ProfessionalAction('Clinical notes', Icons.note_alt_outlined, onNotes),
      _ProfessionalAction('Messages', Icons.chat_bubble_outline_rounded, onMessages),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your practice, organized',
            key: Key('care360-plus-quick-actions-heading'),
            style: TextStyle(
              color: _navy, fontWeight: FontWeight.w800,
              fontSize: 19, height: 1.2),
          ),
          const SizedBox(height: 4),
          const Text('Fast access to everyday clinical workflows.',
            style: TextStyle(color: Color(0xFF526B72), fontSize: 13)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            return GridView.builder(
              key: const Key('care360-plus-quick-actions'),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: actions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 92,
              ),
              itemBuilder: (context, i) {
                final action = actions[i];
                return Semantics(
                  button: true,
                  label: 'Open ${action.title}',
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFFDCE8E5)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      key: Key('care360-plus-${i}'),
                      onTap: action.open,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          Container(
                            width: 39,
                            height: 39,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(action.icon, color: _teal, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(action.title,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _navy, fontWeight: FontWeight.w700,
                                fontSize: 12.5, height: 1.15,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _ProfessionalAction {
  const _ProfessionalAction(this.title, this.icon, this.open);
  final String title;
  final IconData icon;
  final VoidCallback open;
}
