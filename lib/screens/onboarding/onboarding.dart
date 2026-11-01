import 'package:flutter/material.dart';
import '../../brand/care360_entry.dart';
import '../../constant/prefConstatnt.dart';
import '../../constant/preferences.dart';
import '../auth/SignIn.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => Care360Welcome(
    professional: true,
    onComplete: () async {
      await SharedPreferenceHelper.setBoolean(Preferences.onboarding_seen, true);
      if (!context.mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SignIn()));
    },
  );
}
