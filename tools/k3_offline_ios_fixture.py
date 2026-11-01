#!/usr/bin/env python3
"""Create synthetic-only Firebase config for K3 iOS Simulator compile checks."""
import plistlib
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
pbx = (root / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
ids = re.findall(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(com\.cnu\.(?:patient|doctor));', pbx)
if not ids or len(set(ids)) != 1:
    raise SystemExit('Unexpected or inconsistent K3 Runner bundle ID')
plist = root / 'ios/Runner/GoogleService-Info.plist'
if plist.exists():
    raise SystemExit('Refusing to overwrite existing Firebase plist')
plist.parent.mkdir(parents=True, exist_ok=True)
plist.write_bytes(plistlib.dumps({
    'PLIST_VERSION': '1',
    'API_KEY': 'k3-synthetic-not-a-valid-firebase-key',
    'GCM_SENDER_ID': '123456789012',
    'PROJECT_ID': 'k3-synthetic-build-invalid',
    'STORAGE_BUCKET': 'k3-synthetic-build-invalid.invalid',
    'GOOGLE_APP_ID': '1:123456789012:ios:0123456789abcdef01234567',
    'BUNDLE_ID': ids[0],
    'IS_ADS_ENABLED': False,
    'IS_ANALYTICS_ENABLED': False,
    'IS_SIGNIN_ENABLED': False,
    'IS_GCM_ENABLED': False,
}))
print('Synthetic Firebase plist created for simulator-only compile')
