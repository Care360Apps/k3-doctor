#!/usr/bin/env python3
"""Prepare a LAN-only Care360 debug APK from an isolated staging Firebase app.

Runs only in a disposable CI checkout. Does not alter production configs.
"""
import argparse
import ipaddress
import json
import os
from pathlib import Path
import re
import sys

LAN_CIDRS = tuple(ipaddress.ip_network(c) for c in
                  ("10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"))
SUFFIX = ".k3staging"


def prepare(root: Path, firebase_path: Path, output: Path, ipv4: str) -> str:
    try:
        address = ipaddress.IPv4Address(ipv4)
    except ipaddress.AddressValueError as exc:
        raise ValueError("A literal IPv4 address is required") from exc
    if not any(address in network for network in LAN_CIDRS):
        raise ValueError("Only RFC1918 private IPv4 addresses are permitted")

    approved_project = os.environ.get("K3_STAGING_FIREBASE_PROJECT_ID", "")
    if not approved_project or approved_project.startswith("k3-synthetic"):
        raise ValueError("Set the approved K3_STAGING_FIREBASE_PROJECT_ID GitHub variable")

    gradle_path = root / "android/app/build.gradle"
    main_manifest = root / "android/app/src/main/AndroidManifest.xml"
    debug_manifest = root / "android/app/src/debug/AndroidManifest.xml"
    gradle = gradle_path.read_text(encoding="utf-8")
    main_xml = main_manifest.read_text(encoding="utf-8")
    debug_xml = debug_manifest.read_text(encoding="utf-8")

    ids = re.findall(r'(?m)^\s*applicationId\s+["\x27](com\.cnu\.(?:patient|doctor))["\x27]', gradle)
    if len(ids) != 1 or "applicationIdSuffix" in gradle:
        raise ValueError("Unexpected Android package ID or suffix: fail closed")
    package = ids[0] + SUFFIX
    if gradle.count("    buildTypes {\n") != 1:
        raise ValueError("Cannot safely isolate the debug Android package")
    labels = list(re.finditer(r'android:label="[^"]+"', main_xml))
    if len(labels) != 1:
        raise ValueError("Cannot identify a single Android application label")
    if "<application" in debug_xml or debug_xml.count("</manifest>") != 1:
        raise ValueError("Unexpected debug manifest layout")

    config = json.loads(firebase_path.read_text(encoding="utf-8"))
    project = config.get("project_info", {})
    if project.get("project_id") != approved_project:
        raise ValueError("Firebase project does not match the approved staging project")
    clients = config.get("client", [])
    registered = [
        c.get("client_info", {}).get("android_client_info", {}).get("package_name")
        for c in clients
    ]
    if registered.count(package) != 1 or ids[0] in registered:
        raise ValueError("Firebase must register the isolated .k3staging app, not the production app")
    client = clients[registered.index(package)]
    settings = {
        "K3_API_BASE_URL": f"http://{address}:8000/api/",
        "K3_FIREBASE_API_KEY": client["api_key"][0]["current_key"],
        "K3_FIREBASE_APP_ID": client["client_info"]["mobilesdk_app_id"],
        "K3_FIREBASE_SENDER_ID": project["project_number"],
        "K3_FIREBASE_PROJECT_ID": project["project_id"],
        "K3_FIREBASE_STORAGE_BUCKET": project.get("storage_bucket", ""),
    }
    if any(not settings[k] for k in ("K3_API_BASE_URL", "K3_FIREBASE_API_KEY",
                                     "K3_FIREBASE_APP_ID", "K3_FIREBASE_SENDER_ID",
                                     "K3_FIREBASE_PROJECT_ID")):
        raise ValueError("Missing Firebase client settings")

    gradle_path.write_text(
        gradle.replace("    buildTypes {\n",
                       '    buildTypes {\n        debug {\n            applicationIdSuffix ".k3staging"\n        }\n', 1),
        encoding="utf-8",
    )
    label = "Care360 Patient LAN TEST" if ids[0].endswith("patient") else "Care360 Plus LAN TEST"
    main_manifest.write_text(
        main_xml[:labels[0].start()] + f'android:label="{label}"' +
        main_xml[labels[0].end():],
        encoding="utf-8",
    )
    debug_manifest.write_text(
        debug_xml.replace("</manifest>",
                          '    <application android:usesCleartextTraffic="true" />\n</manifest>'),
        encoding="utf-8",
    )
    output.write_text(json.dumps(settings), encoding="utf-8")
    output.chmod(0o600)
    print("LAN test config prepared for isolated package", package)
    print("HTTP enabled only in Android debug manifest")
    print("GitHub runner will compile only; backend must be reachable from the user's emulator")
    return package


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ipv4", required=True)
    parser.add_argument("--firebase", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    try:
        prepare(Path(__file__).resolve().parents[1],
                Path(args.firebase), Path(args.out), args.ipv4)
    except (ValueError, KeyError, TypeError, IndexError, OSError, json.JSONDecodeError) as exc:
        sys.exit(f"Care360 LAN debug configuration rejected: {exc}")


if __name__ == "__main__":
    main()
