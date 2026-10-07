#!/usr/bin/env python3
"""Print ASC_MAX cfBundleVersion for com.asrax.aminvestment (stdout last line ASC_MAX=N)."""
import json
import os
import subprocess
import sys
import time
import urllib.request

try:
    import jwt
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "PyJWT", "cryptography", "-q"])
    import jwt


def main() -> None:
    key_id = os.environ["ASC_KEY_ID"]
    issuer = os.environ["ASC_ISSUER"]
    p8 = os.environ["ASC_P8"]
    now = int(time.time())
    token = jwt.encode(
        {"iss": issuer, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
        p8,
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )
    if isinstance(token, bytes):
        token = token.decode()
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}

    def get(url: str):
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as r:
            return json.load(r)

    apps = get(
        "https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]=com.asrax.aminvestment"
    )
    if not apps.get("data"):
        raise SystemExit("app not found")
    app_id = apps["data"][0]["id"]
    print(f"app_id={app_id}")

    builds = get(
        f"https://api.appstoreconnect.apple.com/v1/builds?filter[app]={app_id}&sort=-version&limit=50"
    )
    nums = []
    for b in builds.get("data") or []:
        v = b.get("attributes") or {}
        ver = v.get("version")
        print(
            json.dumps(
                {
                    "version": ver,
                    "uploadedDate": v.get("uploadedDate"),
                    "processingState": v.get("processingState"),
                    "expired": v.get("expired"),
                }
            )
        )
        try:
            nums.append(int(str(ver)))
        except Exception:
            pass

    # Also check preReleaseVersions → builds if top-level list is thin
    if not nums:
        pr = get(
            f"https://api.appstoreconnect.apple.com/v1/preReleaseVersions?filter[app]={app_id}&limit=20"
        )
        for pv in pr.get("data") or []:
            pid = pv["id"]
            rel = get(
                f"https://api.appstoreconnect.apple.com/v1/preReleaseVersions/{pid}/builds?limit=50"
            )
            for b in rel.get("data") or []:
                ver = (b.get("attributes") or {}).get("version")
                print(json.dumps({"preReleaseBuild": ver, "versionString": (pv.get("attributes") or {}).get("version")}))
                try:
                    nums.append(int(str(ver)))
                except Exception:
                    pass

    asc_max = max(nums) if nums else 0
    print(f"ASC_MAX={asc_max}")
    print(f"NEXT={asc_max + 1}")


if __name__ == "__main__":
    main()
