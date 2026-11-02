#!/usr/bin/env python3
"""Fail fast if Android desugaring required by notifications is missing.

Pure source check; does not contact any backend or external services.
"""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
GRADLE = ROOT / "android/app/build.gradle"


class AndroidDesugaringConfiguration(unittest.TestCase):
    def test_flutter_local_notifications_supported(self):
        source = GRADLE.read_text(encoding="utf-8")
        self.assertRegex(
            source,
            r"(?s)compileOptions\s*\{[^}]*\bcoreLibraryDesugaringEnabled\s+true\b",
        )
        self.assertIn(
            "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'", source,
        )
        self.assertIn("sourceCompatibility JavaVersion.VERSION_17", source)
        self.assertIn("targetCompatibility JavaVersion.VERSION_17", source)


if __name__ == "__main__":
    unittest.main()
