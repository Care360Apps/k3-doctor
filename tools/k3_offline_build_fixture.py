#!/usr/bin/env python3
"""Prepare synthetic-only Android CI compile configuration, never real K3 services.

Generates throwaway Firebase metadata and a .invalid API endpoint in the
temporary runner checkout only. Debug APK receives a distinct package ID.
Never use such builds for clinical/user acceptance or payments.
"""
import json
import os
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
gradle = root / 'android/app/build.gradle'
text = gradle.read_text()
match = re.search(r'(?m)^\s*applicationId\s+["\'](com\.cnu\.(?:patient|doctor))["\']', text)
if not match:
    sys.exit('Expected K3 Android applicationId missing or changed')
package = match.group(1)
if 'applicationIdSuffix' in text:
    sys.exit('Existing app ID suffix present: inspect build setup manually')
needle = '    buildTypes {\n'
if text.count(needle) != 1:
    sys.exit('Cannot add offline-only debug application suffix safely')
text = text.replace(needle, needle + '        debug {\n            applicationIdSuffix ".k3sandbox"\n        }\n', 1)
gradle.write_text(text)

manifest = root / 'android/app/src/main/AndroidManifest.xml'
xml = manifest.read_text()
label_match = re.search(r'android:label="[^"]+"', xml)
if not label_match:
    sys.exit('Missing Android application label')
xml = xml[:label_match.start()] + 'android:label="K3 OFFLINE TEST"' + xml[label_match.end():]
manifest.write_text(xml)

firebase = {
    'project_info': {
        'project_number': '123456789012',
        'project_id': 'k3-synthetic-build-invalid',
        'storage_bucket': 'k3-synthetic-build-invalid.invalid',
    },
    'client': [{
        'client_info': {
            'mobilesdk_app_id': '1:123456789012:android:0123456789abcdef01234567',
            'android_client_info': {'package_name': package + '.k3sandbox'},
        },
        'api_key': [{'current_key': 'k3-synthetic-not-a-valid-firebase-key'}],
    }],
    'configuration_version': '1',
}
path = root / 'android/app/google-services.json'
if path.exists():
    sys.exit('Refusing to overwrite existing Firebase config')
path.write_text(json.dumps(firebase, indent=2))
config = {
    'K3_API_BASE_URL': 'https://k3-offline.invalid/api/',
    'K3_FIREBASE_API_KEY': 'k3-synthetic-not-a-valid-firebase-key',
    'K3_FIREBASE_APP_ID': '1:123456789012:android:0123456789abcdef01234567',
    'K3_FIREBASE_SENDER_ID': '123456789012',
    'K3_FIREBASE_PROJECT_ID': 'k3-synthetic-build-invalid',
    'K3_FIREBASE_STORAGE_BUCKET': 'k3-synthetic-build-invalid.invalid',
}
config_path = Path(os.environ.get('RUNNER_TEMP', '/tmp')) / 'k3_offline_dart_defines.json'
config_path.write_text(json.dumps(config))
config_path.chmod(0o600)
print('OFFLINE SYNTHETIC CONFIG: no production/staging Firebase or API used')
print('Debug Android ID:', package + '.k3sandbox')
print('Use only for offline installation/compile checks; NOT clinical testing')

# Compile the actual app entrypoint. Never substitute a separate preview UI.
print('OFFLINE TEST: actual app source; synthetic services, no live accounts')
