# pyside6-ios

Working proof-of-concept: PySide6 6.8.3 running on a physical iPhone.

Qt 6.8.3, CPython 3.13, both QML and QtWidgets UIs with touch — driven
entirely from Python via PySide6. No patches to Qt or CPython. Uses the
official Qt iOS static SDK as input.

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
- **QLayout(parent) broken** — static PySide6 modules silently fail to attach
  layouts via constructor parent arg; must use explicit `widget.setLayout()`
- **QtWidgets window sizing** — `show()` produces a blank/tiny window; use
  `showFullScreen()` and resize top-level QWidgets from `main.mm` after
  reparenting the Qt UIView into the iOS UIWindow

## Non-Happy Path Architecture Support

The demo app (`test/test_pyside6`) exercises every non-trivial integration
pattern needed for a production app:

| Feature | Description | Status |
|---------|-------------|--------|
| QtRuntime.framework | All Qt static libs merged into one dynamic framework | Done |
| PySide6 static modules | QtCore, QtGui, QtWidgets, QtNetwork, QtQml, QtQuick cross-compiled | Done |
| Python stdlib | CPython 3.13 iOS framework with stdlib + lib-dynload | Done |
| QML UI | 9-tab QML controls showcase (buttons, input, selection, indicators, navigation, dialogs, lists, animation, info) | Done |
| QtWidgets UI | 10-tab widgets showcase (buttons, input, sliders, lists, layout, QGraphicsView, calendar, dialogs, custom QPainter, info) | Done |
| App packages | Python source packages bundled and importable | Done |
| Vendor packages | Third-party pure-Python deps (dateutil) vendored | Done |
| Custom C++ sources | ObjC++/C++ files compiled by Xcode (`deviceinfo.mm`) | Done |
| MOC auto-detection | Headers with `Q_OBJECT` auto-processed by moc | Done |
| Shiboken6 bindings | Custom C++ class (`AppState`) exposed to Python | Done |
| Python virtual override | Python subclass overrides C++ virtual, used in QML | Done |
| Resources | Fonts, images, Settings.bundle, Assets.xcassets | Done |
| Code signing | Automatic signing + entitlements | Done |
| Device deployment | CLI build + install via `xcrun devicectl` | Done |

See also [doc/initial-plan.md](doc/initial-plan.md) for the original milestone progression
(M1–M5).

## TL;DR — Demo on your iPhone

### Prerequisites

