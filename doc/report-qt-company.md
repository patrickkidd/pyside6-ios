# PySide6 on iOS: Root Cause Analysis and Working Solution

**Date:** 2026-03-05
**Author:** Patrick Stinson (Alaska Family Systems)
**Status:** Demonstrated on physical iPhone — PySide6 6.8.3 + Qt 6.8.3 + CPython 3.13

## Executive Summary

PySide6 on iOS has been blocked since mid-2025 by duplicate symbol errors
(PYSIDE-2352, Gerrit 651061). This report documents the root cause and a
working solution that was validated end-to-end on a physical iPhone: a QML app
driven entirely by Python via PySide6.QtQml, with touch interaction, running on
Qt 6.8.3 and CPython 3.13.

The fundamental issue is architectural, not implementational. The current
approach of building each PySide6 module as a separate dynamic library that
absorbs static Qt code is structurally guaranteed to produce duplicate symbols.
The solution is to merge Qt's static iOS libraries into a single dynamic
framework (QtRuntime.framework) and link PySide6 modules against it statically
into the host executable. This eliminates duplication by construction.

---

## 1. Root Cause: Why Duplicate Symbols Are Inevitable

### The Constraint Triangle

Three constraints interact to make the current approach impossible:

1. **Qt 6 iOS ships only static libraries.** Qt's CMake enforces
   `BUILD_SHARED_LIBS=OFF` on iOS with a `FATAL_ERROR`.

2. **PySide6 modules are separate dynamic libraries.** Each module
   (QtCore.abi3.so, QtGui.abi3.so, etc.) is a CPython extension that must be
   independently loadable.

3. **Static libraries are absorbed into whatever links them.** When
   QtCore.abi3.so and QtGui.abi3.so each link QtCore.a, each one gets its own
   copy of every symbol from QtCore.a.

When the app loads both modules at runtime, the dynamic linker sees the same
symbols (particularly ObjC classes like `_OBJC_CLASS_$_RunLoopModeTracker` and
`_OBJC_CLASS_$_KeyValueObserver`) in multiple images. This is a fatal error on
iOS — there is no `-force_flat_namespace` workaround.

### Why Post-Link Symbol Stripping Fails

The WIP Gerrit change (651061) attempts to strip duplicate ObjC symbols
post-link. This treats the symptom. The root problem is that Qt code exists in
N places instead of 1. Even if ObjC duplicates are stripped, C++ symbols with
static storage (vtables, RTTI, `QMetaObject` singletons) will still be
duplicated, causing subtle bugs: type identity failures, signal/slot
mismatches, and corrupted global state.

---

## 2. The Solution: QtRuntime.framework

Merge all Qt static iOS libraries into a **single dynamic framework**. PySide6
modules link against this one framework. Qt code exists in exactly one place.

### 2.1 Build Pipeline

```
Qt 6.8.3 iOS static SDK
         │
         ▼
┌─────────────────────────┐
│  1. lipo -thin arm64    │  Extract device slices from universal archives
│  2. globalize_symbols   │  Clear N_PEXT bit on hidden-visibility symbols
│  3. clang++ -dynamiclib │  Link with -force_load into single .dylib
│     -exported_symbols   │  Re-export all globalized symbols
└─────────┬───────────────┘
          │
          ▼
   QtRuntime.framework   (57 MB, ~99k exported text symbols)
```

**Script:** `scripts/build_qtruntime.sh`

The framework includes:
- 27 Qt module static libraries (QtCore through QtPrintSupport)
- 5 bundled dependencies (Freetype, Harfbuzz, libjpeg, libpng, PCRE2)
- 9 plugins (qios platform, image formats, TLS, SQLite, network reachability)

### 2.2 N_PEXT Symbol Globalization (Critical)

Qt's static libraries are compiled with `-fvisibility=hidden`. In static
linking this doesn't matter — the linker resolves all symbols internally. But
when re-exporting from a dynamic framework, hidden symbols are marked with the
Mach-O `N_PEXT` (private external) bit and excluded from the export table.

