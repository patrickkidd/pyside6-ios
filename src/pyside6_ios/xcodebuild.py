import re
import subprocess

from pyside6_ios.config import AppConfig


def _derive_device_id(destination: str) -> str:
    match = re.search(r"id=([A-Fa-f0-9-]+)", destination)
    return match.group(1) if match else ""


def _find_app_path(xcodeproj: str, scheme: str, configuration: str,
                   destination: str) -> str:
    cmd = [
        "xcodebuild",
        "-project", xcodeproj,
        "-scheme", scheme,
        "-configuration", configuration,
        "-showBuildSettings",
    ]
    if destination:
        cmd.extend(["-destination", destination])
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    build_dir = ""
    product_name = ""
    for line in result.stdout.splitlines():
        line = line.strip()
        if line.startswith("TARGET_BUILD_DIR = "):
            build_dir = line.split(" = ", 1)[1]
        elif line.startswith("FULL_PRODUCT_NAME = "):
            product_name = line.split(" = ", 1)[1]
    if build_dir and product_name:
        return f"{build_dir}/{product_name}"
    return ""


def build(cfg: AppConfig, configuration: str = "Release",
          destination: str = "", scheme: str = "",
          install: bool = False):
    product_name = cfg.name.replace(" ", "")
    xcodeproj = str(cfg.output_dir / f"{product_name}.xcodeproj")

    if not scheme:
        scheme = product_name

    for script in cfg.pre_scripts:
        print(f"Running pre-build: {script}")
        subprocess.run(
            script, shell=True, check=True, cwd=cfg.project_root,
        )

    cmd = [
        "xcodebuild",
        "-project", xcodeproj,
        "-scheme", scheme,
        "-configuration", configuration,
    ]

    if destination:
        cmd.extend(["-destination", destination])

    xcconfig = cfg.xcconfig_release if configuration == "Release" else cfg.xcconfig_debug
    if not xcconfig:
        xcconfig = cfg.xcconfig
    if xcconfig:
        cmd.extend(["-xcconfig", str(cfg.project_root / xcconfig)])

    cmd.append("build")

    print(f"Running: {' '.join(cmd)}")
    subprocess.run(cmd, check=True)

    if install:
        device_id = _derive_device_id(destination)
        if not device_id:
            raise RuntimeError(
                "--install requires --destination 'id=DEVICE_UUID'"
            )
        app_path = _find_app_path(xcodeproj, scheme, configuration, destination)
        if not app_path:
            raise RuntimeError("Could not determine .app path from build settings")
        print(f"Installing {app_path} on device {device_id}...")
        subprocess.run(
            ["xcrun", "devicectl", "device", "install", "app",
             "--device", device_id, app_path],
            check=True,
        )
