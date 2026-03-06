# pyside6-ios

Working proof-of-concept: PySide6 6.8.3 running on a physical iPhone.

Qt 6.8.3, CPython 3.13, QML UI with touch — driven entirely from Python via
`PySide6.QtQml`. No patches to Qt or CPython. Uses the official Qt iOS static
SDK as input.

## The Problem

PySide6 on iOS is blocked by duplicate symbols (PYSIDE-2352, Gerrit 651061).
Qt 6 ships only static libraries for iOS. When each PySide6 module absorbs
static Qt code into a separate dynamic library, symbols duplicate across
images. This is architecturally inevitable — no amount of post-link stripping
fixes it.

## The Solution

Merge all Qt static libraries into a **single dynamic framework**
(`QtRuntime.framework`). PySide6 modules are cross-compiled as static libraries
and linked into the host executable, registered as Python built-in modules via
`PyImport_AppendInittab`. Qt code exists in exactly one place.

See **[doc/report-qt-company.md](doc/report-qt-company.md)** for the full
technical report: root cause analysis, every pitfall encountered, and what
`pyside6-deploy` needs to change to support iOS.

## Key Technical Details

The report covers these in depth, but briefly:

- **N_PEXT globalization** — Qt's `-fvisibility=hidden` must be undone at the
  Mach-O level before re-exporting from a dynamic framework
- **Module naming** — `PyModuleDef.m_name` must be `"PySide6.QtCore"` (not
  `"QtCore"`) for type resolution to work
- **Lazy loading** — `shouldLazyLoad()` needs a `"Qt"` prefix check for
  built-in module names
- **Metatype instantiations** — extern templates in `qmetatype.h` need explicit
  local instantiations to avoid arm64 linker errors
- **QProcess exclusion** — `QT_CONFIG(process)` is false on iOS; generated
  wrappers and headers need patching
- **qt-inside-ios-native** — host app owns `UIApplicationMain`; Qt uses
  `QIOSEventDispatcher` (non-jumping) to integrate with `CFRunLoop`

## Non-Happy Path Architecture Support

The demo app (`test/test_pyside6`) exercises every non-trivial integration
pattern needed for a production app:

| Feature | Description | Status |
|---------|-------------|--------|
| QtRuntime.framework | All Qt static libs merged into one dynamic framework | Done |
| PySide6 static modules | QtCore, QtGui, QtNetwork, QtQml, QtQuick cross-compiled | Done |
| Python stdlib | CPython 3.13 iOS framework with stdlib + lib-dynload | Done |
| QML UI | 9-tab controls showcase (buttons, input, selection, indicators, navigation, dialogs, lists, animation, info) | Done |
| App packages | Python source packages bundled and importable | Done |
| Vendor packages | Third-party pure-Python deps (dateutil) vendored | Done |
| Custom C++ sources | ObjC++/C++ files compiled by Xcode (`deviceinfo.mm`) | Done |
| MOC auto-detection | Headers with `Q_OBJECT` auto-processed by moc | Done |
| Shiboken6 bindings | Custom C++ class (`AppState`) exposed to Python | Done |
| Python virtual override | Python subclass overrides C++ virtual, used in QML | Done |
| Resources | Fonts, images, Settings.bundle, Assets.xcassets | Done |
| Code signing | Automatic signing + entitlements | Done |
| Device deployment | CLI build + install via `xcrun devicectl` | Done |

See also [doc/plan.md](doc/plan.md) for the original milestone progression
(M1–M5).

## TL;DR — Demo on your iPhone

### Prerequisites (one-time, ~30 min)

