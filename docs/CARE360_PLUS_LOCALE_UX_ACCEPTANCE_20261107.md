# Care360 Plus — locale/healthcare UI and clinical review
Date: 2026-11-07
Status: Draft source changes only, NOT a verified release APK.

## Intent
This branch is stacked on professional Nearby Care opt-in shifts PR #27. It applies the same confirmed Patient language-selection protections to Care360 Plus for both doctor and provider roles: use the Navigator's overlay, no icon Tooltip from MaterialApp.builder, wait for bottom-sheet/pop animation completion before locale rebuild, prevent rapid duplicate taps, and fall back to English framework widgets when Flutter has no Material/Widgets/Cupertino built-in translations for Hausa/Igbo/Yoruba. The user's selected locale is retained in the Care360 translation delegate. It also standardizes professional UI color tokens to clinical navy/teal without adding Patient-sponsored placements.

## UI expectations
- Modern, accessible healthcare navy/teal and restrained surfaces. Real Nigerian/African-clinician imagery must have appropriate reuse rights, visible consent and no implied professional endorsements.
- Distinct **Doctor** vs **Provider** labels and role navigation. Doctors: teleconsultation, clinical notes, prescriptions, history. Providers: approved virtual and/or home visits within permissions, explicit on-duty opt-in; no unauthorized doctor-only prescriptions.
- No MindCheck patient integration or sponsored advertisements on clinical consultations, medical history, prescriptions, emergency or payment screens.
- Each language selection must remain usable on login, dashboard, settings and all high-traffic routes, including after relaunch. Switching must not discard unfinished notes, reset sessions or change backend clinical data.

## Testing
- Run Flutter 3.38.3 test/care360_plus_language_switch_regression_test.dart after dependency setup.
- On BlueStacks, switch English ↔ Hausa ↔ Igbo ↔ Yoruba ↔ French through both floating control and Settings; navigate to appointments, notes and profile between switches. Check no Flutter red screen, overflow or stale overlay.
- Test signed-in **Doctor** and **Provider** synthetic roles; verify on-duty opt-in, visibility, home visits restrictions, clinical notes, e-scripts, calls and logout after switching locales.
- Keep English fallback until independently reviewed clinical translation sets are available. The current Plus locale JSON count is ~38/338 per additional language, NOT complete translation.
- Verify secure backend PR #28 (stacked on #27), payment and public-file security; avoid linking a Plus Android test app to Patient APK or production Firebase.
- Final developer package must include full private Plus source commit, tests, backend migration instructions and staging evidence, with no credentials or personal records.

The release owner has not yet approved or demonstrated this version in a real connected Android build.
