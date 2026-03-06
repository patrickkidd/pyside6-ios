import argparse
import shutil
import subprocess
import sys
from pathlib import Path

from pyside6_ios import config, mainmm, moc, pbxproj, shiboken, signing, xcodebuild


def cmd_generate(args):
    cfg = config.load(args.config)
    output = cfg.output_dir
    product_name = cfg.name.replace(" ", "")

    output.mkdir(parents=True, exist_ok=True)

    # Run pre-build scripts
    for script in cfg.pre_scripts:
        print(f"Running pre-build: {script}")
        subprocess.run(script, shell=True, cwd=cfg.project_root, check=True)

    # Run moc on headers with Q_OBJECT
    moc_files = moc.run(cfg)
    if moc_files:
        print(f"Generated {len(moc_files)} moc file(s)")

    # Run shiboken for custom bindings
    binding_libs = shiboken.run(cfg)
    if binding_libs:
        print(f"Generated {len(binding_libs)} binding lib(s)")

    # Generate or copy main.mm
    if cfg.main_mm:
        src = cfg.project_root / cfg.main_mm
        shutil.copy2(src, output / "main.mm")
        print(f"Copied custom main.mm from {src}")
    else:
        main_content = mainmm.generate(cfg)
        (output / "main.mm").write_text(main_content)
        print("Generated main.mm")

    # Copy Info.plist
    if cfg.info_plist:
        src = cfg.project_root / cfg.info_plist
        shutil.copy2(src, output / "Info.plist")
    else:
        _generate_minimal_plist(cfg, output / "Info.plist")
    print("Info.plist ready")

    # Copy entitlements
    if cfg.entitlements:
        src = cfg.project_root / cfg.entitlements
        dest = output / Path(cfg.entitlements).name
        shutil.copy2(src, dest)

    # Copy assets catalog
    if cfg.assets:
        src = cfg.project_root / cfg.assets
        dest = output / Path(cfg.assets).name
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(src, dest)

    # Copy settings bundle
    if cfg.settings_bundle:
        src = cfg.project_root / cfg.settings_bundle
        dest = output / Path(cfg.settings_bundle).name
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(src, dest)

    # Generate .xcodeproj
    proj_dir = output / f"{product_name}.xcodeproj"
    proj_dir.mkdir(parents=True, exist_ok=True)
    pbx_content = pbxproj.generate(cfg, moc_files=moc_files, binding_libs=binding_libs)
    (proj_dir / "project.pbxproj").write_text(pbx_content)
    print(f"Generated {proj_dir}")

    # Generate xcscheme for xcodebuild -scheme to work
    _generate_scheme(proj_dir, product_name, cfg)


def cmd_build(args):
    cfg = config.load(args.config)
    # Generate first
    args_gen = argparse.Namespace(config=args.config)
    cmd_generate(args_gen)
    xcodebuild.build(
        cfg,
        configuration=args.configuration,
        destination=args.destination or "",
        install=args.install,
    )


def cmd_clean(args):
    cfg = config.load(args.config)
    if cfg.output_dir.exists():
        shutil.rmtree(cfg.output_dir)
        print(f"Removed {cfg.output_dir}")


def cmd_setup_keychain(args):
    cfg = config.load(args.config)
    signing.setup_keychain(cfg.output_dir)


def cmd_teardown_keychain(args):
    signing.teardown_keychain()


def _generate_minimal_plist(cfg: AppConfig, dest: Path):
    product_name = cfg.name.replace(" ", "")
    plist = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CFBundleDisplayName</key>
\t<string>{cfg.name}</string>
\t<key>CFBundleExecutable</key>
\t<string>{product_name}</string>
\t<key>CFBundleIdentifier</key>
\t<string>{cfg.bundle_id}</string>
\t<key>CFBundleName</key>
\t<string>{cfg.name}</string>
\t<key>CFBundlePackageType</key>
\t<string>APPL</string>
\t<key>CFBundleShortVersionString</key>
\t<string>{cfg.version}</string>
\t<key>CFBundleVersion</key>
\t<string>{cfg.version}</string>
\t<key>LSRequiresIPhoneOS</key>
\t<true/>
\t<key>UIApplicationSceneManifest</key>
\t<dict>
\t\t<key>UIApplicationSupportsMultipleScenes</key>
\t\t<false/>
\t\t<key>UISceneConfigurations</key>
\t\t<dict/>
\t</dict>
\t<key>UISupportedInterfaceOrientations</key>
\t<array>
\t\t<string>UIInterfaceOrientationPortrait</string>
\t\t<string>UIInterfaceOrientationLandscapeLeft</string>
\t\t<string>UIInterfaceOrientationLandscapeRight</string>
\t</array>
</dict>
</plist>
"""
    dest.write_text(plist)


def _generate_scheme(proj_dir: Path, product_name: str, cfg: AppConfig):
    schemes_dir = proj_dir / "xcshareddata" / "xcschemes"
    schemes_dir.mkdir(parents=True, exist_ok=True)

    # Minimal scheme XML that xcodebuild needs
    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1500" version="1.7">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference
               BuildableIdentifier="primary"
               BlueprintName="{product_name}"
               BuildableName="{product_name}.app"
               ReferencedContainer="container:{product_name}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference
            BuildableIdentifier="primary"
            BlueprintName="{product_name}"
            BuildableName="{product_name}.app"
            ReferencedContainer="container:{product_name}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
</Scheme>
"""
    (schemes_dir / f"{product_name}.xcscheme").write_text(scheme)


def main():
    parser = argparse.ArgumentParser(
        prog="pyside6-ios",
        description="Build tool for PySide6 iOS apps",
    )
    parser.add_argument(
        "-c", "--config",
        default="pyside6-ios.toml",
        help="Path to config file (default: pyside6-ios.toml)",
    )

    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("generate", help="Generate Xcode project")

    build_p = sub.add_parser("build", help="Generate and build")
    build_p.add_argument("--configuration", default="Release",
                         choices=["Debug", "Release"])
    build_p.add_argument("--destination", default="",
                         help="xcodebuild destination (e.g. 'id=DEVICE_ID')")
    build_p.add_argument("--install", action="store_true",
                         help="Install app on device after building (requires --destination)")

    sub.add_parser("clean", help="Remove output directory")

    sub.add_parser("setup-keychain", help="Set up CI signing keychain from env vars")
    sub.add_parser("teardown-keychain", help="Remove CI signing keychain")

    args = parser.parse_args()

    commands = {
        "generate": cmd_generate,
        "build": cmd_build,
        "clean": cmd_clean,
        "setup-keychain": cmd_setup_keychain,
        "teardown-keychain": cmd_teardown_keychain,
    }
    commands[args.command](args)
