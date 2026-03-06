# pyside6-ios Build Tool Reference

## Overview

`pyside6-ios` generates Xcode projects from a TOML config file. It handles the
iOS-specific build complexity that makes PySide6 apps non-trivial: static
framework linking, Python stdlib bundling, QML plugin registration, code
signing, custom C++ bindings, and resource management.

## Commands

```bash
pyside6-ios -c <config.toml> generate    # Generate .xcodeproj
pyside6-ios -c <config.toml> build       # Generate + xcodebuild
pyside6-ios -c <config.toml> clean       # Remove output directory
pyside6-ios -c <config.toml> setup-keychain     # CI: decode signing assets from env
pyside6-ios -c <config.toml> teardown-keychain  # CI: remove temp keychain
```

### `generate`

1. Runs pre-build scripts (`[build-scripts] pre`)
2. Runs `moc` on headers containing `Q_OBJECT` (from `[sources]` and `[bindings]`)
3. Runs `shiboken6` for custom binding modules (`[bindings]`)
4. Generates or copies `main.mm` (auto-generated unless `[sources] main-mm` is set)
5. Copies `Info.plist`, entitlements, `Assets.xcassets`, `Settings.bundle`
6. Writes `project.pbxproj` and xcscheme

### `build`

Runs `generate`, then invokes `xcodebuild`. Accepts `--configuration Debug|Release`
and `--destination` (e.g., `'id=DEVICE_UUID'`).

To build and install on a connected device:

```bash
pyside6-ios -c pyside6-ios.toml build \
  --configuration Debug \
  --destination 'id=DEVICE_UUID' \
  --install
```

Without `--install`, `xcodebuild build` only compiles — it does not deploy to
the device. The `--install` flag runs `xcrun devicectl device install app` after
a successful build.

Find device UUIDs with `xcrun devicectl list devices`.

To launch the installed app with console output:

```bash
xcrun devicectl device process launch \
  --device DEVICE_UUID --console com.example.myapp
```

Or open the generated `.xcodeproj` in Xcode and use Run (Cmd+R) to build,
install, launch, and debug in one step.

### `setup-keychain` / `teardown-keychain`

For CI pipelines. Decodes base64-encoded signing assets from environment variables
and installs them into a temporary keychain.

**Environment variables:**

| Variable | Contents |
|----------|----------|
| `CERTIFICATE_BASE64` | .p12 certificate |
| `PRIVATE_KEY_BASE64` | Private key (.pem) |
| `CERTIFICATE_PASSWORD` | Password for the .p12 |
| `PROVISIONING_PROFILE_BASE64` | .mobileprovision file |
| `AC_AUTH_KEY_BASE64` | App Connect auth key (.p8), optional |


## Config File Reference (`pyside6-ios.toml`)

All keys use hyphen-case. Paths are relative to the config file's directory
unless absolute or `~`-prefixed.

### `[app]`

| Key | Required | Description |
|-----|----------|-------------|
| `name` | yes | Display name. Spaces removed for product/scheme names. |
| `bundle-id` | yes | CFBundleIdentifier (e.g., `com.example.myapp`) |
| `version` | yes | CFBundleShortVersionString |
| `entry-point` | no | Python `module:function` (currently informational) |
| `team-id` | no | Apple Developer Team ID for code signing |
| `deployment-target` | no | iOS minimum version (default: `"16.0"`) |

### `[paths]`

| Key | Required | Description |
|-----|----------|-------------|
| `pyside6-ios` | yes | Path to pyside6-ios checkout (contains `build/`) |
| `qt-ios` | yes | Path to Qt iOS SDK (e.g., `~/dev/lib/Qt-6/6.8.3/ios`) |
| `output-dir` | no | Where `.xcodeproj` is generated (default: `build/ios`) |

### `[pyside6]`

| Key | Description |
|-----|-------------|
| `modules` | List of PySide6 modules to link (e.g., `["QtCore", "QtGui", "QtWidgets"]` or `["QtCore", "QtGui", "QtQml", "QtQuick"]`) |

Each module must have a corresponding `libPySide6_<Module>.a` in
`<pyside6-ios>/build/pyside6-ios-static/`. Build these with
`scripts/build_pyside6_module.sh`.

### `[python]`

