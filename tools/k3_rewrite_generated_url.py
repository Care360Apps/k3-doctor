#!/usr/bin/env python3
"""Rewrite Retrofit generated URL to compile-time K3 API URL. Run after build_runner."""
from pathlib import Path
import re,sys
root=Path(__file__).resolve().parents[1]
path=root/'lib/retrofit/network_api.g.dart'
text=path.read_text()
# Retrofit generator embeds a literal from annotation const evaluation; replace with runtime constant.
text,n=re.subn(r"(?m)^(\s*)baseUrl\s*\?\?=\s*['\"]https?://[^'\"]+['\"];",r'\1baseUrl ??= Apis.baseUrl;',text,count=1)
# Already safe source is acceptable.
if n==0 and 'baseUrl ??= Apis.baseUrl;' not in text:
    print('Could not find Retrofit baseUrl assignment',file=sys.stderr);sys.exit(1)
# Strip former commented production endpoints.
text='\n'.join(l for l in text.split('\n') if not (l.lstrip().startswith('//') and 'baseUrl' in l and ('http://' in l or 'https://' in l)))
path.write_text(text)
print('Retrofit generated baseUrl now references explicit environment configuration')
