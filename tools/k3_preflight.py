#!/usr/bin/env python3
"""Offline K3 source preflight: no live API requests or credentials are needed."""
from pathlib import Path
import re, sys, urllib.parse
root=Path(__file__).resolve().parents[1]
lib=root/'lib'
errors=[]
for p in lib.rglob('*.dart'):
    raw=p.read_text(encoding='utf-8',errors='replace')
    for val in re.findall(r'''(?:import|export|part)\s+['"]([^'"]+)['"]''',raw):
        val=urllib.parse.unquote(val)
        if val.startswith('dart:') or (val.startswith('package:') and not val.startswith('package:doctro/')):continue
        if val.startswith('package:doctro/'):
            candidate=lib / val.split('/',1)[1]
        elif '://' in val:continue
        else:candidate=(p.parent/val)
        if not candidate.is_file(): errors.append(f'{p.relative_to(root)} -> {val}')
# Credentialed FCM requests must originate from trusted server infrastructure.
for p in lib.rglob('*.dart'):
    raw=p.read_text(encoding='utf-8',errors='replace')
    if 'fcm.googleapis.com/fcm/send' in raw:
        errors.append('Legacy FCM HTTP endpoint in mobile source: '+str(p.relative_to(root)))
    if re.search(r'(?i)Authorization[\s\S]{0,100}key\s*=\s*AAAA[\w:-]{20,}',raw):
        errors.append('Firebase server key in mobile source: '+str(p.relative_to(root)))
    if re.search(r'AAAA[\w:-]{32,}',raw):
        errors.append('Possible Firebase server credential in mobile source: '+str(p.relative_to(root)))

for p in root.rglob('*'):
    if not p.is_file() or '.git' in p.parts:continue
    n=p.name
    if (n in {'.env','key.properties','local.properties','google-services.json','GoogleService-Info.plist','oauth-private.key'} or
        re.fullmatch(r'\.env(?:\..+)?',n) or p.suffix in {'.jks','.keystore','.p8','.p12','.pem','.key','.mobileprovision'}):
        errors.append('Private/generated file present: '+str(p.relative_to(root)))
    if p.suffix in {'.dart','.yaml','.gradle','.xml','.properties','.plist','.json','.kt','.swift','.md'} and p.stat().st_size<1500000:
        text=p.read_text(errors='replace')
        if re.search(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|\bsk_live_[A-Za-z0-9]{12,}|\bAKIA[0-9A-Z]{16}',text):
            errors.append('Possible embedded credential: '+str(p.relative_to(root)))
print('K3 static preflight: '+('PASS' if not errors else 'FAIL'))
for e in errors[:100]:print(' - '+e)
if len(errors)>100:print(f' ... {len(errors)-100} additional')
sys.exit(1 if errors else 0)
