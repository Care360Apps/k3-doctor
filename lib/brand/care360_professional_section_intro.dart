import 'package:flutter/material.dart';

/// Static visual context for protected professional tools.
/// This displays no patient identity, notes, diagnoses or login state.
class Care360ProfessionalSectionIntro extends StatelessWidget {
  const Care360ProfessionalSectionIntro({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Semantics(
        container: true,
        label: '$title. $description',
        child: ExcludeSemantics(
          child: Container(
            key: const Key('care360-plus-section-intro'),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F1),
              border: Border.all(color: const Color(0xFFD5E8E2)),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12,
            ),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: const Color(0xFF087D76)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF123E4D),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF506B70),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
