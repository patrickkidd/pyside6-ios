import base64
import os
import subprocess
import tempfile
from pathlib import Path


KEYCHAIN_NAME = "pyside6-ios-build.keychain-db"

ENV_VARS = {
    "certificate": "CERTIFICATE_BASE64",
    "private_key": "PRIVATE_KEY_BASE64",
    "provisioning_profile": "PROVISIONING_PROFILE_BASE64",
    "password": "CERTIFICATE_PASSWORD",
    "ac_auth_key": "AC_AUTH_KEY_BASE64",
}


def _decode_env(var: str) -> bytes | None:
    val = os.environ.get(var, "")
    if not val:
        return None
    return base64.b64decode(val)


def setup_keychain(build_dir: Path):
    build_dir.mkdir(parents=True, exist_ok=True)

    password = os.environ.get(ENV_VARS["password"], "")
    if not password:
        raise EnvironmentError(
            f"{ENV_VARS['password']} must be set for CI signing"
        )

    cert_data = _decode_env(ENV_VARS["certificate"])
    key_data = _decode_env(ENV_VARS["private_key"])
    profile_data = _decode_env(ENV_VARS["provisioning_profile"])
    ac_key_data = _decode_env(ENV_VARS["ac_auth_key"])

    if not cert_data or not key_data:
        raise EnvironmentError(
            f"Both {ENV_VARS['certificate']} and {ENV_VARS['private_key']} must be set"
        )

    cert_path = build_dir / "cert.p12"
    key_path = build_dir / "key.pem"
    cert_path.write_bytes(cert_data)
    key_path.write_bytes(key_data)

    if ac_key_data:
        ac_key_path = build_dir / "auth_key.p8"
        ac_key_path.write_bytes(ac_key_data)

    def _run(*args):
        subprocess.run(args, check=True)

    _run("security", "create-keychain", "-p", password, KEYCHAIN_NAME)
    _run("security", "default-keychain", "-s", KEYCHAIN_NAME)
    _run("security", "unlock-keychain", "-p", password, KEYCHAIN_NAME)
    _run("security", "set-keychain-settings", "-lut", "1200", KEYCHAIN_NAME)
    _run("security", "list-keychains", "-s", KEYCHAIN_NAME)
    _run("security", "import", str(key_path), "-t", "priv",
         "-P", password, "-A", "-T", "/usr/bin/codesign", "-k", KEYCHAIN_NAME)
    _run("security", "import", str(cert_path), "-P", password, "-k", KEYCHAIN_NAME)
    _run("security", "set-key-partition-list", "-S",
         "apple-tool:,apple:,codesign:", "-s", "-k", password, KEYCHAIN_NAME)

    if profile_data:
        profile_path = build_dir / "profile.mobileprovision"
        profile_path.write_bytes(profile_data)

        # Extract UUID from provisioning profile
        plist_result = subprocess.run(
            ["security", "cms", "-D", "-i", str(profile_path)],
            capture_output=True, text=True, check=True,
        )
        # Write temp plist for PlistBuddy
        plist_tmp = build_dir / "profile.plist"
        plist_tmp.write_text(plist_result.stdout)

        uuid_result = subprocess.run(
            ["/usr/libexec/PlistBuddy", "-c", "Print :UUID", str(plist_tmp)],
            capture_output=True, text=True, check=True,
        )
        profile_uuid = uuid_result.stdout.strip()

        profiles_dir = Path.home() / "Library/MobileDevice/Provisioning Profiles"
        profiles_dir.mkdir(parents=True, exist_ok=True)
        dest = profiles_dir / f"{profile_uuid}.mobileprovision"
        dest.write_bytes(profile_data)
        print(f"Installed provisioning profile: {profile_uuid}")

    print(f"Keychain {KEYCHAIN_NAME} configured for signing")


def teardown_keychain():
    try:
        subprocess.run(
            ["security", "delete-keychain", KEYCHAIN_NAME],
            check=True,
        )
    except subprocess.CalledProcessError:
        pass

    subprocess.run(
        ["security", "list-keychains", "-s", "login.keychain-db"],
        check=False,
    )
    subprocess.run(
        ["security", "default-keychain", "-s", "login.keychain-db"],
        check=False,
    )
    print("Keychain cleaned up")
