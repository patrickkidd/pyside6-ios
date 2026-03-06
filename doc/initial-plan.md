# pyside6-ios: Build Plan

**Goal:** Demo Qt/QML app running on Patrick's physical iPhone.

## Problem
PySide6 on iOS is blocked by duplicate symbols. Qt 6 ships only static libraries for iOS.
PySide6 modules must be separate dynamic `.framework` bundles (iOS + CPython requirement).
When each module absorbs static Qt code, symbols duplicate across frameworks.

## Solution: QtRuntime.framework
Merge all Qt static libs into a single dynamic framework. PySide6 modules link against it
dynamically. Zero duplication by construction.

## Qt 6.8.3 iOS SDK Layout (Validated)
- **Static frameworks**: `~/dev/lib/Qt-6/6.8.3/ios/lib/Qt*.framework/` — universal archives (x86_64 + arm64)
- **Platform plugin**: `ios/plugins/platforms/libqios.a`
- **Bundled deps**: `ios/lib/libQt6Bundled*.a` (freetype, harfbuzz, libjpeg, libpng, pcre2)
- **Symbol visibility**: confirmed default (16k+ global `T` symbols in QtCore alone)

## Architecture
```
YourApp.app/
├── YourApp                          (host executable)
├── Frameworks/
│   ├── Python.framework/            (CPython 3.13+)
│   ├── QtRuntime.framework/         (ALL Qt merged into ONE dynamic framework)
│   ├── QtCore.abi3.framework/       (PySide6 module, links QtRuntime dynamically)
│   ├── QtGui.abi3.framework/
│   └── ...
└── lib/python3.13/
```

## Milestones

### M1: QtRuntime.framework builds and loads [DONE]
- [x] Install Qt 6.8.3 iOS SDK via aqt
- [x] Verify symbol visibility (PASS — not a risk)
- [x] Build QtRuntime.framework from static frameworks + plugins
- [x] C++ test app creates QCoreApplication on simulator

### M2: QML window on simulator (C++ only, no Python yet) [DONE]
- [x] C++ app shows a QML window via QtRuntime.framework on simulator
- [x] Validates QtQuick, rendering pipeline, qios platform plugin all work

### M3: QML window on physical iPhone [DONE]
- [x] Same app, code-signed and deployed to device
- [x] QtRuntime.framework works end-to-end on real hardware

### M4a: Embed Python.framework alongside Qt [DONE]
- [x] BeeWare Python-Apple-support 3.13-b13 provides Python.xcframework
- [x] Python initializes and runs scripts on iPhone

### M4b: Python drives QML via C bridge [DONE]
- [x] qtbridge C extension module provides Python→Qt bridge
- [x] Python script loads QML and sets context properties

### M4c: Cross-compile PySide6 QtCore for iOS [DONE — 2026-03-05]
- [x] Run shiboken6 generator for QtCore C++ wrappers
- [x] Cross-compile libshiboken6.a for arm64 (25 source files)
- [x] Cross-compile libpyside6.a for arm64 (18 source files)
- [x] Cross-compile QtCore wrappers for arm64 (~188 source files)
- [x] Register PySide6.QtCore as built-in module via PyImport_AppendInittab
- [x] Successfully import PySide6.QtCore and use QUrl, QPoint, QSize on iPhone
- [x] QML UI displays PySide6 version info

### M5: Full PySide6 QML app on iPhone [DONE — 2026-03-05]
- [x] Cross-compile PySide6 QtGui, QtNetwork, QtQml, QtQuick for iOS arm64
- [x] Python script creates QGuiApplication and loads QML directly (no qtbridge)
- [x] Remove qtbridge dependency — PySide6 drives everything
- [x] QML UI renders and responds to touch on physical iPhone

### M6: Full PySide6 QtWidgets app on iPhone [DONE — 2026-03-06]
- [x] Add QtWidgets case to build_pyside6_module.sh (include paths, setAsDockMenu iOS patch)
- [x] Cross-compile PySide6 QtWidgets for iOS arm64 (194/194 wrappers, 17M)
- [x] Custom main.mm using QApplication (not QGuiApplication)
- [x] 10-tab widget showcase: buttons, input, sliders, lists, containers, QGraphicsView, calendar, dialogs, custom QPainter, info
- [x] Same native C++/Obj-C/shiboken binding pattern as QML demo
- [x] Build tool generates and builds Xcode project with zero changes to build tool code

## Key Design Decisions

### Host App Pattern: qt-inside-ios-native
Host app owns UIApplicationMain. Qt uses QIOSEventDispatcher (non-jumping) to integrate with
the already-running CFRunLoop. Avoids qt_main_wrapper / setjmp/longjmp entirely.

### -Wl,-U,_main for libqios.a
The qios platform plugin references `main()` at link time. Since QtRuntime.framework is a
dylib (no main), use `-Wl,-U,_main` to leave it unresolved. It won't be called — the host
app already owns the lifecycle.

### Framework vs Plain .a
Qt 6.8.3 iOS ships modules as static `.framework` bundles, not plain `.a`. The build script
must use `-force_load` on the framework binary path (e.g.
`QtCore.framework/QtCore`), extracting the arm64 slice first via `lipo`.

### PySide6 Module Name on iOS
PyModuleDef m_name must be "PySide6.QtCore" (not bare "QtCore") because TypeInitStruct.fullName
references types as "PySide6.QtCore.QFoo". Module::get() needs to find "PySide6.QtCore" in
sys.modules to resolve base types during lazy loading.

## Risks (Updated)

| Risk | Status | Notes |
|------|--------|-------|
| Symbol visibility | **RESOLVED** | Default visibility confirmed in Qt 6.8.3 |
| QIOSEventDispatcher | **RESOLVED** | qt-inside-ios-native pattern works |
| Shiboken cross-compilation | **RESOLVED** | Manual cross-compile pipeline works |
| Qt plugin loading | **RESOLVED** | libqios.a force-loaded → auto-registers |
| PySide6 lazy loading | **RESOLVED** | shouldLazyLoad() needed "Qt*" prefix check |
| App Store rejection | Low | Dynamic frameworks are standard since iOS 8 |
