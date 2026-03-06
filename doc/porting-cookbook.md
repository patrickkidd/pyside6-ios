# Porting an Existing PySide6 App to iOS

Step-by-step guide for porting a desktop PySide6/QML application to iOS using
`pyside6-ios`. Assumes the app's Python code already works with PySide6/Qt 6.

## Prerequisites

Before starting, you need working builds of:
- **QtRuntime.framework** — `./scripts/build_qtruntime.sh`
- **PySide6 static modules** — one `./scripts/build_pyside6_module.sh <Module>` per module your app imports
- **Python.xcframework** — BeeWare's CPython 3.13 for iOS (already in `build/python/`)


## Step 1: Create the project directory

```
myapp-ios/
  pyside6-ios.toml        # Build config (this is what you're writing)
  Info.plist               # iOS app metadata
  Assets.xcassets/         # App icon
  myapp/                   # Your Python source (symlink or copy)
  vendor/                  # Third-party deps
  scripts/
    app.py                 # Entry point script
```

The config file's directory is the project root. All relative paths in the
config resolve from here.


## Step 2: Identify your PySide6 modules

List every `PySide6.*` import in your codebase:

```bash
grep -rh "from PySide6" myapp/ | sed 's/from PySide6.\([A-Za-z]*\).*/\1/' | sort -u
```

Each unique module name must appear in `[pyside6] modules` and must have been
cross-compiled via `build_pyside6_module.sh`. If you find a module that hasn't
been cross-compiled yet, build it before proceeding.

```toml
# QML app:
[pyside6]
modules = ["QtCore", "QtGui", "QtNetwork", "QtQml", "QtQuick"]

# QtWidgets app:
[pyside6]
modules = ["QtCore", "QtGui", "QtWidgets"]
```


## Step 3: Vendor your Python dependencies

iOS has no `pip install` at runtime. All third-party packages must be
pre-vendored:

```bash
pip install --target=vendor/ dateutil sortedcontainers pydantic
```

Remove any packages that contain compiled C extensions (`.so`/`.pyd` files) —
these won't work on iOS arm64 unless you cross-compile them separately. Pure
Python packages work as-is.

```toml
[python]
vendor-dir = "vendor"
```

Check what you vendored:

```bash
find vendor/ -name "*.so" -o -name "*.pyd"
```

