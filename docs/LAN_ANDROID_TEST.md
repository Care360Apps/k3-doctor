# Care360 local LAN Android debug build

This opt-in GitHub Actions workflow compiles the real Flutter application for
**BlueStacks on the same trusted private network as the local Laravel backend**.
It does not deploy the backend, publish to Play Store, sign a release, or
connect a GitHub runner to the user's private laptop.

## Before dispatch

1. Run the local Laravel backend with
   php artisan serve --host=0.0.0.0 --port=8000; ensure MySQL stays running.
2. From BlueStacks' browser confirm
   http://192.168.100.38:8000 (or the laptop's current IPv4) loads.
3. In **each app repository**, configure:
   - GitHub Actions secret K3_STAGING_ANDROID_FIREBASE_JSON_B64:
     base64 of the *isolated staging* Android google-services.json, not
     a Firebase service-account credential.
   - GitHub Actions variable K3_STAGING_FIREBASE_PROJECT_ID:
     approved staging Firebase project ID.
4. The staging Firebase project must register the corresponding isolated
   Android application:
   - Patient: com.cnu.patient.k3staging
   - Plus: com.cnu.doctor.k3staging
   The JSON must contain the matching package and must **not** include the
   production com.cnu.patient or com.cnu.doctor registration.
5. The local Laravel environment's Firebase service-account/project must be
   compatible with the test app if testing custom Firebase authentication.
   Successful Laravel API login alone does not establish this.

## Trigger only when ready

After merging the reviewed workflow, open **Actions** in the appropriate
GitHub repository and choose **LAN Android debug** -> **Run workflow**.
Enter your laptop's current **private IPv4**, e.g. 192.168.100.38.
The workflow refuses public and loopback IPs and uses **HTTP on port 8000**
only in the disposable Android **debug** build. It produces a universal
Flutter debug APK artifact plus a SHA256 checksum and short README.

The APK embeds http://<selected-private-ip>:8000/api/. It will not work
outside the laptop's private network or when that IPv4 changes. GitHub
cannot reach/test the user's LAN; the user must install and verify in
BlueStacks.

The resulting app is labeled **LAN TEST** and has the .k3staging package
suffix, keeping production app IDs and production signing untouched.
It might conflict with a previously installed staging build signed with a
different key; uninstall the *staging* version only if needed.

## Security and acceptance

- Use **only fictional test accounts** and trusted private Wi-Fi.
- Do **not** use real patient data, live payments, or clinical testing.
- HTTP credentials are unencrypted on the LAN. Never use this build on
  public/hotel networks; production requires a verified HTTPS API.
- Never publish this APK, commit google-services.json, or share Laravel
  Passport private keys, service-account credentials or client secrets.
- Verify Patient, Doctor and Provider login, token usage, API endpoints,
  Firebase compatibility, and post-login navigation on BlueStacks.
- GitHub Actions success proves compilation/artifact creation, **not**
  functional Android sign-in.

This manual workflow is distinct from offline synthetic checks and from the
existing HTTPS staging and release workflows.
