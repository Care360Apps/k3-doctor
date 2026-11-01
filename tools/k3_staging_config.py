#!/usr/bin/env python3
"""Prepare temporary staging Dart defines without logging Firebase credentials.

An Android Firebase project can contain multiple apps. Select the exact
isolated .k3staging registration, never the first client in the JSON.
"""
import argparse
import json
import os
import pathlib
import plistlib
from urllib.parse import urlsplit


def choose_android_client(obj, package):
    if not package or not package.endswith(".k3staging"):
        raise ValueError("The explicit .k3staging Android package is required")
    clients = [
        client for client in obj.get("client", [])
        if client.get("client_info", {}).get("android_client_info", {})
        .get("package_name") == package
    ]
    if len(clients) != 1:
        raise ValueError("Firebase must contain exactly one matching Android staging app")
    return clients[0]


def prepare(platform, source, destination, api_url, android_package=None):
    parsed = urlsplit(api_url)
    if (parsed.scheme != "https" or not parsed.hostname
            or parsed.path != "/api/" or parsed.query or parsed.fragment
            or parsed.username or parsed.password):
        raise ValueError("Expected HTTPS staging API URL ending in /api/")

    if platform == "android":
        obj = json.loads(pathlib.Path(source).read_text(encoding="utf-8"))
        project = obj["project_info"]
        client = choose_android_client(obj, android_package)
        vals = {
            "K3_FIREBASE_API_KEY": client["api_key"][0]["current_key"],
            "K3_FIREBASE_APP_ID": client["client_info"]["mobilesdk_app_id"],
            "K3_FIREBASE_SENDER_ID": project["project_number"],
            "K3_FIREBASE_PROJECT_ID": project["project_id"],
            "K3_FIREBASE_STORAGE_BUCKET": project.get("storage_bucket", ""),
        }
    else:
        obj = plistlib.loads(pathlib.Path(source).read_bytes())
        vals = {
            "K3_FIREBASE_API_KEY": obj["API_KEY"],
            "K3_FIREBASE_APP_ID": obj["GOOGLE_APP_ID"],
            "K3_FIREBASE_SENDER_ID": obj["GCM_SENDER_ID"],
            "K3_FIREBASE_PROJECT_ID": obj["PROJECT_ID"],
            "K3_FIREBASE_STORAGE_BUCKET": obj.get("STORAGE_BUCKET", ""),
        }
    if any(not val for key, val in vals.items() if key != "K3_FIREBASE_STORAGE_BUCKET"):
        raise ValueError("Incomplete staging Firebase settings")

    vals["K3_API_BASE_URL"] = api_url
    out = pathlib.Path(destination)
    out.write_text(json.dumps(vals), encoding="utf-8")
    out.chmod(0o600)
    print("Staging Dart defines prepared: correct app registered; no secrets printed")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", choices=["android", "ios"], required=True)
    parser.add_argument("--firebase", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--android-package")
    args = parser.parse_args()
    try:
        prepare(args.platform, args.firebase, args.out,
                os.environ.get("K3_STAGING_API_URL", ""), args.android_package)
    except (ValueError, KeyError, IndexError, TypeError, OSError, json.JSONDecodeError) as exc:
        parser.exit(1, "Staging configuration invalid: " + str(exc) + "\n")


if __name__ == "__main__":
    main()
