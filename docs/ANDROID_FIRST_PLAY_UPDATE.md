# Android-first Google Play upgrade — release checklist (1 November 2026)

This work targets the **existing** listings, not new apps:

- Care360 Patient: `com.cnu.patient`
- Care360 Plus: `com.cnu.doctor`

The redesign branches include Nigerian/African imagery, shared Care360 logo with the correct product label, and the linked "A product of CNU Medical Institute" credit at https://www.cnumedical.com/. Real sign-in navigation is retained, not replaced by an offline preview.

## Release sequence

1. Finish code review, Flutter analyzer/widget tests and the Android synthetic build. A synthetic APK **cannot** authenticate and is not suitable for end users.
2. Bring up an isolated Care360 Laravel API with schema-only fixtures and **synthetic** patient/doctor/provider accounts; configure separate Firebase staging apps. Confirm both actual Flutter clients use only this staging API/Firebase project.
3. Test Android real-app flows using synthetic records: onboarding, registration, OTP, login, logout, doctor/provider role separation, dashboard, appointments, and failed-network/retry behavior. Include small screens, low bandwidth, denied location permission, and TalkBack.
4. Before production release, verify the live backend's TLS chain, account isolation, secure file access, payment verification and authorization; restore/verify the current Play upload key and Google Play Console control.
5. Confirm the highest **already uploaded** versionCode in Play Console for each app. Build a **signed Android App Bundle (AAB)** with the same package ID and a higher versionCode. Verify that Flutter's production environment includes the verified HTTPS `K3_API_BASE_URL` ending in `/api/` and correct production Firebase app configuration. Never publish the placeholder `127.0.0.1:9` API.
6. Run `python3 tools/k3_android_release_preflight.py` with required environment variables `K3_BUILD_ENV=production`, `K3_API_BASE_URL`, `K3_PLAY_LATEST_VERSION_CODE`, and `K3_ANDROID_NEXT_VERSION_CODE` set privately. The script fails if required upload signing credentials, keystore file, package ID, URL or version are missing/invalid. **It does not verify keystore fingerprint equality or execute a build**, so compare the upload certificate in Play Console separately.
7. Upload the signed AAB **first to Google Play internal testing**, run installed-app smoke tests with volunteer synthetic accounts and inspect crash/ANR results. Only then promote a staged rollout. Do not change the account, listing ID, signing key or release track without authorized console access.

## Android release blockers (not solved by a passing synthetic build)

- Staging/production API and Firebase configuration still need successful real-app tests.
- Upload signing-keystore custody and app ownership with the existing Play Console publisher must be confirmed.
- VersionCode must come from Play Console, not inferred from `pubspec.yaml` alone.
- Healthcare data, payment, OTP, document access and user-account deletion safety need integration verification.
- The older, overlapping Patient premium-design PR should be reconciled **after** the lean Android-first release candidate; do not merge conflicting onboarding implementations blindly.

No production data or credentials should be uploaded to GitHub. Android is first; iOS changes are outside this release.
