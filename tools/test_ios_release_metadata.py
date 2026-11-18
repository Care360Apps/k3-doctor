"""Offline Plus native metadata guards; does not replace an Xcode build."""
from pathlib import Path
import plistlib
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class IOSReleaseMetadataTests(unittest.TestCase):
    def test_release_and_profile_use_production_push(self):
        project = (ROOT / "ios/Runner.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
        for config_id, name in (("249021D4217E4FDB00AE95B9", "Profile"),
                                ("97C147071CF9000F007C117D", "Release")):
            block = project.split(f"{config_id} /* {name} */ = {{", 1)[1].split(f"name = {name};", 1)[0]
            self.assertIn("CODE_SIGN_ENTITLEMENTS = Runner/RunnerRelease.entitlements;", block)
        release = plistlib.loads((ROOT / "ios/Runner/RunnerRelease.entitlements").read_bytes())
        self.assertEqual("production", release["aps-environment"])

    def test_debug_push_and_keychain_identity_are_preserved(self):
        debug = plistlib.loads((ROOT / "ios/Runner/Runner.entitlements").read_bytes())
        release = plistlib.loads((ROOT / "ios/Runner/RunnerRelease.entitlements").read_bytes())
        self.assertEqual("development", debug["aps-environment"])
        self.assertEqual(debug["keychain-access-groups"], release["keychain-access-groups"])

    def test_native_startup_does_not_reconfigure_firebase_or_log_tokens(self):
        source = (ROOT / "ios/Runner/AppDelegate.swift").read_text(encoding="utf-8")
        self.assertRegex(source, r"if FirebaseApp\.app\(\) == nil\s*\{\s*FirebaseApp\.configure\(\)")
        self.assertNotIn("print(", source)
        self.assertNotIn('\\(error)', source)
        self.assertIn("Messaging.messaging().apnsToken = deviceToken", source)


if __name__ == "__main__":
    unittest.main()
