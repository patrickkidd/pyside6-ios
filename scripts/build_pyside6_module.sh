#!/bin/bash
set -euo pipefail

MODULE="${1:?Usage: $0 <ModuleName>}"
MODULE_LOWER=$(echo "$MODULE" | tr '[:upper:]' '[:lower:]')

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QT_IOS="$HOME/dev/lib/Qt-6/6.8.3/ios"
QT_MACOS="$HOME/dev/lib/Qt-6/6.8.3/macos"
PYSIDE_SRC="$ROOT/build/pyside-setup/sources/pyside6"
PYSIDE6_SRC="$PYSIDE_SRC/PySide6"
LIBSHIBOKEN_SRC="$ROOT/build/pyside-setup/sources/shiboken6/libshiboken"
LIBPYSIDE_SRC="$PYSIDE_SRC/libpyside"
LIBPYSIDEQML_SRC="$PYSIDE_SRC/libpysideqml"
SHIBOKEN6="$ROOT/.venv/lib/python3.14/site-packages/shiboken6_generator/shiboken6"
PYTHON_FW="$ROOT/build/python/Python.xcframework/ios-arm64/Python.framework"

GEN_DIR="$ROOT/build/pyside6-ios-gen/PySide6/$MODULE"
OBJ_DIR="$ROOT/build/${MODULE_LOWER}-ios"
OUT_DIR="$ROOT/build/pyside6-ios-static"

IOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CXX="xcrun -sdk iphoneos clang++"

CXXFLAGS=(-arch arm64 -std=c++17 -isysroot "$IOS_SDK" -miphoneos-version-min=16.0 \
    -iframework "$QT_IOS/lib" -I "$QT_IOS/include" \
    -I "$QT_IOS/lib/QtCore.framework/Headers" \
    -I "$QT_IOS/lib/QtCore.framework/Headers/6.8.3" \
    -I "$QT_IOS/lib/QtCore.framework/Headers/6.8.3/QtCore" \
    -I "$PYTHON_FW/Headers" -I "$LIBSHIBOKEN_SRC" -I "$LIBPYSIDE_SRC" \
    -I "$PYSIDE6_SRC" -I "$GEN_DIR" -I "$ROOT/build/pyside6-ios-gen/PySide6/QtCore" \
    -DQT_LEAN_HEADERS=1 -DQT_NO_DEBUG -O2 -fPIC)

TYPESYSTEM_XML=""
EXTRA_SHIBOKEN_FLAGS=()
EXTRA_CXXFLAGS=()
EXTRA_INCLUDE_DIRS=()
EXTRA_SOURCES=()

