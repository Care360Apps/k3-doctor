#!/usr/bin/env python3
"""Create private Flutter Dart configuration for a Care360 Plus store build.

Use only with verified production Firebase client files and an approved
production HTTPS backend. Writes to a private temporary path, never stdout.
This does not authenticate the caller or prove backend/Firestore policy safety.
"""
import argparse
import json
import os
from pathlib import Path
import plistlib
import re
import sys
from urllib.parse import urlsplit

PLUS_ID = "com.cnu.doctor"
NONPRODUCTION_TOKENS = {"staging", "test", "sandbox", "dev", "synthetic", "offline"}


def verify_production_endpoint(value: str) -> None:
    u = urlsplit(value)
    host = (u.hostname or "").lower()
    segments = set(re.split(r"[-.]", host))
    if (u.scheme != "https" or not host or "." not in host or
            u.port not in (None, 443) or u.path != "/api/" or
            u.username or u.password or u.query or u.fragment or
            host in {"example.com", "localhost"} or
            host.endswith((".invalid", ".test", ".example", ".local")) or
            re.fullmatch(r"[0-9.]+", host) or
            NONPRODUCTION_TOKENS.intersection(segments)):
        raise ValueError("Expected approved production HTTPS API ending exactly /api/")


def verify_production_project(value: str, staging_project: str) -> None:
    if (not value or value == staging_project or
            NONPRODUCTION_TOKENS.intersection(set(re.split(r"[-.]", value.lower())))):
        raise ValueError("Production Firebase project must be explicit and separate from staging")


def prepare(platform: str, source: Path, target: Path, api_url: str,
            approved_project: str, staging_project: str = "") -> None:
    verify_production_endpoint(api_url)
    verify_production_project(approved_project, staging_project)

    if platform == "android":
        obj = json.loads(source.read_text(encoding="utf-8"))
        project = obj["project_info"]
        matches = [
            client for client in obj.get("client", [])
            if client.get("client_info", {}).get("android_client_info", {})
            .get("package_name") == PLUS_ID
        ]
        if len(matches) != 1:
            raise ValueError("Firebase Android config must include one com.cnu.doctor app")
        client = matches[0]
        vals = {
            "K3_FIREBASE_API_KEY": client["api_key"][0]["current_key"],
            "K3_FIREBASE_APP_ID": client["client_info"]["mobilesdk_app_id"],
            "K3_FIREBASE_SENDER_ID": project["project_number"],
            "K3_FIREBASE_PROJECT_ID": project["project_id"],
            "K3_FIREBASE_STORAGE_BUCKET": project.get("storage_bucket", ""),
        }
    elif platform == "ios":
        obj = plistlib.loads(source.read_bytes())
        if obj.get("BUNDLE_ID") != PLUS_ID:
            raise ValueError("Firebase iOS bundle ID must be the existing Plus ID")
        vals = {
            "K3_FIREBASE_API_KEY": obj["API_KEY"],
            "K3_FIREBASE_APP_ID": obj["GOOGLE_APP_ID"],
            "K3_FIREBASE_SENDER_ID": obj["GCM_SENDER_ID"],
            "K3_FIREBASE_PROJECT_ID": obj["PROJECT_ID"],
            "K3_FIREBASE_STORAGE_BUCKET": obj.get("STORAGE_BUCKET", ""),
        }
    else:
        raise ValueError("Platform must be android or ios")

    if vals["K3_FIREBASE_PROJECT_ID"] != approved_project:
        raise ValueError("Firebase config does not match verified production project")
    if any(not vals[k] for k in ("K3_FIREBASE_API_KEY", "K3_FIREBASE_APP_ID",
                               "K3_FIREBASE_SENDER_ID", "K3_FIREBASE_PROJECT_ID")):
        raise ValueError("Firebase client configuration is incomplete")
    vals["K3_API_BASE_URL"] = api_url
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        raise ValueError("Refusing to overwrite an existing private build configuration")
    target.write_text(json.dumps(vals), encoding="utf-8")
    os.chmod(target, 0o600)
    print("Care360 production Dart configuration verified and written privately (no values shown).")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--platform", required=True, choices=("android", "ios"))
    ap.add_argument("--firebase", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    try:
        if os.environ.get("K3_BUILD_ENV") != "production":
            raise ValueError("K3_BUILD_ENV=production is mandatory")
        prepare(args.platform, args.firebase, args.out,
                os.environ.get("K3_API_BASE_URL", ""),
                os.environ.get("K3_PRODUCTION_FIREBASE_PROJECT_ID", ""),
                os.environ.get("K3_STAGING_FIREBASE_PROJECT_ID", ""))
    except (ValueError, OSError, KeyError, IndexError, TypeError, json.JSONDecodeError,
            plistlib.InvalidFileException) as exc:
        print(f"Care360 production config BLOCKED: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