1. macOS (Apple Silicon) with Xcode 16+ from the App Store
2. Install [uv](https://docs.astral.sh/uv/getting-started/installation/)
3. Install Qt 6.8.3 iOS + macOS SDKs:
   ```bash
   uv venv .venv && source .venv/bin/activate
   uv pip install aqtinstall
   aqt install-qt mac ios 6.8.3 --outputdir ~/dev/lib/Qt-6
   aqt install-qt mac desktop 6.8.3 --outputdir ~/dev/lib/Qt-6
   ```
4. Download [CPython 3.13 iOS framework](https://github.com/beeware/Python-Apple-support/releases) and extract to `build/python/`
5. Clone [pyside-setup](https://code.qt.io/cgit/pyside/pyside-setup.git/) sources to `build/pyside-setup/`
6. Install shiboken6-generator: `uv pip install shiboken6-generator`

### Build and deploy

**Manual step** — Connect your iPhone via USB and trust the computer.

```bash
# Install the build tool
uv pip install -e .

# Build QtRuntime.framework (~5 min first time)
./scripts/build_qtruntime.sh

# Cross-compile PySide6 modules (~10 min first time)
for mod in QtCore QtGui QtNetwork QtQml QtQuick; do
    ./scripts/build_pyside6_module.sh $mod
done

# Find your device UUID
xcrun devicectl list devices

# Build, deploy to your iPhone
cd test/test_pyside6
uv run pyside6-ios -c pyside6-ios.toml build \
    --configuration Debug \
    --destination 'id=YOUR_DEVICE_UUID' \
    --install

# Launch with console output
xcrun devicectl device process launch \
    --device YOUR_DEVICE_UUID \
    --console com.alaskafamilysystems.test-pyside6
```

**Manual step** — If this is your first deploy, you may need to trust the
developer certificate on the device: Settings > General > VPN & Device
Management > tap your developer profile > Trust.


## Repository Structure

```
scripts/
  build_qtruntime.sh          Merge Qt static libs into QtRuntime.framework
  build_pyside6_module.sh     Shiboken generation + cross-compile per module
  globalize_symbols.py        Clear N_PEXT bit for hidden-visibility re-export

test/
  test_pyside6/               Full PySide6 QML app on iPhone (M5)
    pyside6-ios.toml          Build config for Xcode project generation
    main.mm                   Host app (ObjC++): Python + Qt init, UIView reparenting
    qml/                      QML UI (SwipeView with controls, lists, info)
  test_python_qml/            M4b: Python drives QML via C bridge
  test_qml/                   M2/M3: C++ QML app (no Python)
  test_qtruntime/             M1: Minimal QtRuntime.framework validation

src/pyside6_ios/              Build tool (see below)
tests/                        Build tool unit tests

doc/
  report-qt-company.md        Full technical report for pyside6-deploy authors
  pyside6-ios-solution.md     Original problem analysis and architecture
```

## Build Tool

The `pyside6-ios` CLI generates Xcode projects from a TOML config file. It
handles framework linking, Python stdlib bundling, QML plugin static
registration, shiboken6 custom bindings, code signing, and device deployment.

```bash
pyside6-ios -c config.toml generate              # Generate .xcodeproj
pyside6-ios -c config.toml build --install        # Generate + build + deploy
pyside6-ios -c config.toml clean                  # Remove output dir
```

Documentation:
- **[doc/build-tool-reference.md](doc/build-tool-reference.md)** — config file reference, commands, bundle layout
- **[doc/porting-cookbook.md](doc/porting-cookbook.md)** — step-by-step guide for porting an existing app
- **[test/test_pyside6/pyside6-ios.toml](test/test_pyside6/pyside6-ios.toml)** — working example config

```bash
uv run pytest tests/ -v
```

## References

- [PYSIDE-2352](https://bugreports.qt.io/browse/PYSIDE-2352) — PySide6 iOS tracking issue
- [Gerrit 651061](https://codereview.qt-project.org/c/pyside/pyside-setup/+/651061) — WIP PySide6 iOS patch
- [QTBUG-85974](https://bugreports.qt.io/browse/QTBUG-85974) — Dynamic Qt for iOS
- [PEP 730](https://peps.python.org/pep-0730/) — CPython iOS support
- [qt-inside-ios-native](https://github.com/kambala-decapitator/qt-inside-ios-native) — Host app pattern