case "$MODULE" in
    QtNetwork)
        TYPESYSTEM_XML="$PYSIDE6_SRC/QtNetwork/typesystem_network.xml"
        EXTRA_SHIBOKEN_FLAGS+=("--drop-type-entries=QDtls;QDtlsClientVerifier;QDtlsClientVerifier::GeneratorParameters;QDtlsError")
        EXTRA_CXXFLAGS+=(-I "$QT_IOS/lib/QtNetwork.framework/Headers" \
            -I "$QT_IOS/lib/QtNetwork.framework/Headers/6.8.3" \
            -I "$QT_IOS/lib/QtNetwork.framework/Headers/6.8.3/QtNetwork")
        ;;
    QtGui)
        TYPESYSTEM_XML="$PYSIDE6_SRC/QtGui/typesystem_gui.xml"
        EXTRA_INCLUDE_DIRS+=("$GEN_DIR")
        EXTRA_CXXFLAGS+=(-I "$QT_IOS/lib/QtGui.framework/Headers" \
            -I "$QT_IOS/lib/QtGui.framework/Headers/6.8.3" \
            -I "$QT_IOS/lib/QtGui.framework/Headers/6.8.3/QtGui")
        ;;
    QtQml)
        TYPESYSTEM_XML="$PYSIDE6_SRC/QtQml/typesystem_qml.xml"
        EXTRA_INCLUDE_DIRS+=("$ROOT/build/pyside6-ios-gen/PySide6/QtNetwork" "$GEN_DIR" "$LIBPYSIDEQML_SRC")
        EXTRA_CXXFLAGS+=(-I "$LIBPYSIDEQML_SRC" -I "$PYSIDE6_SRC/QtQml" \
            -I "$QT_IOS/lib/QtNetwork.framework/Headers" \
            -I "$QT_IOS/lib/QtQml.framework/Headers" \
            -I "$QT_IOS/lib/QtQml.framework/Headers/6.8.3" \
            -I "$QT_IOS/lib/QtQml.framework/Headers/6.8.3/QtQml" \
            -I "$ROOT/build/pyside6-ios-gen/PySide6/QtNetwork")
        EXTRA_SOURCES+=("$PYSIDE6_SRC/QtQml/pysideqmlvolatilebool.cpp")
        ;;
    QtQuick)
        TYPESYSTEM_XML="$PYSIDE6_SRC/QtQuick/typesystem_quick.xml"
        EXTRA_SHIBOKEN_FLAGS+=("--keywords=no_QtOpenGL")
        EXTRA_INCLUDE_DIRS+=("$ROOT/build/pyside6-ios-gen/PySide6/QtNetwork" \
            "$ROOT/build/pyside6-ios-gen/PySide6/QtGui" \
            "$ROOT/build/pyside6-ios-gen/PySide6/QtQml" "$GEN_DIR" "$LIBPYSIDEQML_SRC")
        EXTRA_CXXFLAGS+=(-I "$LIBPYSIDEQML_SRC" \
            -I "$ROOT/build/pyside6-ios-gen/PySide6/QtNetwork" \
            -I "$ROOT/build/pyside6-ios-gen/PySide6/QtGui" \
            -I "$ROOT/build/pyside6-ios-gen/PySide6/QtQml" \
            -I "$QT_IOS/lib/QtGui.framework/Headers" \
            -I "$QT_IOS/lib/QtNetwork.framework/Headers" \
            -I "$QT_IOS/lib/QtQml.framework/Headers" \
            -I "$QT_IOS/lib/QtQml.framework/Headers/6.8.3" \
            -I "$QT_IOS/lib/QtQml.framework/Headers/6.8.3/QtQml" \
            -I "$QT_IOS/lib/QtQuick.framework/Headers" \
            -I "$QT_IOS/lib/QtQuick.framework/Headers/6.8.3" \
            -I "$QT_IOS/lib/QtQuick.framework/Headers/6.8.3/QtQuick" \
            -I "$PYSIDE6_SRC/QtQuick")
        EXTRA_SOURCES+=("$PYSIDE6_SRC/QtQuick/pysidequickregistertype.cpp")
        ;;
    QtWidgets)
        TYPESYSTEM_XML="$PYSIDE6_SRC/QtWidgets/typesystem_widgets.xml"
        EXTRA_INCLUDE_DIRS+=("$ROOT/build/pyside6-ios-gen/PySide6/QtNetwork" \
            "$ROOT/build/pyside6-ios-gen/PySide6/QtGui" "$GEN_DIR")
        EXTRA_CXXFLAGS+=(\
            -I "$ROOT/build/pyside6-ios-gen/PySide6/QtGui" \
            -I "$ROOT/build/pyside6-ios-gen/PySide6/QtNetwork" \
            -I "$QT_IOS/lib/QtGui.framework/Headers" \
            -I "$QT_IOS/lib/QtGui.framework/Headers/6.8.3" \
            -I "$QT_IOS/lib/QtGui.framework/Headers/6.8.3/QtGui" \
            -I "$QT_IOS/lib/QtNetwork.framework/Headers" \
            -I "$QT_IOS/lib/QtWidgets.framework/Headers" \
            -I "$QT_IOS/lib/QtWidgets.framework/Headers/6.8.3" \
            -I "$QT_IOS/lib/QtWidgets.framework/Headers/6.8.3/QtWidgets")
        ;;
    *) echo "Unknown module: $MODULE"; exit 1 ;;
esac