**Fix:** Patch the Mach-O nlist entries in each `.a` archive to clear the
`N_PEXT` bit before linking:

```python
# From scripts/globalize_symbols.py
N_PEXT = 0x10
N_EXT  = 0x01

# For each nlist_64 entry:
if (n_type & N_PEXT) and (n_type & N_EXT):
    data[entry + 4] = n_type & ~N_PEXT
```

This operates on the raw `.a` archives in-place. After globalization, an
explicit `-exported_symbols_list` passes all symbol names to the linker.

**Script:** `scripts/globalize_symbols.py`

### 2.3 Harfbuzz Graph Stubs

Qt's bundled Harfbuzz references `graph::gsubgpos_graph_context_t` symbols that
were never compiled into the archive (font subsetting code, unused at runtime).
Empty stubs are compiled and linked in: `scripts/hb_stubs.cpp`.

---

## 3. Cross-Compiling PySide6 Modules for iOS

### 3.1 Shiboken Code Generation

Shiboken6-generator runs on the **macOS host** using **macOS Qt headers** for
parsing. The generator doesn't need iOS headers — it's producing C++ wrapper
source code, not compiled binaries.

```bash
shiboken6 --enable-pyside-extensions \
    --include-paths="$PYSIDE6_SRC:$QT_MACOS/include:..." \
    --typesystem-paths="$PYSIDE6_SRC:$PYSIDE6_SRC/templates" \
    --framework-include-paths="$QT_MACOS/lib" \
    --lean-headers --api-version=6.8 --platform=darwin \
    "$GLOBAL_H" "$TYPESYSTEM_XML"
```

Key flags per module:
- **QtNetwork:** `--drop-type-entries=QDtls;QDtlsClientVerifier;...` (DTLS not available on iOS)
- **QtQuick:** `--keywords=no_QtOpenGL` (Qt 6 uses Metal via RHI on iOS)

**Script:** `scripts/build_pyside6_module.sh`

### 3.2 iOS Cross-Compilation

Generated wrappers are cross-compiled for arm64:

```bash
xcrun -sdk iphoneos clang++ \
    -arch arm64 -std=c++17 \
    -isysroot "$IOS_SDK" \
    -miphoneos-version-min=16.0 \
    -iframework "$QT_IOS/lib" \
    -I "$QT_IOS/include" \
    -I "$QT_IOS/lib/QtCore.framework/Headers" \
    -DQT_LEAN_HEADERS=1 -DQT_NO_DEBUG -O2 -fPIC \
    -c wrapper.cpp -o wrapper.o
```

Object files are archived into static libraries via `libtool -static`:
- `libPySide6_QtCore.a` (20 MB, ~188 wrapper files)
- `libPySide6_QtGui.a` (12 MB)
- `libPySide6_QtNetwork.a` (2.9 MB)
- `libPySide6_QtQml.a` (1.4 MB)
- `libPySide6_QtQuick.a` (2.4 MB)
- `libshiboken6.a` (2.6 MB, 25 source files)
- `libpyside6.a` (1.6 MB, 18 source files)
- `libpysideqml.a` (168 KB)

### 3.3 Static Linking Into Host Executable

On iOS, PySide6 modules are **not** loaded dynamically via `dlopen`. They are
statically linked into the host executable and registered as Python built-in
modules:

```objc
// main.mm — register before Py_Initialize
PyImport_AppendInittab("PySide6.QtCore", PyInit_QtCore);
PyImport_AppendInittab("PySide6.QtGui", PyInit_QtGui);
PyImport_AppendInittab("PySide6.QtNetwork", PyInit_QtNetwork);
PyImport_AppendInittab("PySide6.QtQml", PyInit_QtQml);
PyImport_AppendInittab("PySide6.QtQuick", PyInit_QtQuick);
PyImport_AppendInittab("shiboken6.Shiboken", PyInit_Shiboken);
```

