#!/usr/bin/env python3
"""Fail closed before preparing connected Care360 Android STAGING APKs.

Changes only the disposable CI checkout. Staging must have its own Android
package registration and Firebase project, never the installed Play package.
"""
import argparse
import json
import os
from pathlib import Path
import re
from urllib.parse import urlsplit
import ipaddress

SUFFIX = ".k3staging"


def _is_staging_host(host: str) -> bool:
    # A standalone DNS label or hyphen-delimited environment token, never
    # substrings such as 'contest', 'development' or 'productionstaging'.
    if not host or host.endswith((".invalid", ".local", ".test", ".example")):
        return False
    try:
        ipaddress.ip_address(host)
        return False
    except ValueError:
        pass
    labels = host.lower().split(".")
    return len(labels) >= 3 and any(
        token in ("staging", "sandbox", "test", "dev")
        for label in labels[:-2] for token in label.split("-")
    )


def verify_endpoint(value: str) -> None:
    u = urlsplit(value)
    host = (u.hostname or "").lower()
    # The production server must never be the Android staging target.
    if (u.scheme != "https" or u.path != "/api/" or not host or
            u.port not in (None, 443) or u.username or u.password or
            u.query or u.fragment or not _is_staging_host(host)):
        raise ValueError("An approved HTTPS staging API URL ending /api/ is required")


def prepare(root: Path, firebase_file: Path, approved_project_id: str,
            staging_url: str) -> str:
    verify_endpoint(staging_url)
    if not approved_project_id or approved_project_id.lower().startswith("k3-synthetic"):
        raise ValueError("Explicit approved staging Firebase project ID is required")
    gradle_file = root / "android/app/build.gradle"
    manifest_file = root / "android/app/src/main/AndroidManifest.xml"
    gradle = gradle_file.read_text(encoding="utf-8")
    manifest = manifest_file.read_text(encoding="utf-8")
    ids = re.findall(r'^\s*applicationId\s+["\x27](com\.cnu\.(?:patient|doctor))["\x27]',
                     gradle, flags=re.MULTILINE)
    if len(ids) != 1 or "applicationIdSuffix" in gradle:
        raise ValueError("Unexpected Android application ID or existing debug suffix")
    base = ids[0]
    config = json.loads(firebase_file.read_text(encoding="utf-8"))
    project = config.get("project_info", {}).get("project_id", "")
    if project != approved_project_id:
        raise ValueError("Staging Firebase project is not the explicitly approved project")
    registered_packages = [
        c.get("client_info", {}).get("android_client_info", {}).get("package_name")
        for c in config.get("client", [])
    ]
    if base + SUFFIX not in registered_packages or base in registered_packages:
        raise ValueError("Firebase config must register only the .k3staging Android package")
    marker = "    buildTypes {\n"
    if gradle.count(marker) != 1:
        raise ValueError("Unexpected Gradle buildTypes layout")
    label_matches = list(re.finditer(r'android:label="[^"]+"', manifest))
    if len(label_matches) != 1:
        raise ValueError("Cannot identify unique Android app label")
    # Write files only after *all* checks have passed.
    gradle_file.write_text(
        gradle.replace(marker, marker + '        debug {\n'
                       '            applicationIdSuffix ".k3staging"\n'
                       '        }\n', 1),
        encoding="utf-8",
    )
    manifest_file.write_text(
        manifest[:label_matches[0].start()] +
        'android:label="Care360 STAGING TEST"' +
        manifest[label_matches[0].end():],
        encoding="utf-8",
    )
    return base + SUFFIX


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=str(Path(__file__).resolve().parents[1]))
    parser.add_argument("--firebase", required=True)
    args = parser.parse_args()
    try:
        package = prepare(
            Path(args.root), Path(args.firebase),
            os.environ.get("K3_APPROVED_STAGING_FIREBASE_PROJECT_ID", ""),
            os.environ.get("K3_STAGING_API_URL", ""),
        )
    except (ValueError, OSError, KeyError, json.JSONDecodeError) as exc:
        parser.exit(1, f"Android staging identity validation FAILED: {exc}\n")
    print(f"Care360 isolated Android staging package configured: {package}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