# Phase 1: Global header
echo "==> Phase 1: Generating ${MODULE}_global.h"
GLOBAL_H="$ROOT/build/pyside6-ios-gen/${MODULE}_global.h"
mkdir -p "$(dirname "$GLOBAL_H")"
cat > "$GLOBAL_H" << 'GHEOF'
#include <QtCore/qnamespace.h>
#define Q_OS_MAC
#define Q_OS_UNIX
#define QT_NO_DEBUG
GHEOF
echo "#include <${MODULE}/${MODULE}>" >> "$GLOBAL_H"
POST_HEADER="$PYSIDE6_SRC/$MODULE/${MODULE}_global.post.h.in"
[ -f "$POST_HEADER" ] && cat "$POST_HEADER" >> "$GLOBAL_H"

# Phase 2: shiboken6
echo "==> Phase 2: Running shiboken6 for $MODULE"
mkdir -p "$GEN_DIR"
SHIBOKEN_INCLUDES="$PYSIDE6_SRC:$QT_MACOS/include"
for dep in QtCore QtGui QtWidgets QtNetwork QtQml QtQuick QtOpenGL; do
    FW="$QT_MACOS/lib/$dep.framework/Headers"
    [ -d "$FW" ] && SHIBOKEN_INCLUDES="$SHIBOKEN_INCLUDES:$FW"
    [ -d "$FW/6.8.3" ] && SHIBOKEN_INCLUDES="$SHIBOKEN_INCLUDES:$FW/6.8.3"
    [ -d "$FW/6.8.3/$dep" ] && SHIBOKEN_INCLUDES="$SHIBOKEN_INCLUDES:$FW/6.8.3/$dep"
done
for d in "${EXTRA_INCLUDE_DIRS[@]+"${EXTRA_INCLUDE_DIRS[@]}"}"; do
    SHIBOKEN_INCLUDES="$SHIBOKEN_INCLUDES:$d"
done
SHIBOKEN_INCLUDES="$SHIBOKEN_INCLUDES:$LIBPYSIDE_SRC:$LIBSHIBOKEN_SRC:$LIBPYSIDEQML_SRC"

"$SHIBOKEN6" --enable-pyside-extensions \
    "--include-paths=$SHIBOKEN_INCLUDES" \
    "--typesystem-paths=$PYSIDE6_SRC:$PYSIDE6_SRC/templates" \
    "--output-directory=$ROOT/build/pyside6-ios-gen" \
    "--license-file=$PYSIDE6_SRC/licensecomment.txt" \
    --lean-headers "--api-version=6.8" "--platform=darwin" \
    "--framework-include-paths=$QT_MACOS/lib" \
    "${EXTRA_SHIBOKEN_FLAGS[@]+"${EXTRA_SHIBOKEN_FLAGS[@]}"}" \
    "$GLOBAL_H" "$TYPESYSTEM_XML" 2>&1