Requires macOS (Apple Silicon), Xcode 16+, and [uv](https://docs.astral.sh/uv/getting-started/installation/).

Set the Qt and PySide6 versions you want to use. Tested with 6.8.3; other 6.x
versions should work if a matching `shiboken6-generator` exists on PyPI.

```bash
# --- Set versions ---
QT_VERSION=6.8.3        # Qt SDK version to install
PYSIDE_VERSION=6.8.3    # Must match a shiboken6-generator release on PyPI

# Ensure xcode-select points at Xcode (not standalone Command Line Tools)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Python environment
uv venv .venv --python 3.13 && source .venv/bin/activate
uv pip install aqtinstall shiboken6-generator==$PYSIDE_VERSION

# Qt iOS + macOS SDKs (skip if you already have Qt installed)
mkdir -p ~/dev/lib/Qt-6
aqt install-qt mac ios $QT_VERSION --outputdir ~/dev/lib/Qt-6
aqt install-qt mac desktop $QT_VERSION --outputdir ~/dev/lib/Qt-6

# Point build scripts at your Qt install
export QT_IOS="$HOME/dev/lib/Qt-6/$QT_VERSION/ios"
# If you installed Qt via the Qt Maintenance Tool instead of aqtinstall:
#   export QT_IOS="$HOME/Qt/$QT_VERSION/ios"

# CPython 3.13 iOS framework (pre-built via PEP 730)
mkdir -p build/python && curl -L https://github.com/beeware/Python-Apple-support/releases/download/3.13-b13/Python-3.13-iOS-support.b13.tar.gz | tar -xz -C build/python/

# PySide6 sources (branch must match PYSIDE_VERSION)
git clone --branch v$PYSIDE_VERSION https://code.qt.io/pyside/pyside-setup.git build/pyside-setup
```

### Build and deploy

**Manual step** — Connect your iPhone via USB, unlock it, and trust the
computer.

```bash
# Install the build tool
uv pip install -e .

# Build QtRuntime.framework (~5 min first time)
./scripts/build_qtruntime.sh

# Cross-compile support libraries: libshiboken6, libpyside6, libpysideqml (~2 min)
./scripts/build_support_libs.sh

# Cross-compile PySide6 modules (~10 min first time)
for mod in QtCore QtGui QtWidgets QtNetwork QtQml QtQuick; do
    ./scripts/build_pyside6_module.sh $mod
done

# Find your device IDs (two different ID systems — see note below)
xcrun xctrace list devices          # UDID for xcodebuild --destination
xcrun devicectl list devices        # CoreDevice UUID for xcrun devicectl

# --- QML demo ---
cd test/test_pyside6
uv run pyside6-ios -c pyside6-ios.toml build \
    --configuration Debug \
    --destination 'id=XCODE_UDID' \
    --install
xcrun devicectl device process launch \
    --device COREDEVICE_UUID \
    --console com.alaskafamilysystems.test-pyside6

# --- QtWidgets demo ---
cd ../test_widgets
uv run pyside6-ios -c pyside6-ios.toml build \
    --configuration Debug \
    --destination 'id=XCODE_UDID' \
    --install
xcrun devicectl device process launch \
    --device COREDEVICE_UUID \
    --console com.alaskafamilysystems.test-widgets
```

**Manual step** — If this is your first deploy, you may need to trust the
developer certificate on the device: Settings > General > VPN & Device
Management > tap your developer profile > Trust.


## Repository Structure

```
scripts/
  build_qtruntime.sh          Merge Qt static libs into QtRuntime.framework
  build_support_libs.sh       Cross-compile libshiboken6, libpyside6, libpysideqml + shiboken wrapper
  build_pyside6_module.sh     Shiboken generation + cross-compile per module
  globalize_symbols.py        Clear N_PEXT bit for hidden-visibility re-export

test/
  test_pyside6/               Full PySide6 QML app on iPhone (M5)
    pyside6-ios.toml          Build config for Xcode project generation
    main.mm                   Host app (ObjC++): Python + Qt init, UIView reparenting
    qml/                      QML UI (SwipeView with controls, lists, info)
  test_widgets/               Full PySide6 QtWidgets app on iPhone (M6)
    pyside6-ios.toml          Build config (QtCore + QtGui + QtWidgets)
    main.mm                   Host app (ObjC++): QApplication, shiboken bindings
    myapp/pages.py            10-tab widget showcase incl. QGraphicsView, QPainter
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
- **[test/test_pyside6/pyside6-ios.toml](test/test_pyside6/pyside6-ios.toml)** — working QML example config
- **[test/test_widgets/pyside6-ios.toml](test/test_widgets/pyside6-ios.toml)** — working QtWidgets example config

```bash
uv run pytest tests/ -v
```

## References

- [PYSIDE-2352](https://bugreports.qt.io/browse/PYSIDE-2352) — PySide6 iOS tracking issue
- [Gerrit 651061](https://codereview.qt-project.org/c/pyside/pyside-setup/+/651061) — WIP PySide6 iOS patch
- [QTBUG-85974](https://bugreports.qt.io/browse/QTBUG-85974) — Dynamic Qt for iOS
- [PEP 730](https://peps.python.org/pep-0730/) — CPython iOS support
- [qt-inside-ios-native](https://github.com/kambala-decapitator/qt-inside-ios-native) — Host app pattern
