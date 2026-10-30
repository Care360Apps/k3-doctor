# K3 Doctor — private development baseline

Source: original cnu_doctor.zip dated 13 October 2026; extracted with .git history, local generated caches, Firebase app config and signing files excluded. Files have not been uploaded to GitHub or deployed.

## Build safety
- **Do not run the original `test/base_url_test.dart` in CI**: it makes a real HTTP call to the configured API.
- `tools/k3_preflight.py` performs offline internal-import and sensitive-file checks.
- `quality.yml` runs Flutter static analysis and the new offline smoke test. Failures in legacy source need triage; they are not automatically proof of the new setup failing.
- `staging-build.yml` is **manual, opt-in and blocked by `K3_STAGING_API_VERIFIED=true`**. Do not set this flag until every API client is confirmed to use staging when built with `--dart-define=K3_BUILD_ENV=staging`.
- Configure separate Firebase staging apps and set `K3_STAGING_ANDROID_FIREBASE_JSON_B64` / `K3_STAGING_IOS_FIREBASE_PLIST_B64` in GitHub Secrets. Do not use production Firebase config for test builds.
- Requires Flutter 3.38.3 with Dart 3.10.x, Android SDK with Java 17, and macOS/Xcode for iOS simulator builds.
- Prior to an Android Play update, verify package IDs, release version code, and Play signing/upload keystore. Do not commit credentials.

## Delivery status
This ZIP is a **source handoff, not a tested APK/IPA**. Existing source may still need dependency and compiler repairs after Flutter tooling runs.

## Staging isolation changes in this copy
- Both `Apis.baseUrl` and `DefaultFirebaseOptions.currentPlatform` have been changed to require compile-time environment configuration rather than use production defaults.
- An explicit `K3_STAGING_API_URL` GitHub Actions secret must point to the isolated HTTPS staging API ending `/api/`.
- Set `K3_STAGING_API_VERIFIED=true` only after auditing **all** network calls and confirming no production endpoints, payments, messages, or patient records can be reached by test builds.
- The `tools/k3_staging_config.py` helper extracts only staging Firebase app configuration from GitHub Actions secrets; it does not print its contents.
- Check and update `lib/**` remaining hardcoded third-party endpoints before any emulator test.
- iOS Firebase configuration in the original archive was Android-only Dart code; this source uses separate iOS build settings but has not been compiled or tested.

- Original generated Retrofit `.g.dart` had an embedded API URL. The prepared source and CI `tools/k3_rewrite_generated_url.py` replace that with `Apis.baseUrl` after every code-generation run.
- The original test file includes an HTTP integration test; it is excluded from offline CI.


## 28 October 2026 — notification safety hardening

The original mobile source used the retired Firebase legacy HTTP endpoint, and the Patient app included a server credential in its Dart source. The prepared source now removes client-side FCM server access and uses *opt-in* calls to existing Laravel `/api/send_message_to_doctor_notification` or `/api/send_message_to_patient_notification` endpoints. It sends only generic notification text; chat messages remain in Firestore.

**Important:** Backend push remains disabled by default (`K3_BACKEND_PUSH_ENABLED=false`). Before enabling, test the current Laravel OneSignal configuration, confirm recipient OneSignal subscription IDs match Laravel database records, validate that only legitimate participants can cause chat notifications, apply rate limits, and run live-device staging acceptance checks. Do not enable on production without these. The original exposed server credential must be rotated/revoked with the Firebase owner; source removal does not revoke it.

The Patient app's missing Gradle wrapper was restored from the supplied Doctor project's wrapper because both projects request Gradle 8.14. The wrapper JAR still requires trustworthy upstream checksum verification before CI execution.
