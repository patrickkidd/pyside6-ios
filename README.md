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

## Prerequisites

- macOS (Apple Silicon)
- Xcode 16+ with iOS 16.0+ SDK
- Qt 6.8.3 iOS + macOS SDKs
- CPython 3.13 iOS framework ([BeeWare Python-Apple-support](https://github.com/beeware/Python-Apple-support))
- PySide6 6.8.3 source (`pyside-setup`)
- shiboken6-generator (PyPI, runs on macOS host)
- `uv` for Python environment management

### Install Qt 6.8.3

```bash
uv venv .venv && source .venv/bin/activate
uv pip install aqtinstall
aqt install-qt mac ios 6.8.3 --outputdir ~/dev/lib/Qt-6
aqt install-qt mac desktop 6.8.3 --outputdir ~/dev/lib/Qt-6
```

## Build

```bash
# 1. Build QtRuntime.framework (all Qt static libs → one dynamic framework)
./scripts/build_qtruntime.sh

# 2. Cross-compile PySide6 modules for iOS arm64
./scripts/build_pyside6_module.sh QtCore
./scripts/build_pyside6_module.sh QtGui
./scripts/build_pyside6_module.sh QtNetwork
./scripts/build_pyside6_module.sh QtQml
./scripts/build_pyside6_module.sh QtQuick

# 3. Open Xcode project, build and deploy to device
open test/test_pyside6/TestPySide6.xcodeproj
```

## Repository Structure

```
scripts/
  build_qtruntime.sh          Merge Qt static libs into QtRuntime.framework
  build_pyside6_module.sh     Shiboken generation + cross-compile per module
  globalize_symbols.py        Clear N_PEXT bit for hidden-visibility re-export
  hb_stubs.cpp                Harfbuzz graph stubs (unused font subsetting)

test/
  test_pyside6/               M5: Full PySide6 QML app on iPhone
    main.mm                   Host app (ObjC++): Python + Qt init, UIView reparenting
    main.qml                  QML UI with touch interaction
    scripts/app.py            Python app using PySide6.QtQml
    packages/                 shiboken6 + PySide6 package stubs for iOS
  test_python_qml/            M4b: Python drives QML via C bridge
  test_qml/                   M2/M3: C++ QML app (no Python)
  test_qtruntime/             M1: Minimal QtRuntime.framework validation

doc/
  report-qt-company.md        Full technical report for pyside6-deploy authors
  pyside6-ios-solution.md     Original problem analysis and architecture
  plan.md                     Milestone tracking and design decisions
```

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
- **qt-inside-ios-native** — host app owns `UIApplicationMain`; Qt uses
  `QIOSEventDispatcher` (non-jumping) to integrate with `CFRunLoop`

## Status

All milestones complete. See [doc/plan.md](doc/plan.md).

| Milestone | Description | Status |
|-----------|-------------|--------|
| M1 | QtRuntime.framework builds and loads | Done |
| M2 | QML window on simulator (C++ only) | Done |
| M3 | QML window on physical iPhone | Done |
| M4a | Embed Python.framework alongside Qt | Done |
| M4b | Python drives QML via C bridge | Done |
| M4c | Cross-compile PySide6 QtCore for iOS | Done |
| M5 | Full PySide6 QML app on iPhone | Done |

## References

- [PYSIDE-2352](https://bugreports.qt.io/browse/PYSIDE-2352) — PySide6 iOS tracking issue
- [Gerrit 651061](https://codereview.qt-project.org/c/pyside/pyside-setup/+/651061) — WIP PySide6 iOS patch
- [QTBUG-85974](https://bugreports.qt.io/browse/QTBUG-85974) — Dynamic Qt for iOS
- [PEP 730](https://peps.python.org/pep-0730/) — CPython iOS support
- [qt-inside-ios-native](https://github.com/kambala-decapitator/qt-inside-ios-native) — Host app pattern
