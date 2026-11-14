#!/usr/bin/env python3
"""Offline non-secret tests for the Plus production Firebase config generator."""
import importlib.util
import json
from pathlib import Path
import plistlib
import tempfile
import unittest

source = Path(__file__).with_name("k3_production_config.py")
spec = importlib.util.spec_from_file_location("k3_production_config", source)
production = importlib.util.module_from_spec(spec)
spec.loader.exec_module(production)


class ProductionConfigTests(unittest.TestCase):
    def test_production_api_is_explicit_https_only(self):
        production.verify_production_endpoint("https://api.care360apps.com/api/")
        for url in ("", "http://api.care360apps.com/api/",
                    "https://staging-api.care360apps.com/api/",
                    "https://api.care360apps.com/admin",
                    "https://api.care360apps.com/api/?debug=1",
                    "https://k3-offline.invalid/api/"):
            with self.subTest(url=url), self.assertRaises(ValueError):
                production.verify_production_endpoint(url)

    def test_production_project_cannot_be_staging(self):
        production.verify_production_project("care360production", "care360-staging-9c90a")
        for proj in ("", "care360-staging-9c90a", "care360-test", "k3-synthetic-build-invalid"):
            with self.subTest(project=proj), self.assertRaises(ValueError):
                production.verify_production_project(proj, "care360-staging-9c90a")

    def test_android_config_uses_exact_plus_app(self):
        with tempfile.TemporaryDirectory() as d:
            source = Path(d) / "google-services.json"
            target = Path(d) / "private-android.json"
            fixture = {
                "project_info": {
                    "project_id": "care360production",
                    "project_number": "12345678",
                    "storage_bucket": "care360production.appspot.com",
                },
                "client": [
                    {
                        "client_info": {
                            "mobilesdk_app_id": "1:123:android:1",
                            "android_client_info": {"package_name": "com.cnu.doctor"},
                        },
                        "api_key": [{"current_key": "fake-for-unit-testing"}],
                    },
                    {
                        "client_info": {
                            "mobilesdk_app_id": "1:123:android:2",
                            "android_client_info": {"package_name": "com.cnu.doctor.k3staging"},
                        },
                        "api_key": [{"current_key": "staging-unit-test-only"}],
                    },
                ],
            }
            source.write_text(json.dumps(fixture), encoding="utf-8")
            production.prepare("android", source, target,
                               "https://api.care360apps.com/api/",
                               "care360production", "care360-staging-9c90a")
            vals = json.loads(target.read_text())
            self.assertEqual(vals["K3_FIREBASE_APP_ID"], "1:123:android:1")
            self.assertEqual(vals["K3_API_BASE_URL"], "https://api.care360apps.com/api/")
            with self.assertRaises(ValueError):
                production.prepare("android", source, target,
                                   "https://api.care360apps.com/api/",
                                   "care360production")
            fixture["client"][0]["client_info"]["android_client_info"]["package_name"] = "com.example.other"
            source.write_text(json.dumps(fixture))
            with self.assertRaises(ValueError):
                production.prepare("android", source, Path(d) / "other.json",
                                   "https://api.care360apps.com/api/",
                                   "care360production")

    def test_ios_config_checks_bundle_and_project(self):
        with tempfile.TemporaryDirectory() as d:
            source = Path(d) / "GoogleService-Info.plist"
            target = Path(d) / "private-ios.json"
            fixture = {
                "BUNDLE_ID": "com.cnu.doctor",
                "PROJECT_ID": "care360production",
                "API_KEY": "fake-for-unit-testing",
                "GOOGLE_APP_ID": "1:123:ios:1",
                "GCM_SENDER_ID": "123",
            }
            source.write_bytes(plistlib.dumps(fixture))
            production.prepare("ios", source, target,
                               "https://api.care360apps.com/api/",
                               "care360production")
            self.assertEqual(json.loads(target.read_text())["K3_FIREBASE_APP_ID"], "1:123:ios:1")
            fixture["BUNDLE_ID"] = "com.example.foreign"
            source.write_bytes(plistlib.dumps(fixture))
            with self.assertRaises(ValueError):
                production.prepare("ios", source, Path(d) / "different.json",
                                   "https://api.care360apps.com/api/",
                                   "care360production")


if __name__ == "__main__":
    unittest.main()
