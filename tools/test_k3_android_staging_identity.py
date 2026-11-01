#!/usr/bin/env python3
"""Offline-only test of Play package isolation for a connected Android staging build."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

p = Path(__file__).with_name("k3_android_staging_identity.py")
spec = importlib.util.spec_from_file_location("staging_identity", p)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class TestStagingIdentity(unittest.TestCase):
    def fixture(self, folder: str):
        root = Path(folder)
        app = root / "android/app"
        manifest = app / "src/main/AndroidManifest.xml"
        manifest.parent.mkdir(parents=True)
        (app / "build.gradle").write_text(
            'android {\n    defaultConfig {\n'
            '        applicationId "com.cnu.patient"\n    }\n'
            '    buildTypes {\n        release { }\n    }\n}\n')
        manifest.write_text(
            '<manifest><application android:label="Care360 Patient" /></manifest>')
        config = root / "firebase.json"
        config.write_text(json.dumps({
            "project_info": {"project_id": "care360-staging"},
            "client": [{"client_info": {
                "android_client_info": {
                    "package_name": "com.cnu.patient.k3staging"
                }
            }}]
        }))
        return root, config, app, manifest

    def test_staging_changes_debug_package_only(self):
        with tempfile.TemporaryDirectory() as t:
            root, config, app, manifest = self.fixture(t)
            result = mod.prepare(root, config, "care360-staging",
                                 "https://staging.care360apps.com/api/")
            self.assertEqual(result, "com.cnu.patient.k3staging")
            gradle = (app / "build.gradle").read_text()
            self.assertIn('applicationId "com.cnu.patient"', gradle)
            self.assertIn('applicationIdSuffix ".k3staging"', gradle)
            self.assertIn('Care360 STAGING TEST', manifest.read_text())

    def test_production_api_is_blocked(self):
        for url in ["https://medic.care360hms.com/api/",
                    "https://k3-offline.invalid/api/",
                    "http://staging.care360apps.com/api/",
                    "https://staging.care360apps.com/public/"]:
            with self.subTest(url=url), self.assertRaises(ValueError):
                mod.verify_endpoint(url)

    def test_wrong_firebase_project_or_package_fails_without_file_changes(self):
        with tempfile.TemporaryDirectory() as t:
            root, config, app, manifest = self.fixture(t)
            original = (app / "build.gradle").read_text()
            with self.assertRaises(ValueError):
                mod.prepare(root, config, "production-project",
                            "https://staging.care360apps.com/api/")
            self.assertEqual((app / "build.gradle").read_text(), original)
            record = json.loads(config.read_text())
            record["client"][0]["client_info"]["android_client_info"]["package_name"] = "com.cnu.patient"
            config.write_text(json.dumps(record))
            with self.assertRaises(ValueError):
                mod.prepare(root, config, "care360-staging",
                            "https://staging.care360apps.com/api/")
            self.assertEqual((app / "build.gradle").read_text(), original)


if __name__ == "__main__":
    unittest.main()
