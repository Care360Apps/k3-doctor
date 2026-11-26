# Care360 Windows-first testing policy

**Applies to:** Care360 Patient (`k3-patient`), Care360 Plus (`k3-doctor`), and Laravel backend (`k3-backend`).

## Routine checks on Windows

The owner runs a local PowerShell test kit from a workspace containing the three private repositories:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\Run-Care360Tests.ps1 -Target All -Mode Quick -CloneMissing
.\Run-Care360Tests.ps1 -Target All -Mode Full
```

Recommended prerequisites: Git for Windows with an authenticated private-repo account, Python 3, PHP 8.2+ from XAMPP, Composer 2, Flutter 3.38.3 (app-compatible SDK), Dart, Java 17 and Android Studio for native testing. Use `flutter doctor -v` to verify local native tools.

**Local check requirements:** source preflight and security contracts; PHP lint and offline contracts; Flutter `pub get --enforce-lockfile`, Retrofit generation, `flutter analyze`, and repository widget tests. All must pass with synthetic data. Never run real patient records, actual medicine payments, or production API/Firebase credentials in routine local tests. Git repos should stay clean apart from reviewed generated sources.

The Windows kit is distributed directly by the project team. It does not register a self-hosted Actions runner.

## Hosted runners are reserved for manually approved release checks

The hosted `quality.yml` workflows use **manual `workflow_dispatch`** instead of automatic PR/main branch triggers. Patient's expensive `offline-android-apk.yml` and both apps' LAN debug builds are also manually triggered. iOS simulator and signed release workflows already require opt-in.

This reduces unnecessary GitHub-hosted minutes but changes review requirements:

1. **Before merging changes affecting real users**, the reviewer must inspect the diff and confirm passing local checks for the exact commit; don't rely on a skipped/missing GitHub check as proof.
2. For important integration/release candidates, manually run the GitHub-hosted quality workflow on the reviewed branch and confirm it **succeeds**.
3. Before production, independently test staging backend migrations, clinical permissions, pharmacy payment/refund/stock flows, synthetic patient/doctor/provider consultation journeys, mobile accessibility, backups and rollback. A source-only CI pass is not sufficient.
4. **Never bypass existing branch protection.** If GitHub reports a required check that no longer runs automatically, a repository administrator must review the intended rules and arrange a replacement gate; do not turn off protections merely to merge.
5. A GitHub merge does not deploy Laravel to Namecheap and does not publish APKs to app stores.

## Source and deployment isolation

- Use only synthetic fixtures for local code tests.
- Android app builds require an isolated `.k3sandbox` or `.k3staging` package ID and approved Firebase/API settings in a disposable checkout. Existing CI fixture preparation modifies Gradle/manifest files; **do not run it in an active production checkout**.
- Only trusted project maintainers may run tests from private branches. Do not register this personal Windows laptop as a general-purpose runner for untrusted PRs.
- Do not commit or share `.env`, database dumps, keystores, Firestore service accounts, bearer tokens or patient information.

## Existing pending work

- Patient rotating MindCheck/sponsored carousel: `Care360Apps/k3-patient#24`
- Backend campaign administration: `Care360Apps/k3-backend#18`
- Full Care360 UI/UX release programme: `Care360Apps/k3-patient#25`

These PRs remain subject to local + independent release checks; this policy does not implicitly approve their merge or production deployment.
