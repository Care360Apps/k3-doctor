import '../workforce/workforce_landing.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Future modules expose information only, never protected APIs or clinical data.
/// Releasing a module requires a working route and independent server permissions.
enum Care360PlannedModule { healthWallet, familyCare, workforce, training, organizations }

class Care360ServicesRoadmap extends StatelessWidget {
  const Care360ServicesRoadmap({super.key, this.professional = false});
  final bool professional;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(professional ? 'Professional services' : 'More Care360 services')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      ListTile(leading:const Icon(Icons.work_outline),title:const Text('Workforce & CNU training'),subtitle:const Text('Career profiles, verified hiring and course requests'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>const Care360WorkforceLanding()))),
      const Divider(),
      const Text('Upcoming services', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('These planned modules are not available in this release. Your existing care services remain in their current menus.'),
      if (!professional) ...[
        _entry(context, Care360PlannedModule.healthWallet, 'Health Wallet', 'A future place for your consultation records, prescriptions and reports with controlled sharing.', '1.2', Icons.folder_shared_outlined),
        _entry(context, Care360PlannedModule.familyCare, 'Family Care', 'Planned care for dependents with verified caregiver authority and appropriate consent.', '1.2', Icons.family_restroom),
      ],
      if (professional)
        _entry(context, Care360PlannedModule.organizations, 'Organization management', 'Planned tools for verified practices, teams and healthcare organizations.', '2.0', Icons.business_outlined),
      const Divider(),
      const Text('CNU information is available separately on its website. Opening it leaves Care360; no clinical records are included in the link. Course eligibility and accreditation must be checked with CNU.'),
      TextButton.icon(
        onPressed: () async {
          bool opened;
          try {
            opened = await launchUrl(Uri.https('www.cnumedical.com', '/'), mode: LaunchMode.externalApplication);
          } catch (_) { opened = false; }
          if (!opened && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open CNU. Please visit www.cnumedical.com.')));
          }
        },
        icon: const Icon(Icons.open_in_new),
        label: const Text('Visit CNU website'),
      ),
    ]),
  );

  Widget _entry(BuildContext context, Care360PlannedModule module, String title, String description, String version, IconData icon) =>
    Card(child: ListTile(
      key: ValueKey(module),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text('Coming soon · Planned V$version\n$description'),
      isThreeLine: true,
      // No route or API exists for unreleased modules. No client flag grants access.
    ));
}

