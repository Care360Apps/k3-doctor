#!/usr/bin/env python3
"""Pure offline tests for Care360 Android release safeguards."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

source = Path(__file__).with_name("k3_android_release_preflight.py")
spec = importlib.util.spec_from_file_location("k3_android_release_preflight", source)
release_gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release_gate)


class AndroidReleaseGateTests(unittest.TestCase):
    def test_https_backend_is_required(self):
        release_gate.validate_api_url("https://medic.care360hms.com/api/")
        for value in (
            "http://medic.care360hms.com/api/",
            "http://127.0.0.1:9/api/",
            "https://example.test/api/",
            "https://medic.care360hms.com/other",
            "https://medic.care360hms.com/api/?debug=1",
        ):
            with self.subTest(value=value), self.assertRaises(ValueError):
                release_gate.validate_api_url(value)

    def test_play_version_code_must_increase(self):
        release_gate.validate_version("123", "124")
        for old, new in [("", "124"), ("124", "124"), ("125", "124"), ("1", "v2")]:
            with self.subTest(old=old, new=new), self.assertRaises(ValueError):
                release_gate.validate_version(old, new)

    def test_application_id_cannot_change(self):
        with tempfile.TemporaryDirectory() as folder:
            gradle = Path(folder) / "build.gradle"
            gradle.write_text('applicationId "com.cnu.doctor"\n')
            release_gate.validate_package(gradle)
            gradle.write_text('applicationId "com.example.newapp"\n')
            with self.assertRaises(ValueError):
                release_gate.validate_package(gradle)

    def test_release_rejects_missing_upload_keystore(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(ValueError):
                release_gate.validate_signing(Path(folder) / "missing.properties")


if __name__ == "__main__":
    unittest.main()
