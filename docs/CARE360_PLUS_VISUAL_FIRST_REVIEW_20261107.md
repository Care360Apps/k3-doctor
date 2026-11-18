# Care360 Plus — visual-first startup and multilingual onboarding

Date: 2026-11-07  
Status: DRAFT source, **no new APK compiled or visually accepted**.

## Implemented
- First-time Doctor/Provider installation: native splash → Care360 Plus first-language selector (English/Hausa/Igbo/Yoruba/French) → original three-screen professional onboarding → original professional sign-in and account type selection. Approved logo and existing African clinical photographs are reused.
- Returning signed-in Doctors/Providers continue directly to `loginHome`; existing onboarded users continue to SignIn. Existing appointment schedules, Notes, patient details, provider categories, wallet/payment, calls and clinical routes remain untouched.
- Shared entry/auth shell now matches Patient's medical navy #123E4D, teal #087D76, neutral #F5F8F7, rounded photo and accessible buttons.
- Language preference is fully persisted before route change, with safe English fallback for missing localization keys; the existing Flutter system translation fallback remains for Nigerian languages. **This does not complete medically accurate Hausa, Igbo, Yoruba and French translation.**
- Existing official `assets/images/care360_master_logo.webp` rather than unapproved artificial icon. `tools/k3_prepare_launch_brand.py` converts this master for `flutter_native_splash` when ready to build. Master is only 160x160px and a high-resolution official export is recommended before final signing.
- Test definitions in `test/care360_plus_first_launch_visual_test.dart` cover first screen, five languages, real art, onboarding and professional routes.

## Not changed
- Doctor/Provider registration policy, professional credentials, clinical notes, e-prescriptions, chat/calls, payments, Firebase identity, staging/production secrets, permissions, server endpoints.
- No Care360 Workforce employer signup or Patient-only MindCheck entry in Plus.
- No final APK or AAB has been built, and no original Play Store signing configuration was touched.

## QA needed
- Run `python3 tools/k3_prepare_launch_brand.py`, `flutter pub get`, `dart run flutter_native_splash:create`, then `flutter test test/care360_plus_first_launch_visual_test.dart test/k3_entry_brand_test.dart test/care360_plus_language_switch_regression_test.dart` in the private Plus source checkout using Flutter 3.38.3.
- Private Plus CI cannot currently certify success; public isolated runner requires the separate read-only `CARE360_DOCTOR_SOURCE_READ_TOKEN` for `Care360Apps/k3-doctor`. Do not expose token in chat.
- Android/iOS small/large screen and accessibility screenshot review, then one joined Doctor+Provider staging APK check with fictional identities.
- Clinical and backend security release gates still open; do not deploy this UI review as a production release.

**Dependency:** this branch stacks on Plus #28 language safety review and is separate from Patient #41. The user will approve visuals before the single final review APK.
