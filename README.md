# pyside6-ios

Build toolchain enabling PySide6 to run on iOS.

## The Problem

Qt 6 ships only static libraries for iOS. PySide6 modules must be separate dynamic
`.framework` bundles. When each module absorbs static Qt code, symbols duplicate across
frameworks — the bug that has blocked the Qt Company for 8+ months.

## The Fix

Merge all Qt static libraries into a single `QtRuntime.framework` dynamic framework.
PySide6 modules link against it dynamically. Zero duplication by construction.

## Prerequisites

- macOS (Apple Silicon)
- Xcode with iOS SDK
- Qt 6.8.3 iOS SDK at `~/dev/lib/Qt-6/6.8.3/ios/`
- Python 3.13+ with `uv`

### Install Qt 6.8.3 iOS

```bash
uv venv .venv && source .venv/bin/activate
uv pip install aqtinstall
aqt install-qt mac ios 6.8.3 ios --outputdir ~/dev/lib/Qt-6 --autodesktop
```

## Quick Start

```bash
# Build QtRuntime.framework (arm64 for device/Apple Silicon simulator)
./scripts/build_qtruntime.sh

# Build and run test app on iOS Simulator
./scripts/build_test_app.sh --run
```

## Project Structure

```
scripts/
  build_qtruntime.sh    — Merge Qt static libs into QtRuntime.framework
  build_test_app.sh     — Build/run the M1 validation app on simulator
test/
  test_qtruntime/       — Minimal iOS app that loads QtRuntime + creates QCoreApplication
doc/
  plan.md               — Full project plan and milestone tracking
```

## Status

See [doc/plan.md](doc/plan.md) for milestones and risk assessment.