If any results, those packages need either: a pure-Python alternative, a
cross-compiled iOS build, or removal (if the feature isn't needed on iOS).


## Step 4: Set up your Python packages

List your app's own source packages. Use `exclude` to skip files that bloat
the bundle or fail on iOS:

```toml
[python]
packages = [
    { src = "myapp", exclude = ["*.pyc", "__pycache__", "*.so", "build", "doc", "tests"] },
]
```

If your package directory name differs from the import name, use `as`:

```toml
packages = [
    { src = "src/pkdiagram", as = "pkdiagram" },
]
```


## Step 5: Write the entry point script

Create `scripts/app.py`. This is what `main.mm` runs via `PyRun_SimpleFile`.
It must:
1. Import your app's main module
2. Get the existing application instance (created by `main.mm`)
3. Set up the UI (QML engine or QtWidgets)

**QML app:**

```python
import sys, os
bundle = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

app = QGuiApplication.instance()
engine = QQmlApplicationEngine()
engine.addImportPath(os.path.join(bundle, "qml"))
engine.load(QUrl.fromLocalFile(os.path.join(bundle, "qml", "main.qml")))
```

**QtWidgets app:**

```python
import sys, os
from PySide6.QtWidgets import QApplication, QMainWindow, QTabWidget

app = QApplication.instance()
win = QMainWindow()
# ... build your widget UI ...
win.showFullScreen()  # NOT win.show() — see iOS pitfalls below
```

```toml
[python]
scripts = ["scripts/app.py"]
```


## Step 6: QML files (QML apps only)

Skip this step for QtWidgets-only apps — omit the `[qml]` section entirely.

Copy or symlink your QML directory. List the Qt QML modules your QML imports:

```bash
grep -rh "^import " myapp/qml/ | sed 's/import \([A-Za-z.]*\).*/\1/' | sort -u
```

```toml
[qml]
dirs = ["myapp/qml"]
qt-modules = ["QtQuick", "QtQml", "QtCore"]
```

The tool auto-discovers QML static plugins from these modules. You do not need
to manually list `Q_IMPORT_PLUGIN` entries — the generated `main.mm` (or the
`OTHER_LDFLAGS` if using a custom `main.mm`) handles this.

**If using a custom main.mm**, you must add `Q_IMPORT_PLUGIN(...)` for each
discovered plugin yourself. Generate once without a custom main.mm, inspect the
generated `main.mm` to see which plugins are needed, then copy those lines into
your custom version.


## Step 7: Resources

### Images, data files, help content

```toml
[resources]
dirs = ["myapp/resources/images", "myapp/resources/help"]
files = ["myapp/resources/fonts/*"]
```

These are copied into `<bundle>/app_resources/` by a shell script build phase.
Access them at runtime:

```python
import os
bundle = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
images_dir = os.path.join(bundle, "app_resources", "images")
```

**Warning:** The directory is named `app_resources`, not `resources`. The name
`Resources` (case-insensitive on APFS) collides with iOS bundle internals and
causes codesign failures.

### App icon (Assets.xcassets)

Create a minimal asset catalog:

```
Assets.xcassets/
  Contents.json             # { "info": { "version": 1, "author": "xcode" } }
  AppIcon.appiconset/
    Contents.json           # Icon sizes manifest
    icon-1024.png           # Single 1024x1024 icon (Xcode generates all sizes)
```

```toml
[resources]
assets = "Assets.xcassets"
```

### Settings.bundle

For apps that expose settings in the iOS Settings app:

```
Settings.bundle/
  Info.plist                # Must contain CFBundlePackageType = BNDL
  Root.plist                # Settings schema
```

The `Info.plist` inside Settings.bundle must contain:

```xml
<key>CFBundlePackageType</key>
<string>BNDL</string>
```

Without this, Xcode won't recognize it as a valid bundle and codesign fails.

```toml
[resources]
settings-bundle = "Settings.bundle"
```


## Step 8: Custom C++ sources

If your app has C/C++/ObjC++ code compiled alongside the Python app:

```toml
[sources]
files = ["native/unsafearea.cpp", "native/platform_mac.mm"]
header-search-paths = ["native"]
```

These files are added to Xcode's Sources build phase. Headers containing
`Q_OBJECT` are automatically detected and processed with `moc`.

### Pre-compiled static libraries

```toml
[sources]
static-libs = ["lib/libmyhelper.a"]
```


## Step 9: Custom shiboken bindings

If your app has custom C++ classes exposed to Python via shiboken6:

```toml
[bindings]
modules = [
    {
        name = "_mymodule",
        headers = ["native/myclass.h", "native/unsafearea.h"],
        typesystem = "native/typesystem_mymodule.xml"
    },
]
```

This requires:
- `shiboken6` installed on the host (`pip install shiboken6-generator`)
- PySide6 sources at `<pyside6-ios>/build/pyside-setup/sources/`
- A valid typesystem XML file describing your C++ API

The tool will:
1. Generate wrapper `.cpp` files using shiboken6
2. Cross-compile them for iOS arm64
3. Archive into `lib_mymodule.a`
4. Link into the app executable
5. Register via `PyImport_AppendInittab("_mymodule", PyInit_mymodule)`

### Writing typesystem XML

Minimal example for a class `UnsafeArea`:

```xml
<?xml version="1.0"?>
<typesystem package="_mymodule">
    <load-typesystem name="typesystem_core.xml" generate="no"/>
    <load-typesystem name="typesystem_gui.xml" generate="no"/>

    <object-type name="UnsafeArea"/>
</typesystem>
```


## Step 10: Info.plist

Provide your own or let the tool generate a minimal one:

```toml
[info-plist]
file = "Info.plist"
```

Key entries for iOS apps:

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict/>
</dict>
<key>UIRequiresFullScreen</key>
<true/>
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

The scene manifest with empty `UISceneConfigurations` is required — the
`SceneDelegate` in `main.mm` is registered programmatically, not via plist.


## Step 11: Entitlements and signing

### Local development (automatic signing)

```toml
[signing]
style = "Automatic"
```

If your app uses no special capabilities (no iCloud, no push notifications),
omit the `[entitlements]` section entirely. Xcode generates default entitlements.

If you do need capabilities:

```toml
[entitlements]
file = "App.entitlements"
```

The entitlements file must match what your provisioning profile allows.

### CI signing

```toml
[signing]
style = "Manual"

[signing.ci]
xcconfig = "build/ios-config/App.xcconfig"
xcconfig-debug = "build/ios-config/App-Debug.xcconfig"
xcconfig-release = "build/ios-config/App-Release.xcconfig"
```

Set environment variables for `setup-keychain`:

```bash
export CERTIFICATE_BASE64=$(base64 < cert.p12)
export PRIVATE_KEY_BASE64=$(base64 < key.pem)
export CERTIFICATE_PASSWORD="..."
export PROVISIONING_PROFILE_BASE64=$(base64 < profile.mobileprovision)

pyside6-ios -c pyside6-ios.toml setup-keychain
pyside6-ios -c pyside6-ios.toml build --configuration Release
pyside6-ios -c pyside6-ios.toml teardown-keychain
```


## Step 12: Pre-build scripts

For version stamping, code generation, or other pre-build tasks:

```toml
[build-scripts]
pre = ["python3 bin/update_build_info.py"]
```

Scripts run with `cwd` set to the project root (config file directory), before
moc and shiboken. Use them to generate files that will be included in the build.


## Step 13: Custom main.mm vs. auto-generated

### Auto-generated (recommended for most apps)

Leave `main-mm` empty or omit it:

```toml
[sources]
# main-mm not set — auto-generated
```

The generated `main.mm` handles all boilerplate: Python init, PySide6 module
registration, QML plugin registration, search paths, Qt/UIKit integration.

### Custom main.mm

Set `main-mm` to your file:

```toml
[sources]
main-mm = "main.mm"
```

You need a custom `main.mm` when:
- **Your app uses QtWidgets** (must use `QApplication` instead of `QGuiApplication`)
- Your app needs custom ObjC++ initialization (e.g., `qputenv` for QML style)
- You have app-specific Qt setup before Python runs
- You need to handle multiple entry points or configurations

Start by generating once without `main-mm`, then copy and modify the output.
The critical pieces you must preserve:
- `Q_IMPORT_PLUGIN(QIOSIntegrationPlugin)` — always required
- `Q_IMPORT_PLUGIN(...)` for each QML plugin — check generated `main.mm` or
  pass `--verbose` to see which plugins were discovered
- `PyImport_AppendInittab(...)` for each PySide6 module
- `PyConfig_InitIsolatedConfig` with `module_search_paths_set = 1`
- Search paths for stdlib, lib-dynload, scripts, packages, vendor
- `UIWindowScene`-aware `UIWindow` creation (the SceneDelegate pattern)
- Qt view reparenting via `QWindow::winId()` → `UIView` → `addSubview`


## Step 14: Build settings and defines

```toml
[build-settings]
CLANG_ENABLE_MODULES = "YES"
ENABLE_HARDENED_RUNTIME = "Yes"

[build-settings.debug]
GCC_OPTIMIZATION_LEVEL = "0"

[defines]
common = ["MY_APP=1"]
debug = ["DEBUG=1"]
release = []
```


## Step 15: Generate, build, and deploy

```bash
# Generate Xcode project only
pyside6-ios -c pyside6-ios.toml generate

# Build and install on a connected device
pyside6-ios -c pyside6-ios.toml build \
  --configuration Debug \
  --destination 'id=DEVICE_UUID' \
  --install

# Or open in Xcode for debugging (Cmd+R builds, installs, and launches)
open <output-dir>/MyApp.xcodeproj
```

**Note:** Without `--install`, `xcodebuild build` only compiles — it does not
deploy to the device. The `--install` flag uses `xcrun devicectl device install
app` to deploy the built `.app` after a successful build.

Find your device UUID with:

```bash
xcrun devicectl list devices
```

### Launching and viewing logs

Neither `xcodebuild` nor `--install` launch the app. To launch with console
output:

```bash
xcrun devicectl device process launch \
  --device DEVICE_UUID --console com.example.myapp
```

Alternatively, tail the device system log while manually tapping the app:

```bash
idevicesyslog  # from libimobiledevice (brew install libimobiledevice)
```

Xcode's Run (Cmd+R) is the easiest option — it builds, installs, launches, and
shows console output in the debug console.


## Complete Example: Complex QML App

This config exercises every feature. Modeled on a real production app with QML
UI, custom C++ bindings, vendor deps, resource bundles, and CI signing.
For a QtWidgets example, see `test/test_widgets/pyside6-ios.toml`.

```toml
[app]
name = "Family Diagram"
bundle-id = "com.vedanamedia.familydiagram"
version = "2.1.23"
entry-point = "pkdiagram.main:main"
team-id = "8KJB799CU7"
deployment-target = "16.0"

[paths]
pyside6-ios = "~/dev/lib/pyside6-ios"
qt-ios = "~/dev/lib/Qt-6/6.8.3/ios"
output-dir = "build/ios"

[pyside6]
modules = ["QtCore", "QtGui", "QtNetwork", "QtQml", "QtQuick"]

[python]
packages = [
    { src = "pkdiagram", exclude = ["*.pyc", "__pycache__", "*.so", "build", "doc"] },
]
vendor-dir = "vendor/"
scripts = ["scripts/app.py"]

[qml]
dirs = ["pkdiagram/resources/qml"]
qt-modules = ["QtQuick", "QtQml", "QtCore"]

[resources]
dirs = ["pkdiagram/resources/misc", "pkdiagram/resources/help-tips"]
files = ["pkdiagram/resources/fonts/*"]
assets = "Assets.xcassets"
settings-bundle = "Settings.bundle"

[sources]
files = ["_pkdiagram/unsafearea.cpp", "_pkdiagram/_pkdiagram_mac.mm"]
header-search-paths = ["_pkdiagram"]

[bindings]
modules = [
    {
        name = "_pkdiagram",
        headers = ["_pkdiagram/_pkdiagram.h", "_pkdiagram/unsafearea.h"],
        typesystem = "_pkdiagram/typesystem_pkdiagram.xml"
    },
]

[info-plist]
file = "Info.plist"

[entitlements]
file = "build/ios-config/Family Diagram.entitlements"

[signing]
style = "Automatic"

[signing.ci]
xcconfig = "build/ios-config/Family-Diagram.xcconfig"
xcconfig-debug = "build/ios-config/Family-Diagram-Debug.xcconfig"
xcconfig-release = "build/ios-config/Family-Diagram-Release.xcconfig"

[build-scripts]
pre = ["python3 bin/update_build_info.py"]

[build-settings]
ENABLE_HARDENED_RUNTIME = "Yes"
CLANG_ENABLE_MODULES = "Yes"
CLANG_ENABLE_OBJC_ARC = "Yes"
DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"

[defines]
common = []
debug = ["DEBUG=1"]
```


## Troubleshooting

### `embedded.mobileprovision: code object is not signed at all`

You have a directory named `resources/` or `Resources/` inside the app bundle.
Rename it — the build tool uses `app_resources/` for this reason. If you have
a custom shell script or build phase that creates a `resources/` dir, rename it.

### `Q_IMPORT_PLUGIN: undefined symbol`

A QML plugin's static library wasn't found or linked. Check:
1. The plugin's `.a` file exists in the Qt SDK's `qml/<Module>/` directory
2. `qt-modules` in your config includes the parent module
3. If using a custom `main.mm`, verify the `Q_IMPORT_PLUGIN` lines match the
   auto-generated version

### `PyImport_AppendInittab` — module not found at runtime

The `m_name` in the module's `PyModuleDef` must use the dotted form:
`"PySide6.QtCore"`, not `"QtCore"`. This is handled by the pyside6-ios cross-
compilation scripts. If you see `ModuleNotFoundError`, check that the static
lib was built with the correct module name.

### `Settings.bundle: bundle format unrecognized`

The `Settings.bundle/Info.plist` must contain:
```xml
<key>CFBundlePackageType</key>
<string>BNDL</string>
```

### Vendor package with C extensions fails

Pure-Python packages work as-is. Packages with compiled extensions (`.so` files)
need cross-compilation for iOS arm64, which is a separate effort per package.
Check for pure-Python alternatives or remove the dependency on iOS.

### QML files not found at runtime

Verify:
1. `engine.addImportPath(os.path.join(bundle, "qml"))` in your entry script
2. QML files are in a `dirs` entry under `[qml]`
3. Qt QML modules are listed in `qt-modules`

### QtWidgets: blank screen or tiny window

On iOS, `QMainWindow.show()` does not fill the screen — Qt doesn't own the
display in the qt-inside-ios-native pattern. Use `win.showFullScreen()` instead.
The host `main.mm` also resizes top-level QWidgets after reparenting the Qt view
into the iOS UIWindow. See `test/test_widgets/main.mm` for the pattern.

### QtWidgets: layouts not working (widgets scrunched to upper-left)

**Critical iOS PySide6 bug:** `QLayout(parent)` constructor calls silently fail
to attach the layout to the parent widget when PySide6 modules are statically
linked. This affects all layout types (`QVBoxLayout`, `QHBoxLayout`,
`QGridLayout`, `QFormLayout`).

**Do not use:**
```python
layout = QVBoxLayout(self)      # BROKEN on iOS static PySide6
g = QGridLayout(groupBox)       # BROKEN on iOS static PySide6
```

**Use instead:**
```python
layout = QVBoxLayout()
self.setLayout(layout)          # explicit setLayout works correctly

g = QGridLayout()
groupBox.setLayout(g)           # explicit setLayout works correctly
```

This applies to every widget that needs a layout, including QGroupBox,
QScrollArea inner widgets, and any custom QWidget subclass.

### xcodebuild: scheme not found

The tool generates an xcscheme automatically. If `xcodebuild -scheme` fails,
check that the scheme name matches the product name (app name with spaces
removed).