| Key | Description |
|-----|-------------|
| `packages` | Array of `{ src, exclude, as }` — app source packages |
| `vendor-dir` | Directory of pre-vendored third-party packages |
| `scripts` | List of Python scripts copied to `<bundle>/scripts/` |

**packages** entries:
- `src` (required): directory path relative to config file
- `exclude` (optional): list of rsync exclude patterns (e.g., `["*.pyc", "__pycache__", "*.so"]`)
- `as` (optional): rename the package in the bundle (e.g., `{ src = "src/mylib", as = "mylib" }`)

Packages are copied to `<bundle>/packages/<name>/`. Vendor packages go to
`<bundle>/vendor/`. Both directories are added to `sys.path` by `main.mm`.

### `[qml]`

| Key | Description |
|-----|-------------|
| `dirs` | App QML source directories — contents copied to `<bundle>/qml/` |
| `qt-modules` | Qt QML modules to bundle (e.g., `["QtQuick", "QtQml", "QtCore"]`) |

**QML plugin auto-discovery:** The tool scans each `qt-modules` entry under the
Qt iOS SDK's `qml/` directory. It parses `qmldir` files for `classname` lines,
finds the corresponding `.a` static library, and automatically:
- Adds `Q_IMPORT_PLUGIN(...)` to the generated `main.mm`
- Adds the plugin's directory to `LIBRARY_SEARCH_PATHS`
- Adds `-l<plugin>` to `OTHER_LDFLAGS`

This means you do not need to manually list QML plugins. Specifying
`qt-modules = ["QtQuick"]` auto-discovers `QtQuick2Plugin`,
`QtQuickControls2Plugin`, etc.

### `[resources]`

| Key | Description |
|-----|-------------|
| `dirs` | Directories copied to `<bundle>/app_resources/<dirname>/` |
| `files` | Glob patterns copied to `<bundle>/app_resources/` |
| `assets` | Path to `Assets.xcassets` (compiled by Xcode via PBXResourcesBuildPhase) |
| `settings-bundle` | Path to `Settings.bundle` (copied and codesigned in shell script) |

**Important:** Resources are placed under `app_resources/` in the bundle, not
`resources/`. The name `Resources` (case-insensitive on APFS) conflicts with
iOS bundle internals and causes codesign failures.

### `[sources]`

| Key | Description |
|-----|-------------|
| `main-mm` | Path to custom `main.mm`. Empty = auto-generate from config. |
| `files` | Additional C/C++/ObjC++ source files compiled by Xcode |
| `header-search-paths` | Extra include directories |
| `static-libs` | Pre-compiled `.a` files to link |

When `main-mm` is empty, the tool generates a complete `main.mm` that:
- Sets up Python with isolated config
- Registers PySide6 modules via `PyImport_AppendInittab`
- Registers custom binding modules
- Registers QML static plugins via `Q_IMPORT_PLUGIN`
- Adds search paths for scripts, packages, and vendor
- Creates `QGuiApplication`, runs the entry script, reparents Qt's view into
  a UIWindowScene-aware UIWindow

**QtWidgets apps require a custom `main.mm`** because the auto-generated
template creates `QGuiApplication`, while QtWidgets needs `QApplication`.
Copy the generated `main.mm` and change `QGuiApplication` to `QApplication`
(with `#include <QtWidgets/QApplication>`). The custom `main.mm` must also
resize top-level QWidgets after reparenting to fill the iOS screen. See
`test/test_widgets/main.mm` for a working example.

**QtWidgets entry scripts must use `showFullScreen()`** instead of `show()`.
Also note: `QLayout(parent)` constructors silently fail on iOS static PySide6 —
always use explicit `widget.setLayout(layout)`. See the porting cookbook
troubleshooting section for details.

When `main-mm` is set, the file is copied as-is. You must handle all of the
above yourself. Use the generated version as a starting template.

### `[bindings]`

| Key | Description |
|-----|-------------|
| `modules` | Array of `{ name, headers, typesystem }` for shiboken6-generated bindings |

Each module:
1. Generates a global header from `headers`
2. Runs `shiboken6` (host macOS) with the `typesystem` XML
3. Cross-compiles generated wrappers to iOS arm64
4. Archives into a static `.a` library
5. Links into the app and registers via `PyImport_AppendInittab`

