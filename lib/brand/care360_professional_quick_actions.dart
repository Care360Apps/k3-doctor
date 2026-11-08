import 'package:flutter/material.dart';

enum Care360ProfessionalDestination {
  appointments,
  schedule,
  notes,
  messages,
}

/// Navigation only. Clinical content remains in its existing guarded screens.
class Care360ProfessionalQuickActions extends StatelessWidget {
  const Care360ProfessionalQuickActions({
    super.key,
    required this.onOpen,
  });

  final ValueChanged<Care360ProfessionalDestination> onOpen;

  static const _navy = Color(0xFF123E4D);
  static const _teal = Color(0xFF087D76);
  static const _entries = <_QuickAction>[
    _QuickAction(Care360ProfessionalDestination.appointments,
        'Appointments', Icons.calendar_month_outlined),
    _QuickAction(Care360ProfessionalDestination.schedule,
        'Schedule', Icons.access_time_rounded),
    _QuickAction(Care360ProfessionalDestination.notes,
        'Clinical notes', Icons.description_outlined),
    _QuickAction(Care360ProfessionalDestination.messages,
        'Messages', Icons.chat_bubble_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const Key('care360-plus-dashboard-hero'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [_navy, Color(0xFF12666A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARE360 PLUS',
                        style: TextStyle(
                          color: Color(0xFFBCECE5),
                          letterSpacing: 1.25,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Your care workspace',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your clinical tools, in one place.',
                        style: TextStyle(color: Color(0xFFE3F1EF), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/care360_clinician_team.webp',
                    key: const Key('care360-plus-dashboard-photo'),
                    width: 88,
                    height: 102,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 88,
                      height: 102,
                      child: Icon(Icons.medical_services_outlined,
                          color: Colors.white, size: 34),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: _navy,
            ),
          ),
          const SizedBox(height: 11),
          LayoutBuilder(builder: (context, size) {
            final columns = size.maxWidth >= 600 ? 4 : 2;
            final height = 98.0 + (textScale > 1 ? (textScale - 1) * 30 : 0);
            return GridView.builder(
              key: const Key('care360-plus-quick-actions'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _entries.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 11,
                mainAxisSpacing: 11,
                mainAxisExtent: height,
              ),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: Key('care360-plus-action-${entry.destination.name}'),
                    onTap: () => onOpen(entry.destination),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2EBEA)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(entry.icon, color: _teal, size: 28),
                          const Spacer(),
                          Text(
                            entry.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _navy, fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
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

class _QuickAction {
  const _QuickAction(this.destination, this.label, this.icon);

  final Care360ProfessionalDestination destination;
  final String label;
  final IconData icon;
}
