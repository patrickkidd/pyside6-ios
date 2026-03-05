#!/usr/bin/env bash
#
# build_test_qml.sh — Build and run the QML test app on iOS Simulator.
#
# Usage: ./scripts/build_test_qml.sh [--run]

set -euo pipefail

RUN=false
ARCH="x86_64"
QT_IOS="$HOME/dev/lib/Qt-6/6.8.3/ios"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --run) RUN=true; shift ;;
        *)     echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
CC=$(xcrun --sdk iphonesimulator --find clang++)

FRAMEWORK_DIR="build/QtRuntime.framework"
if [[ ! -f "$FRAMEWORK_DIR/QtRuntime" ]]; then
    echo "ERROR: build/QtRuntime.framework not found." >&2
    exit 1
fi

BUILD_DIR="build/test_qml"
APP_BUNDLE="$BUILD_DIR/TestQml.app"
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Frameworks"

echo "==> Compiling QML test app"

"$CC" -arch "$ARCH" \
    -isysroot "$SDK" \
    -mios-simulator-version-min=16.0 \
    -std=c++17 \
    -fobjc-arc \
    -iframework "$QT_IOS/lib" \
    -I "$QT_IOS/include" \
    -F build \
    -framework QtRuntime \
    -framework UIKit -framework Foundation \
    -Wl,-rpath,@executable_path/Frameworks \
    -o "$APP_BUNDLE/TestQml" \
    test/test_qml/main.mm

cp -R "$FRAMEWORK_DIR" "$APP_BUNDLE/Frameworks/"
cp test/test_qml/Info.plist "$APP_BUNDLE/"
cp test/test_qml/main.qml "$APP_BUNDLE/"

# Copy QML import plugins needed by QtQuick
QML_DIR="$QT_IOS/qml"
if [[ -d "$QML_DIR" ]]; then
    mkdir -p "$APP_BUNDLE/qml"
    # QtQuick needs its QML type registrations at minimum
    for mod in QtQuick QtQml QtCore; do
        if [[ -d "$QML_DIR/$mod" ]]; then
            cp -R "$QML_DIR/$mod" "$APP_BUNDLE/qml/"
        fi
    done
fi

echo "==> Built: $APP_BUNDLE"
file "$APP_BUNDLE/TestQml"

if $RUN; then
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
    xcrun simctl boot "$DEVICE" 2>/dev/null || true
    xcrun simctl install "$DEVICE" "$APP_BUNDLE"
    echo "==> Launching on simulator"
    xcrun simctl launch --console "$DEVICE" com.alaskafamilysystems.test-qml
fi
