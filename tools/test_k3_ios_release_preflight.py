#!/usr/bin/env python3
"""Offline contract tests for the Care360 Plus App Store release gates."""
import importlib.util
from pathlib import Path
import plistlib
import tempfile
import unittest

source = Path(__file__).with_name("k3_ios_release_preflight.py")
spec = importlib.util.spec_from_file_location("k3_ios_release_preflight", source)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)
root = Path(__file__).resolve().parents[1]


class IOSReleaseGateTests(unittest.TestCase):
    def test_xcode_26_or_later_required(self):
        gate.validate_xcode("Xcode 26.0\nBuild version 17A324\n")
        gate.validate_xcode("Xcode 26.1\nBuild version 17B55\n")
        with self.assertRaises(ValueError):
            gate.validate_xcode("Xcode 16.4\nBuild version 16F6\n")

    def test_existing_app_build_number_must_increase(self):
        gate.validate_version("89", "90")
        for old, proposed in [("", "90"), ("90", "90"), ("91", "90"), ("89", "v90")]:
            with self.subTest(old=old, proposed=proposed), self.assertRaises(ValueError):
                gate.validate_version(old, proposed)

    def test_api_must_be_real_https(self):
        gate.validate_api_url("https://api.care360apps.com/api/")
        for value in ("http://localhost:8000/api/", "https://example.test/api/",
                      "https://care360apps.com/admin/", "https://api.care360apps.com/api/?secret=1"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                gate.validate_api_url(value)

    def test_release_native_source_is_compatible_with_store_gate(self):
        gate.validate_source(
            root / "ios/Runner.xcodeproj/project.pbxproj",
            root / "ios/Runner/Info.plist",
            root / "ios/Runner/RunnerRelease.entitlements",
            root / "ios/Podfile",
            root / "ios/Runner/AppDelegate.swift",
        )

    def test_device_sdk_must_be_26_or_later(self):
        gate.validate_sdk("26.1\n")
        for value in ("", "18.0", "simulator-26.0"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                gate.validate_sdk(value)

    def test_firebase_ios_bundle_and_project_must_match(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "GoogleService-Info.plist"
            config = {
                "BUNDLE_ID": "com.cnu.doctor",
                "PROJECT_ID": "synthetic-test-project",
                "API_KEY": "synthetic-not-real",
                "GOOGLE_APP_ID": "1:123:ios:abcdef",
                "GCM_SENDER_ID": "123",
            }
            path.write_bytes(plistlib.dumps(config))
            gate.validate_firebase_ios(path, "synthetic-test-project")
            with self.assertRaises(ValueError):
                gate.validate_firebase_ios(path, "wrong-project")
            config["BUNDLE_ID"] = "com.example.different"
            path.write_bytes(plistlib.dumps(config))
            with self.assertRaises(ValueError):
                gate.validate_firebase_ios(path, "synthetic-test-project")


    def test_native_firebase_must_match_the_approved_client(self):
        with tempfile.TemporaryDirectory() as folder:
            approved = Path(folder) / "approved.plist"
            native = Path(folder) / "native.plist"
            fixture = {"BUNDLE_ID":"com.cnu.doctor", "PROJECT_ID":"care360productionfixture",
                       "API_KEY":"fake-not-real", "GOOGLE_APP_ID":"1:123:ios:fixture", "GCM_SENDER_ID":"123"}
            approved.write_bytes(plistlib.dumps(fixture))
            native.write_bytes(plistlib.dumps(fixture))
            gate.validate_native_firebase(approved, native, fixture["PROJECT_ID"])
            fixture["GOOGLE_APP_ID"] = "1:123:ios:foreign"
            native.write_bytes(plistlib.dumps(fixture))
            with self.assertRaises(ValueError):
                gate.validate_native_firebase(approved, native, fixture["PROJECT_ID"])

if __name__ == "__main__":
    unittest.main()
