# Care360 V1 production preparation — 14 November 2026

This integrated source candidate is for coordinated review across Patient, Plus and backend. It is not a deployment or store approval. Older stacked pull requests must not be merged independently merely because this candidate is available.

## Implementation and evidence

The source handoff includes the preserved healthcare workflows and new Workforce recruitment, private documents, reviewer-controlled verification, recruiter authority, application/interview/offer flow, administrator-managed CNU cohorts, training requests/completion/certificates, privacy export/reviewed erasure and recovery. Backend permissions remain separate from UI flags and clinical/employment identities remain separated.

Local validation: Patient 131 Flutter tests, Plus 92 Flutter tests, backend 86 tests/635 assertions; 307 PHP syntax checks and 23 offline source/security contracts. Flutter analyzers report no errors, with existing warning/info debt of 294 Patient and 128 Plus. Final installed Android staging APK hashes were verified and relevant read-only screens previewed in BlueStacks. Full live end-to-end and real-device acceptance remain outstanding. iOS has no current build/archive/device evidence.

The mobile CI workflow now selects all offline test files except the intentionally excluded live base_url_test.dart. Plus now has a production Firebase client configuration generator with four offline tests. Existing Android release gates and the new config helper passed 15 selected release tests; repaired workflow YAML was parsed successfully. These are local checks, not claims of successful GitHub Actions.

## Developer-provided production setup

Supply an approved public HTTPS API, production database/storage/mail/OTP setup, rotated service credentials, Firebase clients/server identity/rules, restricted Maps keys/billing, Agora and payment configuration through private deployment mechanisms. Do not commit private keys, signing material, passwords or runtime config.

Maintain existing com.cnu.patient / com.cnu.doctor application identities and existing store signing ownership. Obtain each last uploaded build/version code from the consoles before selecting a higher one. Configure Android upload signing privately and build signed release AABs. For iOS use an authorized Mac, current required Xcode/SDK, Apple team, provisioning, iPhone and TestFlight. Do not substitute Android debug APKs for release artifacts.

Approve and publish recruitment/training privacy notices, retention/deletion procedures, CNU course/cohort information and reviewer responsibilities. Real registrations, new workflows and reviewed deletion remain off until their deployment flags and acceptance requirements are met. CNU's learning website remains separate; progress/completion is administrator verified, with no invented accreditation or automatic LMS synchronization.

Run healthcare, recruitment, training, payment and failure journeys on the coordinated production-configured staging release. Complete medical-file cutover/security assessment, account deletion/session/Firebase acceptance and operational backup/rollback checks. Validate current store privacy, Data safety/health declarations, support/deletion URLs, reviewer access and screenshots against actual deployed behavior.

The developer will provide production setup. No production deployment or public store publishing has been performed. Final public release requires owner approval after evidence is reviewed.
