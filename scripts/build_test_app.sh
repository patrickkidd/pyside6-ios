#!/usr/bin/env bash
#
# build_test_app.sh — Build and optionally run the QtRuntime test app on iOS Simulator.
#
# Usage: ./scripts/build_test_app.sh [--run] [--arch x86_64|arm64] [--qt-ios PATH]
#
# Requires: QtRuntime.framework already built in build/QtRuntime.framework

set -euo pipefail

RUN=false
ARCH="x86_64"
QT_IOS="$HOME/dev/lib/Qt-6/6.8.3/ios"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --run)    RUN=true; shift ;;
        --arch)   ARCH="$2"; shift 2 ;;
        --qt-ios) QT_IOS="$2"; shift 2 ;;
        *)        echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

SDK_NAME="iphonesimulator"
MIN_VERSION_FLAG="-mios-simulator-version-min=16.0"
SDK=$(xcrun --sdk "$SDK_NAME" --show-sdk-path)
CC=$(xcrun --sdk "$SDK_NAME" --find clang++)

FRAMEWORK_DIR="build/QtRuntime.framework"
if [[ ! -f "$FRAMEWORK_DIR/QtRuntime" ]]; then
    echo "ERROR: build/QtRuntime.framework not found. Run build_qtruntime.sh first." >&2
    exit 1
fi

BUILD_DIR="build/test_app"
APP_BUNDLE="$BUILD_DIR/TestQtRuntime.app"

rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Frameworks"

echo "==> Compiling test app ($ARCH, $SDK_NAME)"

# Qt iOS SDK ships headers inside .framework bundles
QT_FRAMEWORK_PATH="$QT_IOS/lib"

"$CC" -arch "$ARCH" \
    -isysroot "$SDK" \
    $MIN_VERSION_FLAG \
    -std=c++17 \
    -fobjc-arc \
    -F "$QT_FRAMEWORK_PATH" \
    -F build \
    -framework QtRuntime \
    -framework UIKit -framework Foundation \
    -Wl,-rpath,@executable_path/Frameworks \
    -o "$APP_BUNDLE/TestQtRuntime" \
    test/test_qtruntime/main.mm

cp -R "$FRAMEWORK_DIR" "$APP_BUNDLE/Frameworks/"
cp test/test_qtruntime/Info.plist "$APP_BUNDLE/"

echo "==> Built: $APP_BUNDLE"
file "$APP_BUNDLE/TestQtRuntime"

if $RUN; then
    echo "==> Booting iOS Simulator"
    DEVICE=$(xcrun simctl list devices available -j | \
        python3 -c "
import json,sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    if 'iOS' in runtime:
        for d in devices:
            if 'iPhone' in d['name'] and d['isAvailable']:
                print(d['udid']); sys.exit()
")
    if [[ -z "$DEVICE" ]]; then
        echo "ERROR: No available iPhone simulator found" >&2
        exit 1
    fi
    xcrun simctl boot "$DEVICE" 2>/dev/null || true
    echo "==> Installing app on simulator $DEVICE"
    xcrun simctl install "$DEVICE" "$APP_BUNDLE"
    echo "==> Launching app"
    xcrun simctl launch --console "$DEVICE" com.alaskafamilysystems.test-qtruntime
fi
