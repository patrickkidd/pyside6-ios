#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

SHIBOKEN_MOD_SRC="$P6IOS_ROOT/build/pyside-setup/sources/shiboken6/shibokenmodule"
SHIBOKEN6="$(python3 -c "import shiboken6_generator; print(shiboken6_generator.__path__[0])")/shiboken6"

BASE_CXXFLAGS=(-arch arm64 -std=c++17 -isysroot "$IOS_SDK" -miphoneos-version-min=16.0 \
    -iframework "$QT_IOS/lib" -I "$QT_IOS/include" \
    $(qt_header_flags QtCore) \
    -I "$PYTHON_FW/Headers" -I "$LIBSHIBOKEN_SRC" \
    -I "$QT_IOS/mkspecs/macx-ios-clang" \
    -DQT_LEAN_HEADERS=1 -DQT_NO_DEBUG -DSHIBOKEN_NO_EMBEDDING_PYC -DNDEBUG -O2 -fPIC)

# Phase 0: sbkversion.h
SBKVERSION_H="$LIBSHIBOKEN_SRC/sbkversion.h"
if [ ! -f "$SBKVERSION_H" ]; then
    echo "==> Generating sbkversion.h"
    PYVER=$(grep "^Python version:" "$P6IOS_ROOT/build/python/VERSIONS" | sed 's/Python version: //')
    PY_MAJOR=${PYVER%%.*}; PYREST=${PYVER#*.}; PY_MINOR=${PYREST%%.*}; PY_PATCH=${PYREST#*.}; PY_PATCH=${PY_PATCH%% *}
    sed -e "s/@shiboken_MAJOR_VERSION@/$SHIBOKEN_MAJOR/g" \
        -e "s/@shiboken_MINOR_VERSION@/$SHIBOKEN_MINOR/g" \
        -e "s/@shiboken_MICRO_VERSION@/$SHIBOKEN_MICRO/g" \
        -e "s/@Python_VERSION_MAJOR@/$PY_MAJOR/g" \
        -e "s/@Python_VERSION_MINOR@/$PY_MINOR/g" \
        -e "s/@Python_VERSION_PATCH@/$PY_PATCH/g" \
        "$LIBSHIBOKEN_SRC/sbkversion.h.in" > "$SBKVERSION_H"
fi

compile_lib() {
    local name="$1" outdir="$2" archive="$3"
    shift 3
    local flags=("${BASE_CXXFLAGS[@]}")
    local extra_flags=() sources=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --flags) shift; while [[ $# -gt 0 && "$1" != --* ]]; do extra_flags+=("$1"); shift; done ;;
            --sources) shift; while [[ $# -gt 0 && "$1" != --* ]]; do sources+=("$1"); shift; done ;;
            *) shift ;;
        esac
    done
    flags+=("${extra_flags[@]+"${extra_flags[@]}"}")

    echo "==> Building $name (${#sources[@]} sources)"
    mkdir -p "$outdir"
    local compiled=0 failed=0
    for src in "${sources[@]}"; do
        local base obj
        base=$(basename "$src" .cpp)
        obj="$outdir/$base.o"
        if $CXX "${flags[@]}" -c "$src" -o "$obj" 2>/dev/null; then
            compiled=$((compiled + 1))
        else
            echo "    WARN: $base failed, retrying verbose..."
            if $CXX "${flags[@]}" -c "$src" -o "$obj" 2>&1 | tail -5; then
                compiled=$((compiled + 1))
            else
                echo "    FAILED: $base"; failed=$((failed + 1))
            fi
        fi
    done
    echo "    Compiled: $compiled, Failed: $failed"
    [ "$failed" -gt 0 ] && { echo "ERROR: $failed file(s) failed in $name"; exit 1; }

    echo "    Archiving $archive"
    xcrun -sdk iphoneos libtool -static -o "$outdir/$archive" "$outdir"/*.o 2>&1
    echo "    Done: $(du -h "$outdir/$archive" | cut -f1)"
}

# -- libshiboken6 --
LIBSHIBOKEN_SOURCES=(
    "$LIBSHIBOKEN_SRC/basewrapper.cpp"
    "$LIBSHIBOKEN_SRC/bindingmanager.cpp"
    "$LIBSHIBOKEN_SRC/bufferprocs_py37.cpp"
    "$LIBSHIBOKEN_SRC/gilstate.cpp"
    "$LIBSHIBOKEN_SRC/helper.cpp"
    "$LIBSHIBOKEN_SRC/pep384impl.cpp"
    "$LIBSHIBOKEN_SRC/sbkarrayconverter.cpp"
    "$LIBSHIBOKEN_SRC/sbkcontainer.cpp"
    "$LIBSHIBOKEN_SRC/sbkconverter.cpp"
    "$LIBSHIBOKEN_SRC/sbkcppstring.cpp"
    "$LIBSHIBOKEN_SRC/sbkenum.cpp"
    "$LIBSHIBOKEN_SRC/sbkerrors.cpp"
    "$LIBSHIBOKEN_SRC/sbkfeature_base.cpp"
    "$LIBSHIBOKEN_SRC/sbkmodule.cpp"
    "$LIBSHIBOKEN_SRC/sbknumpy.cpp"
    "$LIBSHIBOKEN_SRC/sbksmartpointer.cpp"
    "$LIBSHIBOKEN_SRC/sbkstaticstrings.cpp"
    "$LIBSHIBOKEN_SRC/sbkstring.cpp"
    "$LIBSHIBOKEN_SRC/sbktypefactory.cpp"
    "$LIBSHIBOKEN_SRC/shibokenbuffer.cpp"
    "$LIBSHIBOKEN_SRC/threadstatesaver.cpp"
    "$LIBSHIBOKEN_SRC/voidptr.cpp"
    "$LIBSHIBOKEN_SRC/signature/signature.cpp"
    "$LIBSHIBOKEN_SRC/signature/signature_extend.cpp"
    "$LIBSHIBOKEN_SRC/signature/signature_globals.cpp"
    "$LIBSHIBOKEN_SRC/signature/signature_helper.cpp"
)
compile_lib "libshiboken6" "$P6IOS_ROOT/build/libshiboken-ios" "libshiboken6.a" \
    --flags -DBUILD_LIBSHIBOKEN \
    --sources "${LIBSHIBOKEN_SOURCES[@]}"

# -- libpyside6 --
LIBPYSIDE_SOURCES=(
    "$LIBPYSIDE_SRC/class_property.cpp"
    "$LIBPYSIDE_SRC/dynamicqmetaobject.cpp"
    "$LIBPYSIDE_SRC/dynamicslot.cpp"
    "$LIBPYSIDE_SRC/feature_select.cpp"
    "$LIBPYSIDE_SRC/pyside.cpp"
    "$LIBPYSIDE_SRC/pyside_numpy.cpp"
    "$LIBPYSIDE_SRC/pysideclassdecorator.cpp"
    "$LIBPYSIDE_SRC/pysideclassinfo.cpp"
    "$LIBPYSIDE_SRC/pysidemetafunction.cpp"
    "$LIBPYSIDE_SRC/pysideproperty.cpp"
    "$LIBPYSIDE_SRC/pysideqenum.cpp"
    "$LIBPYSIDE_SRC/pysideqslotobject_p.cpp"
    "$LIBPYSIDE_SRC/pysidesignal.cpp"
    "$LIBPYSIDE_SRC/pysideslot.cpp"
    "$LIBPYSIDE_SRC/pysidestaticstrings.cpp"
    "$LIBPYSIDE_SRC/pysideweakref.cpp"
    "$LIBPYSIDE_SRC/qobjectconnect.cpp"
    "$LIBPYSIDE_SRC/signalmanager.cpp"
)
compile_lib "libpyside6" "$P6IOS_ROOT/build/libpyside-ios" "libpyside6.a" \
    --flags -DBUILD_LIBPYSIDE -I "$LIBPYSIDE_SRC" \
    --sources "${LIBPYSIDE_SOURCES[@]}"

# -- libpysideqml --
LIBPYSIDEQML_SOURCES=(
    "$LIBPYSIDEQML_SRC/pysideqml.cpp"
    "$LIBPYSIDEQML_SRC/pysideqmlattached.cpp"
    "$LIBPYSIDEQML_SRC/pysideqmlextended.cpp"
    "$LIBPYSIDEQML_SRC/pysideqmlforeign.cpp"
    "$LIBPYSIDEQML_SRC/pysideqmllistproperty.cpp"
    "$LIBPYSIDEQML_SRC/pysideqmlmetacallerror.cpp"
    "$LIBPYSIDEQML_SRC/pysideqmlnamedelement.cpp"
    "$LIBPYSIDEQML_SRC/pysideqmlregistertype.cpp"
    "$LIBPYSIDEQML_SRC/pysideqmltypeinfo.cpp"
    "$LIBPYSIDEQML_SRC/pysideqmluncreatable.cpp"
)
compile_lib "libpysideqml" "$P6IOS_ROOT/build/libpysideqml-ios" "libpysideqml.a" \
    --flags -DBUILD_LIBPYSIDEQML -I "$LIBPYSIDE_SRC" -I "$LIBPYSIDEQML_SRC" \
            $(qt_header_flags QtQml) \
    --sources "${LIBPYSIDEQML_SOURCES[@]}"

# -- shiboken module wrapper --
echo "==> Generating shiboken module wrapper"
GEN_DIR="$P6IOS_ROOT/build/pyside6-ios-gen/shiboken"
mkdir -p "$GEN_DIR"

GLOBAL_H="$P6IOS_ROOT/build/pyside6-ios-gen/shiboken_global.h"
cat > "$GLOBAL_H" << 'EOF'
#include <sbkpython.h>
#include <shiboken.h>
EOF

HOST_PYTHON_INC="$(python3 -c "import sysconfig; print(sysconfig.get_path('include'))")"
SHIBOKEN_INCLUDES="$LIBSHIBOKEN_SRC:$HOST_PYTHON_INC:$QT_MACOS/lib/QtCore.framework/Headers"
API_VERSION="${SHIBOKEN_MAJOR}.${SHIBOKEN_MINOR}"
"$SHIBOKEN6" --enable-pyside-extensions \
    "--include-paths=$SHIBOKEN_INCLUDES" \
    "--typesystem-paths=$SHIBOKEN_MOD_SRC" \
    "--output-directory=$GEN_DIR" \
    --lean-headers "--api-version=$API_VERSION" \
    "$GLOBAL_H" "$SHIBOKEN_MOD_SRC/typesystem_shiboken.xml" 2>&1

WRAPPER_CPP="$GEN_DIR/Shiboken/shiboken_module_wrapper.cpp"
[ -f "$WRAPPER_CPP" ] || { echo "ERROR: shiboken6 did not generate $WRAPPER_CPP"; exit 1; }

echo "==> Cross-compiling shiboken_module_wrapper.o"
mkdir -p "$P6IOS_ROOT/build/shiboken-ios"
$CXX "${BASE_CXXFLAGS[@]}" \
    -I "$LIBPYSIDE_SRC" \
    -I "$P6IOS_ROOT/build/pyside6-ios-gen/shiboken/Shiboken" \
    -c "$WRAPPER_CPP" -o "$P6IOS_ROOT/build/shiboken-ios/shiboken_module_wrapper.o"

echo "==> All support libraries built successfully"