Requires `shiboken6` installed on the host and `pyside-setup` sources at
`<pyside6-ios>/build/pyside-setup/`.

### `[info-plist]`

| Key | Description |
|-----|-------------|
| `file` | Path to custom `Info.plist`. Empty = generate minimal plist. |

The minimal generated plist includes `UIApplicationSceneManifest`,
`UISupportedInterfaceOrientations`, and standard bundle keys.

### `[entitlements]`

| Key | Description |
|-----|-------------|
| `file` | Path to entitlements plist (e.g., `App.entitlements`) |

Entitlements require a matching provisioning profile. For local development with
automatic signing and no special capabilities, omit this section entirely.

### `[signing]`

| Key | Description |
|-----|-------------|
| `style` | `"Automatic"` (default) or `"Manual"` |

For CI/manual signing, also set:

```toml
[signing.ci]
xcconfig = "build/ios-config/App.xcconfig"
xcconfig-debug = "build/ios-config/App-Debug.xcconfig"
xcconfig-release = "build/ios-config/App-Release.xcconfig"
```

The xcconfig files override build settings per-configuration. They are passed
to `xcodebuild -xcconfig` during `build`.

### `[build-scripts]`

| Key | Description |
|-----|-------------|
| `pre` | Shell commands run before moc/shiboken during `generate` |

Commands run with `cwd` set to the config file's directory. Use for version
stamping, code generation, or other pre-build tasks.

### `[build-settings]`

Top-level keys apply to both Debug and Release project-level configurations.
Use sub-tables for per-configuration overrides:

```toml
[build-settings]
CLANG_ENABLE_MODULES = "YES"

[build-settings.debug]
GCC_OPTIMIZATION_LEVEL = "0"

[build-settings.release]
STRIP_INSTALLED_PRODUCT = "No"
```

These are Xcode build settings applied verbatim to the generated
`XCBuildConfiguration` sections.

### `[defines]`

| Key | Description |
|-----|-------------|
| `common` | Preprocessor defines for all configurations |
| `debug` | Debug-only defines |
| `release` | Release-only defines |
| `alpha` | Alpha-version defines (planned, not yet applied) |
| `beta` | Beta-version defines (planned, not yet applied) |


## iOS App Bundle Layout

The generated Xcode project produces this bundle structure:

```
MyApp.app/
  MyApp                       # Executable (links PySide6 + shiboken static libs)
  Info.plist
  Frameworks/
    QtRuntime.framework       # All Qt static libs merged into one dynamic fw
    Python.framework          # CPython 3.13 for iOS
  lib/
    python3.13/               # Python stdlib (rsync'd from xcframework)
      lib-dynload/            # .so extension modules (codesigned)
  scripts/
    app.py                    # Entry point script
  packages/
    PySide6/                  # PySide6 package stubs (__init__.py)
    shiboken6/                # shiboken6 package stubs
    myapp/                    # App source package
  vendor/
    dateutil/                 # Third-party vendored packages
  qml/
    main.qml                 # App QML files
    QtQuick/                  # Qt QML modules (from SDK)
    QtCore/
    QtQml/
  app_resources/
    images/                   # Resource dirs from [resources] dirs
  Settings.bundle/            # iOS Settings app integration
  Assets.car                  # Compiled from Assets.xcassets by Xcode
  embedded.mobileprovision    # Placed by Xcode automatic signing
```


## Build Phases (in order)

1. **Sources** — Compile `main.mm`, custom sources, moc outputs
2. **Frameworks** — Link QtRuntime, Python, PySide6 static libs, shiboken, UIKit, Foundation
3. **Embed Frameworks** — Copy + codesign QtRuntime.framework, Python.framework
4. **Resources** — Compile Assets.xcassets (if present)
5. **Copy QML Files** — Copy QML file references (if any PBXCopyFiles entries)
6. **Copy QML Modules** — Shell script: copy Qt QML modules + app QML dirs
7. **Copy Python Stdlib** — Shell script: rsync stdlib, codesign .so files
8. **Copy Python Packages** — Shell script: rsync packages, vendor, scripts, PySide6/shiboken stubs
9. **Copy Resources** — Shell script: copy resource dirs/files, Settings.bundle (if any)
10. **CodeSign** — Xcode automatic (signs the whole bundle last)