WRAPPER_COUNT=$(ls "$GEN_DIR"/*_wrapper.cpp 2>/dev/null | wc -l | tr -d ' ')
echo "    Generated $WRAPPER_COUNT wrapper files"
[ "$WRAPPER_COUNT" -eq 0 ] && { echo "ERROR: No wrappers!"; exit 1; }

# Phase 2b: iOS patches
if [ "$MODULE" = "QtNetwork" ]; then
    SSLCONF="$GEN_DIR/qsslconfiguration_wrapper.cpp"
    if [ -f "$SSLCONF" ] && grep -q "defaultDtlsConfiguration" "$SSLCONF"; then
        echo "    Patching DTLS methods..."
        python3 -c "
import re
with open('$SSLCONF') as f: code = f.read()
for func in ['defaultDtlsConfiguration','dtlsCookieVerificationEnabled','setDefaultDtlsConfiguration','setDtlsCookieVerificationEnabled']:
    code = re.sub(rf'static PyObject \*Sbk_QSslConfigurationFunc_{func}\(.*?\n\}}\n', '', code, flags=re.DOTALL)
    code = re.sub(rf'.*Sbk_QSslConfigurationFunc_{func}.*\n', '', code)
with open('$SSLCONF','w') as f: f.write(code)
"
    fi
fi

if [ "$MODULE" = "QtWidgets" ]; then
    QMENU="$GEN_DIR/qmenu_wrapper.cpp"
    if [ -f "$QMENU" ] && grep -q "setAsDockMenu" "$QMENU"; then
        echo "    Patching macOS-only setAsDockMenu..."
        python3 -c "
import re
with open('$QMENU') as f: code = f.read()
# Remove the setAsDockMenu method body and method table entry
code = re.sub(r'static PyObject \*Sbk_QMenuFunc_setAsDockMenu\(.*?\n\}\n', '', code, flags=re.DOTALL)
code = re.sub(r'.*Sbk_QMenuFunc_setAsDockMenu.*\n', '', code)
with open('$QMENU','w') as f: f.write(code)
"
    fi
fi

# Phase 3: Cross-compile
echo "==> Phase 3: Cross-compiling $MODULE for iOS arm64"
mkdir -p "$OBJ_DIR"
CXXFLAGS+=("${EXTRA_CXXFLAGS[@]+"${EXTRA_CXXFLAGS[@]}"}")
FAILED=0; COMPILED=0

for src in "$GEN_DIR"/*_wrapper.cpp; do
    base=$(basename "$src" .cpp)
    obj="$OBJ_DIR/$base.o"
    FILE_FLAGS=()
    [[ "$base" == "qthread_wrapper" ]] && FILE_FLAGS+=("-DAVOID_PROTECTED_HACK")
    if $CXX "${CXXFLAGS[@]}" "${FILE_FLAGS[@]+"${FILE_FLAGS[@]}"}" -c "$src" -o "$obj" 2>/dev/null; then
        COMPILED=$((COMPILED + 1))
    else
        echo "    WARN: $base failed, retrying verbose..."
        if $CXX "${CXXFLAGS[@]}" "${FILE_FLAGS[@]+"${FILE_FLAGS[@]}"}" -c "$src" -o "$obj" 2>&1 | tail -5; then
            COMPILED=$((COMPILED + 1))
        else
            echo "    FAILED: $base"; FAILED=$((FAILED + 1))
        fi
    fi
done

MODULE_WRAPPER="$GEN_DIR/${MODULE_LOWER}_module_wrapper.cpp"
if [ -f "$MODULE_WRAPPER" ]; then
    echo "    Compiling module wrapper..."
    if $CXX "${CXXFLAGS[@]}" -c "$MODULE_WRAPPER" -o "$OBJ_DIR/${MODULE_LOWER}_module_wrapper.o" 2>/dev/null; then
        COMPILED=$((COMPILED + 1))
    else
        $CXX "${CXXFLAGS[@]}" -c "$MODULE_WRAPPER" -o "$OBJ_DIR/${MODULE_LOWER}_module_wrapper.o" 2>&1 | tail -10
        FAILED=$((FAILED + 1))
    fi
fi

for src in "${EXTRA_SOURCES[@]+"${EXTRA_SOURCES[@]}"}"; do
    base=$(basename "$src" .cpp)
    echo "    Compiling extra: $base"
    if $CXX "${CXXFLAGS[@]}" -c "$src" -o "$OBJ_DIR/$base.o" 2>/dev/null; then
        COMPILED=$((COMPILED + 1))
    else
        $CXX "${CXXFLAGS[@]}" -c "$src" -o "$OBJ_DIR/$base.o" 2>&1 | tail -10
        FAILED=$((FAILED + 1))
    fi
done
echo "    Compiled: $COMPILED, Failed: $FAILED"

# Phase 4: Static library
echo "==> Phase 4: Creating libPySide6_${MODULE}.a"
mkdir -p "$OUT_DIR"
xcrun -sdk iphoneos libtool -static -o "$OUT_DIR/libPySide6_${MODULE}.a" "$OBJ_DIR"/*.o 2>&1
echo "==> Done: $OUT_DIR/libPySide6_${MODULE}.a ($(du -h "$OUT_DIR/libPySide6_${MODULE}.a" | cut -f1))"
