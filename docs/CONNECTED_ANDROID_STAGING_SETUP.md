# Care360 connected Android staging — setup and handoff

**Applies to:** Care360 Patient `com.cnu.patient.k3staging` and Care360 Plus
`com.cnu.doctor.k3staging`. Keep the Play Store packages
`com.cnu.patient` and `com.cnu.doctor` installed separately. This is not a
Play release or a production database migration.

## What is already in code

- The app uses `K3_API_BASE_URL`; without a configured server, offline APKs
  cannot log in. Never replace the offline test address with production to
  make a screenshot/demo pass.
- The manual Android workflow builds debug APKs only, with a separate Android
  package suffix `.k3staging` and visible `Care360 STAGING TEST` label.
- The build rejects insecure/nonstaging API endpoints, unexpected Firebase
  project IDs, accidental production package registration, and malformed
  configuration. It chooses the **exact staging Android Firebase client**,
  even when the project contains multiple client registrations.
- Passwords should not be stored in SharedPreferences. Never put credentials
  in screenshots, logs, artifacts or GitHub commits.

## Prerequisite 1 — isolated Laravel backend (infrastructure owner)

Provision a **dedicated non-production** Care360 Laravel API with a distinct
HTTPS hostname containing `staging`, `sandbox`, `test`, or `dev`.
Examples in this document are placeholders, **not existing deployments**.

- Use a separate database, separate access keys, isolated object storage,
  distinct messaging/payment sandbox credentials and synthetic accounts.
- Do **not** clone production patient records, passwords, payments, or medical
  attachments. Use the schema-only Care360 local fixture and synthetic seeder.
- Set `APP_ENV=staging` and `APP_DEBUG=false` on the backend. Restrict
  administrative access; configure TLS with a valid public certificate.
- Confirm the staging API is independently reachable at
  `https://YOUR-STAGING-HOST/api/`. An `/api/` base-path response may be
  HTTP 404 while the host is reachable; authentication endpoints must still
  be tested with *synthetic* credentials once deployed.
- Check OTP, user roles, signed-in appointment authorization, data isolation,
  request throttling, secure medical files and payment sandbox separation
  before offering the build to testers.

**No reachable staging API has been established by these code changes.**
Do not turn on the verified flag until the infrastructure owner has checked it.

## Prerequisite 2 — isolated Firebase project (Firebase owner)

Create/verify a Firebase project **different from production**. Register both
Android applications *in that staging project*:

| Android client | Required package ID |
| --- | --- |
| Patient staging | `com.cnu.patient.k3staging` |
| Plus staging | `com.cnu.doctor.k3staging` |

Download the relevant `google-services.json` for each application. It must
contain the corresponding Android package and refer to the staging project.
Do **not** provide a Firebase Admin service-account private key to the Android
build workflow; it requires the Android **client** configuration only.
Arrange authorized Firebase Auth users and strict Firestore/storage rules
for synthetic testers.

## Prerequisite 3 — GitHub configuration (repository maintainer)

Configure **both** `Care360Apps/k3-patient` and
`Care360Apps/k3-doctor` separately in
**Settings → Secrets and variables → Actions**.

| Kind | Name | Value |
| --- | --- | --- |
| Secret | `K3_STAGING_API_URL` | Verified staging HTTPS URL ending `/api/` |
| Secret | `K3_STAGING_ANDROID_FIREBASE_JSON_B64` | Base64 encoding of this application's *staging Android* `google-services.json` |
| Variable | `K3_STAGING_FIREBASE_PROJECT_ID` | Exact Firebase project ID from staging `project_info.project_id` |
| Variable | `K3_STAGING_API_VERIFIED` | Set to `true` **only after** backend/Firebase isolation is checked |

To base64 encode `google-services.json` on Windows PowerShell, run locally:
`[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\\PATH\\google-services.json"))`
and paste the result into the GitHub **secret**, never into chat or a commit.
No service-account private keys should be used in the mobile repository.

## Build and test

After the staging settings are approved and these changes are merged:

1. Open **Actions → K3 opt-in staging builds (never production signed)** in
   the relevant repository.
2. Select **Run workflow → main → platform: android**.
3. Inspect validation and Flutter build logs; do not download a failed build.
4. Download the `k3-staging-android-debug-apk` Actions artifact, and install
   on a test Android device. It should appear separately as
   **Care360 STAGING TEST**.
5. Test onboarding → register → OTP → sign-in → dashboard → role checks →
   appointments → logout; repeat with no network, denied location and a slow
   connection. Use **synthetic accounts only**.
6. Document observed HTTP/auth response codes (redacted), screenshots without
   patient data, device version, and test results.
7. Only after those checks can the existing Play Store release workflow be
   considered. It needs the current Play Console upload-key certificate
   fingerprint and higher versionCode. iOS is intentionally postponed.

## Release stop conditions

- Backend or Firebase staging missing, or a production endpoint is referenced.
- User/password errors are observed on a synthetic, intentionally disconnected
  APK (it is not a real login test).
- Upload signing key ownership or current Play Store versionCode is unknown.
- Healthcare privacy/authorization, OTP, file access or payment flows remain
  unverified against the **actual connected backend**.

**Important:** Passing GitHub source tests or compiling an offline APK does not
establish that any user can log in.
