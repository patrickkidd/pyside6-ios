#!/bin/bash
# Shared environment for pyside6-ios build scripts.
# Source this from other scripts: source "$(dirname "$0")/env.sh"
#
# Override any variable via environment:
#   QT_IOS=~/Qt/6.10.2/ios ./scripts/build_support_libs.sh
#
# Auto-detects:
#   QT_VERSION   from QtCore.framework/Headers/<version>/
#   PYSIDE_VERSION  from build/pyside-setup/sources/shiboken6/.cmake.conf

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P6IOS_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"

# -- Qt SDK paths (override via env) --
: "${QT_IOS:=$HOME/dev/lib/Qt-6/6.8.3/ios}"
: "${QT_MACOS:=${QT_IOS%/ios}/macos}"

[ -d "$QT_IOS/lib/QtCore.framework" ] || { echo "ERROR: QT_IOS not found: $QT_IOS" >&2; exit 1; }

# -- Auto-detect Qt version from framework headers --
_qt_ver_dir=$(ls -d "$QT_IOS/lib/QtCore.framework/Headers"/[0-9]* 2>/dev/null | head -1)
[ -n "$_qt_ver_dir" ] || { echo "ERROR: Cannot detect Qt version from $QT_IOS/lib/QtCore.framework/Headers/" >&2; exit 1; }
QT_VERSION=$(basename "$_qt_ver_dir")

# -- PySide/shiboken source version from .cmake.conf --
_cmake_conf="$P6IOS_ROOT/build/pyside-setup/sources/shiboken6/.cmake.conf"
if [ -f "$_cmake_conf" ]; then
    SHIBOKEN_MAJOR=$(sed -n 's/.*shiboken_MAJOR_VERSION.*"\([0-9]*\)".*/\1/p' "$_cmake_conf")
    SHIBOKEN_MINOR=$(sed -n 's/.*shiboken_MINOR_VERSION.*"\([0-9]*\)".*/\1/p' "$_cmake_conf")
    SHIBOKEN_MICRO=$(sed -n 's/.*shiboken_MICRO_VERSION.*"\([0-9]*\)".*/\1/p' "$_cmake_conf")
    PYSIDE_VERSION="${SHIBOKEN_MAJOR}.${SHIBOKEN_MINOR}.${SHIBOKEN_MICRO}"
fi

# -- Python iOS framework --
PYTHON_FW="$P6IOS_ROOT/build/python/Python.xcframework/ios-arm64/Python.framework"

# -- Common source paths --
PYSIDE_SRC="$P6IOS_ROOT/build/pyside-setup/sources/pyside6"
PYSIDE6_SRC="$PYSIDE_SRC/PySide6"
LIBSHIBOKEN_SRC="$P6IOS_ROOT/build/pyside-setup/sources/shiboken6/libshiboken"
LIBPYSIDE_SRC="$PYSIDE_SRC/libpyside"
LIBPYSIDEQML_SRC="$PYSIDE_SRC/libpysideqml"

# -- iOS toolchain --
IOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CXX="xcrun -sdk iphoneos clang++"

# Helper: return framework header include flags for a given Qt module.
# Usage: qt_header_flags QtCore
qt_header_flags() {
    local mod="$1"
    local base="$QT_IOS/lib/${mod}.framework/Headers"
    echo "-I $base -I $base/$QT_VERSION -I $base/$QT_VERSION/$mod"
}
