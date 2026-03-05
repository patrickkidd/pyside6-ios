#!/usr/bin/env bash
#
# build_qtruntime.sh — Merge Qt 6 iOS static libraries into a single dynamic framework.
#
# Usage: ./scripts/build_qtruntime.sh [--simulator] [--arch arm64|x86_64] [--qt-ios PATH]
#
# Defaults:
#   --arch       arm64
#   --simulator  (omit for device build)
#   --qt-ios     ~/dev/lib/Qt-6/6.8.3/ios

set -euo pipefail

ARCH="arm64"
SIMULATOR=false
QT_IOS="$HOME/dev/lib/Qt-6/6.8.3/ios"
BUILD_DIR="build/qtruntime"
OUTPUT="build/QtRuntime.framework"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --arch)      ARCH="$2"; shift 2 ;;
        --simulator) SIMULATOR=true; shift ;;
        --qt-ios)    QT_IOS="$2"; shift 2 ;;
        *)           echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

if $SIMULATOR; then
    SDK_NAME="iphonesimulator"
    MIN_VERSION_FLAG="-mios-simulator-version-min=16.0"
else
    SDK_NAME="iphoneos"
    MIN_VERSION_FLAG="-miphoneos-version-min=16.0"
fi

SDK=$(xcrun --sdk "$SDK_NAME" --show-sdk-path)
CC=$(xcrun --sdk "$SDK_NAME" --find clang++)

echo "==> Building QtRuntime.framework"
echo "    Arch:   $ARCH"
echo "    SDK:    $SDK_NAME"
echo "    Qt iOS: $QT_IOS"

# --- Extract single-arch slices from universal static frameworks ---

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/thin" "$OUTPUT"

QT_FRAMEWORKS=(
    QtCore QtGui QtWidgets QtNetwork QtConcurrent
    QtQml QtQmlModels QtQmlWorkerScript QtQmlMeta QtQmlCore
    QtQuick QtQuickControls2 QtQuickTemplates2 QtQuickLayouts
    QtQuickWidgets QtQuickParticles QtQuickShapes QtQuickEffects
    QtQuickControls2Impl QtQuickControls2Basic QtQuickControls2BasicStyleImpl
    QtOpenGL QtOpenGLWidgets QtSvg QtSvgWidgets QtSql QtXml
    QtPrintSupport
)

echo "==> Extracting $ARCH slices from static frameworks"
for fw in "${QT_FRAMEWORKS[@]}"; do
    src="$QT_IOS/lib/${fw}.framework/${fw}"
    if [[ -f "$src" ]]; then
        lipo "$src" -thin "$ARCH" -output "$BUILD_DIR/thin/lib${fw}.a" 2>/dev/null \
            || cp "$src" "$BUILD_DIR/thin/lib${fw}.a"  # already single-arch
    fi
done

# --- Collect bundled deps (already plain .a, may be universal) ---

BUNDLED_LIBS=(
    libQt6BundledFreetype libQt6BundledHarfbuzz
    libQt6BundledLibjpeg libQt6BundledLibpng libQt6BundledPcre2
)

for lib in "${BUNDLED_LIBS[@]}"; do
    src="$QT_IOS/lib/${lib}.a"
    if [[ -f "$src" ]]; then
        lipo "$src" -thin "$ARCH" -output "$BUILD_DIR/thin/${lib}.a" 2>/dev/null \
            || cp "$src" "$BUILD_DIR/thin/${lib}.a"
    fi
done

# --- Collect plugins (plain .a) ---

PLUGINS=(
    plugins/platforms/libqios.a
    plugins/imageformats/libqgif.a
    plugins/imageformats/libqico.a
    plugins/imageformats/libqjpeg.a
    plugins/imageformats/libqsvg.a
    plugins/iconengines/libqsvgicon.a
    plugins/tls/libqsecuretransportbackend.a
    plugins/sqldrivers/libqsqlite.a
    plugins/networkinformation/libqscnetworkreachability.a
)

for plugin in "${PLUGINS[@]}"; do
    src="$QT_IOS/$plugin"
    name=$(basename "$plugin")
    if [[ -f "$src" ]]; then
        lipo "$src" -thin "$ARCH" -output "$BUILD_DIR/thin/${name}" 2>/dev/null \
            || cp "$src" "$BUILD_DIR/thin/${name}"
    fi
