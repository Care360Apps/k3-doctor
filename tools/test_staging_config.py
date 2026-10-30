#!/usr/bin/env python3
"""Pure local tests for staging config generation; uses only fake sample values."""
from pathlib import Path
import json, os, plistlib, subprocess, sys, tempfile, unittest
ROOT=Path(__file__).resolve().parents[1]
TOOL=ROOT/'tools/k3_staging_config.py'

class TestStagingConfig(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.dir=Path(self.temp.name)
        self.out=self.dir/'output.json'
        self.android=self.dir/'google-services.json'
        self.android.write_text(json.dumps({
            'project_info':{'project_number':'1234567890','project_id':'k3-stage-test','storage_bucket':'k3-stage-test.appspot.test'},
            'client':[{'api_key':[{'current_key':'fake-api-key'}], 'client_info':{'mobilesdk_app_id':'1:1234567890:android:fake'}}]
        }))
        self.ios=self.dir/'GoogleService-Info.plist'
        self.ios.write_bytes(plistlib.dumps({
            'API_KEY':'fake-api-key', 'GOOGLE_APP_ID':'1:1234567890:ios:fake',
            'GCM_SENDER_ID':'1234567890','PROJECT_ID':'k3-stage-test',
        }))

    def run_tool(self,platform,url):
        env={**os.environ,'K3_STAGING_API_URL':url}
        file=self.android if platform=='android' else self.ios
        return subprocess.run([sys.executable,str(TOOL),'--platform',platform,
            '--firebase',str(file),'--out',str(self.out)],env=env,
            capture_output=True,text=True)

    def test_android_accepts_fake_staging_config(self):
        result=self.run_tool('android','https://staging.example.test/api/')
        self.assertEqual(result.returncode,0,result.stderr)
        obj=json.loads(self.out.read_text())
        self.assertEqual(obj['K3_API_BASE_URL'],'https://staging.example.test/api/')
        self.assertEqual(obj['K3_FIREBASE_PROJECT_ID'],'k3-stage-test')
        self.assertNotIn('fake-api-key',result.stdout+result.stderr)
        if os.name!='nt': self.assertEqual(self.out.stat().st_mode & 0o777,0o600)

    def test_ios_accepts_fake_staging_config(self):
        result=self.run_tool('ios','https://staging.example.test/api/')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(json.loads(self.out.read_text())['K3_FIREBASE_PROJECT_ID'],'k3-stage-test')

    def test_rejects_non_https_backend(self):
        result=self.run_tool('android','http://localhost/api/')
        self.assertNotEqual(result.returncode,0)
        self.assertFalse(self.out.exists())

    def test_rejects_missing_api_path(self):
        result=self.run_tool('ios','https://staging.example.test/')
        self.assertNotEqual(result.returncode,0)
        self.assertFalse(self.out.exists())

if __name__=='__main__': unittest.main()
