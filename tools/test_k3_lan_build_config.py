"""Offline guardrail checks for manual Care360 LAN APK build configuration."""
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from k3_lan_build_config import prepare


class LanBuildConfigTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "android/app/src/main").mkdir(parents=True)
        (self.root / "android/app/src/debug").mkdir(parents=True)
        (self.root / "android/app/build.gradle").write_text(
            'android {\n    defaultConfig {\n        applicationId "com.cnu.patient"\n'
            '    }\n    buildTypes {\n        release {}\n    }\n}\n',
            encoding="utf-8",
        )
        (self.root / "android/app/src/main/AndroidManifest.xml").write_text(
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '  <application android:label="Care360" />\n</manifest>\n',
            encoding="utf-8",
        )
        (self.root / "android/app/src/debug/AndroidManifest.xml").write_text(
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '</manifest>\n',
            encoding="utf-8",
        )
        self.config_path = self.root / "staging-firebase.json"
        self.out = self.root / "runner-temp.json"
        self.fake_firebase = {
            "project_info": {
                "project_id": "care360-dev-isolated",
                "project_number": "123456789012",
                "storage_bucket": "care360-dev-isolated.example",
            },
            "client": [{
                "client_info": {
                    "mobilesdk_app_id": "1:123456789012:android:aabbccdd",
                    "android_client_info": {"package_name": "com.cnu.patient.k3staging"},
                },
                "api_key": [{"current_key": "fake-example-api-key"}],
            }],
        }
        self.config_path.write_text(json.dumps(self.fake_firebase), encoding="utf-8")
        self.patch = patch.dict(os.environ,
                                {"K3_STAGING_FIREBASE_PROJECT_ID": "care360-dev-isolated"})
        self.patch.start()
        self.addCleanup(self.patch.stop)

    def test_private_lan_build_is_isolated(self):
        package = prepare(self.root, self.config_path, self.out, "192.168.100.38")
        self.assertEqual(package, "com.cnu.patient.k3staging")
        cfg = json.loads(self.out.read_text(encoding="utf-8"))
        self.assertEqual(cfg["K3_API_BASE_URL"], "http://192.168.100.38:8000/api/")
        self.assertIn('applicationIdSuffix ".k3staging"',
                      (self.root / "android/app/build.gradle").read_text())
        self.assertIn('android:usesCleartextTraffic="true"',
                      (self.root / "android/app/src/debug/AndroidManifest.xml").read_text())
        self.assertNotIn("usesCleartextTraffic",
                         (self.root / "android/app/src/main/AndroidManifest.xml").read_text())
        self.assertIn("Care360 Patient LAN TEST",
                      (self.root / "android/app/src/main/AndroidManifest.xml").read_text())

    def test_public_or_loopback_address_rejected_without_modification(self):
        original = (self.root / "android/app/build.gradle").read_text()
        for ip in ("8.8.8.8", "127.0.0.1", "169.254.1.3", "not-an-ip"):
            with self.subTest(ip=ip), self.assertRaises(ValueError):
                prepare(self.root, self.config_path, self.out, ip)
        self.assertEqual(original, (self.root / "android/app/build.gradle").read_text())
        self.assertFalse(self.out.exists())

    def test_production_firebase_registration_rejected(self):
        self.fake_firebase["client"][0]["client_info"]["android_client_info"]["package_name"] = "com.cnu.patient"
        self.config_path.write_text(json.dumps(self.fake_firebase), encoding="utf-8")
        with self.assertRaises(ValueError):
            prepare(self.root, self.config_path, self.out, "192.168.100.38")
        self.assertFalse(self.out.exists())

    def test_unapproved_firebase_project_rejected(self):
        with patch.dict(os.environ, {"K3_STAGING_FIREBASE_PROJECT_ID": "another-project"}):
            with self.assertRaises(ValueError):
                prepare(self.root, self.config_path, self.out, "10.0.0.7")
        self.assertFalse(self.out.exists())


if __name__ == "__main__":
    unittest.main()