done

# --- Globalize private-external symbols ---
# Qt static libs are compiled with -fvisibility=hidden, making all C++ symbols
# private external (N_PEXT). We patch the Mach-O nlist entries to clear N_PEXT
# so symbols can be exported from the dynamic framework.

echo "==> Globalizing hidden symbols in extracted archives"
uv run python scripts/globalize_symbols.py "$BUILD_DIR/thin/"*.a

# --- Build force_load flags ---

FORCE_LOAD_FLAGS=()
for lib in "$BUILD_DIR/thin/"*.a; do
    FORCE_LOAD_FLAGS+=("-Wl,-force_load,$lib")
done

# --- Generate exported symbols list ---
# Qt static libs are compiled with -fvisibility=hidden. To re-export all symbols
# from the dynamic framework, we extract the global symbol names from the archives
# and pass them as an explicit export list to the linker.

echo "==> Generating exported symbols list"
EXPORT_LIST="$BUILD_DIR/exports.txt"
for lib in "$BUILD_DIR/thin/"*.a; do
    nm -gU "$lib" 2>/dev/null | awk '{print $3}'
done | sort -u > "$EXPORT_LIST"
EXPORT_COUNT=$(wc -l < "$EXPORT_LIST" | tr -d ' ')
echo "    $EXPORT_COUNT symbols to export"

# --- Compile Harfbuzz stubs ---
# Qt's bundled Harfbuzz references graph::gsubgpos_graph_context_t symbols that were
# never compiled into the archive. Provide empty stubs (font subsetting is unused at runtime).

echo "==> Compiling Harfbuzz stubs"
HB_STUBS="$BUILD_DIR/hb_stubs.o"
"$CC" -arch "$ARCH" -isysroot "$SDK" $MIN_VERSION_FLAG -std=c++17 \
    -c scripts/hb_stubs.cpp -o "$HB_STUBS"

echo "==> Linking QtRuntime dynamic library (${#FORCE_LOAD_FLAGS[@]} archives)"

"$CC" -dynamiclib -arch "$ARCH" \
    -isysroot "$SDK" \
    $MIN_VERSION_FLAG \
    -install_name @rpath/QtRuntime.framework/QtRuntime \
    -o "$OUTPUT/QtRuntime" \
    "${FORCE_LOAD_FLAGS[@]}" \
    "$HB_STUBS" \
    -Wl,-exported_symbols_list,"$EXPORT_LIST" \
    -Wl,-undefined,dynamic_lookup \
    -framework UIKit -framework Foundation -framework CoreFoundation \
    -framework CoreGraphics -framework CoreText -framework QuartzCore \
    -framework Metal -framework MetalKit -framework ImageIO -framework Security \
    -framework AVFoundation -framework AudioToolbox \
    -framework SystemConfiguration -framework CoreMotion \
    -framework UniformTypeIdentifiers -framework CoreServices \
    -framework IOSurface -framework MobileCoreServices \
    -framework CFNetwork -framework IOKit -framework OpenGLES \
    -framework Photos -framework PhotosUI \
    -lz -lsqlite3 -lbz2 -lc++

# --- Info.plist ---

cat > "$OUTPUT/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.alaskafamilysystems.qtruntime</string>
  <key>CFBundleExecutable</key>
  <string>QtRuntime</string>
  <key>CFBundleVersion</key>
  <string>6.8.3</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>MinimumOSVersion</key>
  <string>16.0</string>
</dict>
</plist>
PLIST

# --- Verify ---

echo ""
echo "==> Verification"
file "$OUTPUT/QtRuntime"
echo ""

SYMBOL_COUNT=$(nm -gU "$OUTPUT/QtRuntime" | grep -c " T " || true)
echo "    Exported text symbols: $SYMBOL_COUNT"

OBJC_CLASSES=$(nm -gU "$OUTPUT/QtRuntime" | grep -c "OBJC_CLASS" || true)
echo "    ObjC classes: $OBJC_CLASSES"

SIZE=$(stat -f%z "$OUTPUT/QtRuntime" 2>/dev/null || stat -c%s "$OUTPUT/QtRuntime")
echo "    Binary size: $((SIZE / 1024 / 1024)) MB"

echo ""
echo "==> QtRuntime.framework built at $OUTPUT"
