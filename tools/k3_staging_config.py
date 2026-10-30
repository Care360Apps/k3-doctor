#!/usr/bin/env python3
"""Build-only staging Dart defines from ephemeral Firebase config, no stdout secrets."""
import argparse, json, plistlib, os, pathlib, urllib.parse
p=argparse.ArgumentParser();p.add_argument('--platform', choices=['android','ios'], required=True);p.add_argument('--firebase',required=True);p.add_argument('--out',required=True)
a=p.parse_args()
source=pathlib.Path(a.firebase)
if a.platform=='android':
    obj=json.loads(source.read_text())
    project=obj['project_info']
    client=obj['client'][0]
    vals={
        'K3_FIREBASE_API_KEY':client['api_key'][0]['current_key'],
        'K3_FIREBASE_APP_ID':client['client_info']['mobilesdk_app_id'],
        'K3_FIREBASE_SENDER_ID':project['project_number'],
        'K3_FIREBASE_PROJECT_ID':project['project_id'],
        'K3_FIREBASE_STORAGE_BUCKET':project.get('storage_bucket',''),
    }
else:
    obj=plistlib.loads(source.read_bytes())
    vals={
        'K3_FIREBASE_API_KEY':obj['API_KEY'],
        'K3_FIREBASE_APP_ID':obj['GOOGLE_APP_ID'],
        'K3_FIREBASE_SENDER_ID':obj['GCM_SENDER_ID'],
        'K3_FIREBASE_PROJECT_ID':obj['PROJECT_ID'],
        'K3_FIREBASE_STORAGE_BUCKET':obj.get('STORAGE_BUCKET',''),
    }
url=os.environ.get('K3_STAGING_API_URL','')
parsed=urllib.parse.urlparse(url)
if parsed.scheme!='https' or not parsed.hostname or not url.endswith('/api/'):
    raise SystemExit('Expected HTTPS K3_STAGING_API_URL ending in /api/')
if any(not val for k,val in vals.items() if k != 'K3_FIREBASE_STORAGE_BUCKET'):
    raise SystemExit('Incomplete staging Firebase settings')
vals['K3_API_BASE_URL']=url
path=pathlib.Path(a.out)
path.write_text(json.dumps(vals))
path.chmod(0o600)
print('Staging Dart-define file prepared without printing values')