The host executable links:
- `QtRuntime.framework` (dynamic, in app's Frameworks/)
- `Python.framework` (dynamic, in app's Frameworks/)
- All `libPySide6_*.a` files (static, absorbed into executable)
- `libshiboken6.a`, `libpyside6.a`, `libpysideqml.a` (static)

This avoids the duplicate symbol problem entirely: Qt code exists only in
QtRuntime.framework, and PySide6 code exists only in the host executable.

---

## 4. Technical Pitfalls and Required Fixes

These are issues that any iOS port of PySide6 will encounter. They should be
addressed in the upstream codebase.

### 4.1 Module Name Must Be "PySide6.QtCore" (Not "QtCore")

**Symptom:** Null pointer crashes during type resolution.

When registering via `PyImport_AppendInittab`, the module name must be the
fully-qualified `"PySide6.QtCore"`, and `PyModuleDef.m_name` must match.

PySide6's type system uses `TypeInitStruct.fullName` with format
`"PySide6.QtCore.QUrl"`. During lazy type incarnation, `Module::get()` does a
`sys.modules` lookup for `"PySide6.QtCore"`. If the module was registered as
bare `"QtCore"`, the lookup fails silently and base type resolution produces
null pointers.

**Fix location:** `PyModuleDef` in each module's `_module_wrapper.cpp` and the
`Module::create()` call.

### 4.2 shouldLazyLoad() Does Not Recognize Built-In Module Names

**Symptom:** All ~200 types instantiated eagerly during `PyInit_QtCore`,
causing cascading errors when any type's dependencies aren't yet available.

`shouldLazyLoad()` in `sbkmodule.cpp` checks `strncmp(modName, "PySide6.", 8)`
to decide whether to defer type instantiation. Built-in modules registered via
`PyImport_AppendInittab` have names like `"PySide6.QtCore"`, but
`PyModule_GetName()` may return the `m_name` from `PyModuleDef`, which could be
just `"QtCore"` depending on how it was registered.

**Fix:** Add a fallback check: `strncmp(modName, "Qt", 2) == 0` to
`shouldLazyLoad()`. This ensures lazy loading is enabled for built-in PySide6
modules regardless of how they were registered.

### 4.3 arm64 adrp/lo12 Fixup Errors From Extern Template Declarations

**Symptom:** Linker error: `arm64 branch26 target '...' does not have address`
or `ld: arm64_adrp_lo12 fixup target does not have address`.

Qt's `qmetatype.h` declares `extern template struct
QMetaTypeInterfaceWrapper<T>` for common types (QString, QVariant, etc.). In
Qt's own static build, these are resolved internally. When PySide6 wrappers
reference these symbols from a separate static library, the linker can't
resolve the extern templates because they were never explicitly instantiated in
PySide6's compilation units.

**Fix:** Provide explicit template instantiations in a separate file compiled
into `libPySide6_QtCore.a`:

```cpp
// metatype_instantiations.cpp
#include <QtCore/qmetatype.h>
#include <QtCore/qvariant.h>
// ... includes for all types ...

namespace QtPrivate {
template struct QMetaTypeInterfaceWrapper<QString>;
template struct QMetaTypeInterfaceWrapper<QVariant>;
template struct QMetaTypeInterfaceWrapper<int>;
template struct QMetaTypeInterfaceWrapper<QObject *>;
// ... ~28 types total including std::nullptr_t ...
}
```

This file should be generated automatically based on the extern template
declarations in `qmetatype.h`.

### 4.4 QT_NO_DATA_RELOCATION Must NOT Be Defined on iOS

**Symptom:** Crashes in `QMetaObject::className()` / `strcmp` — corrupted
string pointers.

`QT_NO_DATA_RELOCATION` is a **Windows-only** define that changes
`QMetaObject::SuperData` from a raw pointer (8 bytes) to a function pointer
wrapper (16 bytes). Qt's iOS SDK compiles without it. If PySide6 wrappers
define it, struct field offsets are wrong: every `QMetaObject` field read after
`SuperData` is shifted by 8 bytes, reading garbage.

**Fix:** Never define `QT_NO_DATA_RELOCATION` when targeting iOS. This should
be enforced in the PySide6 build system.

### 4.5 DTLS Classes Must Be Excluded on iOS

Qt's DTLS (Datagram TLS) APIs are not available on iOS. Shiboken must exclude
them during generation:

```
--drop-type-entries=QDtls;QDtlsClientVerifier;QDtlsClientVerifier::GeneratorParameters;QDtlsError
```

Additionally, generated `qsslconfiguration_wrapper.cpp` may contain DTLS method
wrappers (`defaultDtlsConfiguration`, `setDefaultDtlsConfiguration`, etc.) that
must be patched out post-generation.

### 4.6 AVOID_PROTECTED_HACK for QThread

`qthread_wrapper.cpp` accesses `QThread::exec()` which is protected. Must
compile with `-DAVOID_PROTECTED_HACK` so the generated `QThreadWrapper` class
uses its `exec_protected()` accessor.

### 4.7 SHIBOKEN_NO_EMBEDDING_PYC for Cross-Compilation

Shiboken's signature system embeds compiled `.pyc` bytecode for the host
platform. When cross-compiling, define `SHIBOKEN_NO_EMBEDDING_PYC` to skip
embedding and use source-based loading instead.

### 4.8 Shiboken Bootstrap Pre-Imports

Shiboken's signature bootstrap runs inside `PyInit_Shiboken` and attempts to
import `zipfile`, `struct`, `io`, etc. On iOS, these may not be loadable during
module init (especially if they depend on C extensions in `lib-dynload/`).

**Fix:** The `shiboken6/__init__.py` package stub must pre-import all
dependencies before `shiboken6.Shiboken` is imported:

```python
import zipfile, base64, io, contextlib, textwrap
import traceback, types, struct, re, functools, typing
from shiboken6.Shiboken import *
```

---

## 5. Host App Integration Pattern

### 5.1 qt-inside-ios-native

The host app owns `main()` and calls `UIApplicationMain`. Qt is initialized
after UIKit, detecting the already-running `UIApplication` and using
`QIOSEventDispatcher` (the non-jumping variant) that integrates with
`CFRunLoop`.

This avoids:
- `qt_main_wrapper` / `setjmp` / `longjmp` (incompatible with Python's GC)
- The `_main` symbol resolution problem in dynamic libraries
- Any entry point override (`-Wl,-e,_qt_main_wrapper`)

### 5.2 UIView Reparenting

Qt's `QQmlApplicationEngine` creates a native `QUIMetalView` for the QML
window, but it's not automatically attached to the iOS `UIWindow` hierarchy.

```objc
dispatch_async(dispatch_get_main_queue(), ^{
    QWindow *qtWindow = QGuiApplication::topLevelWindows().first();
    UIView *qtView = (__bridge UIView *)(void *)qtWindow->winId();
    qtView.frame = self.window.bounds;
    qtView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                              UIViewAutoresizingFlexibleHeight;
    [self.window.rootViewController.view addSubview:qtView];
});
```

The `dispatch_async` is necessary because the QML engine creates the window
synchronously during `engine.load()`, but the native `UIView` may not be fully
configured until the next run loop iteration.

### 5.3 Q_IMPORT_PLUGIN

Since `libqios.a` is inside `QtRuntime.framework` (loaded at app launch), the
plugin's static initializer runs automatically. However, `Q_IMPORT_PLUGIN
(QIOSIntegrationPlugin)` should still be declared in the host app to ensure the
linker doesn't dead-strip the plugin registration.

---

## 6. App Bundle Layout

```
TestPySide6.app/
├── TestPySide6                    (host executable, ~42 MB)
│                                   - statically links all libPySide6_*.a
│                                   - dynamically links QtRuntime + Python
├── Frameworks/
│   ├── QtRuntime.framework/       (57 MB — all of Qt in one dynamic library)
│   └── Python.framework/          (CPython 3.13, ~5 MB)
├── lib/python3.13/                (Python stdlib, pure Python)
├── packages/
│   ├── shiboken6/__init__.py      (version info + pre-imports)
│   └── PySide6/__init__.py        (version info)
├── scripts/
│   └── app.py                     (user's Python application)
└── main.qml                       (QML UI)
```

---

## 7. What pyside6-deploy Needs to Change

To integrate this solution into `pyside6-deploy --target ios`:

### 7.1 Build System Changes

1. **Add a QtRuntime.framework build step.** Input: Qt 6.x iOS static SDK.
   Output: single dynamic framework. The `build_qtruntime.sh` script is the
   reference implementation.

2. **Add `globalize_symbols.py` to the build toolchain.** This is required
   whenever Qt's static libs use hidden visibility (which is the default).

3. **Cross-compile PySide6 modules as static libraries** instead of dynamic
   `.abi3.so` files. The `build_pyside6_module.sh` script handles shiboken
   generation + cross-compilation for each module.

4. **Generate `metatype_instantiations.cpp` automatically** from the extern
   template declarations in `qmetatype.h`. This could be a shiboken
   post-processing step.

5. **Generate the host app's `PyImport_AppendInittab` calls** based on which
   PySide6 modules the user's app imports.

### 7.2 Shiboken/libshiboken Changes

1. **`shouldLazyLoad()`** in `sbkmodule.cpp`: add `strncmp(modName, "Qt", 2)`
   fallback for built-in module names.

2. **Module name handling**: ensure `PyModuleDef.m_name` supports dotted names
   like `"PySide6.QtCore"` for `PyImport_AppendInittab` registration.

3. **`SHIBOKEN_NO_EMBEDDING_PYC`**: make this the default for iOS builds, or
   auto-detect cross-compilation.

### 7.3 PySide6 Module Changes

1. **QtNetwork**: exclude DTLS types on iOS (both in shiboken generation and in
   post-generation wrapper patching).

2. **QtQuick**: use `--keywords=no_QtOpenGL` on iOS (Metal via RHI, no GL).

3. **QT_NO_DATA_RELOCATION**: add a build-system guard to prevent this from
   being defined on iOS.

4. **AVOID_PROTECTED_HACK**: apply to `qthread_wrapper.cpp` specifically (not
   globally).

---

## 8. Reproducing the Result

All scripts and test apps are in the repository:

```
scripts/
├── build_qtruntime.sh         # Phase 1: Qt static → dynamic framework
├── build_pyside6_module.sh    # Phase 2: shiboken + cross-compile per module
├── globalize_symbols.py       # N_PEXT bit clearing
└── hb_stubs.cpp               # Harfbuzz graph stubs

test/test_pyside6/
├── main.mm                    # iOS host app (ObjC++ with Qt + Python init)
├── main.qml                   # QML UI with touch interaction
├── scripts/app.py             # Python app using PySide6.QtQml
└── packages/                  # shiboken6 + PySide6 package stubs
```

Prerequisites:
- Qt 6.8.3 iOS SDK (via `aqt install-qt mac ios 6.8.3`)
- Qt 6.8.3 macOS SDK (for shiboken header parsing)
- Python 3.13 iOS framework (BeeWare Python-Apple-support)
- PySide6 6.8.3 source (`pyside-setup`)
- shiboken6-generator (pip install from PyPI, runs on macOS host)
- Xcode 16+ with iOS 16.0+ SDK

Build order:
1. `scripts/build_qtruntime.sh` → `build/QtRuntime.framework`
2. `scripts/build_pyside6_module.sh QtCore` (then QtGui, QtNetwork, QtQml, QtQuick)
3. Open `test/test_pyside6/TestPySide6.xcodeproj`, build and run on device

---

## 9. References

- **PYSIDE-2352**: PySide6 iOS support tracking issue
- **Gerrit 651061**: WIP PySide6 iOS patch (16 patch sets as of 2026-01-26)
- **QTBUG-85974**: Build Qt as dynamic frameworks on iOS
- **PEP 730**: CPython iOS support (merged in 3.13)
- **qt-inside-ios-native**: github.com/kambala-decapitator/qt-inside-ios-native
- **BeeWare Python-Apple-support**: github.com/beeware/Python-Apple-support
