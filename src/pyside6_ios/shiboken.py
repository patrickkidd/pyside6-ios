import os
import subprocess
from pathlib import Path

from pyside6_ios.config import AppConfig, BindingModule


def _ios_sdk_path() -> str:
    result = subprocess.run(
        ["xcrun", "--sdk", "iphoneos", "--show-sdk-path"],
        capture_output=True, text=True, check=True,
    )
    return result.stdout.strip()


def run(cfg: AppConfig) -> list[Path]:
    if not cfg.binding_modules:
        return []

    build_dir = cfg.pyside6_ios / "build"
    qt_ios = cfg.qt_ios
    qt_macos = qt_ios.parent / "macos"
    python_fw = build_dir / "python/Python.xcframework/ios-arm64/Python.framework"
    pyside_src = build_dir / "pyside-setup/sources"
    ios_sdk = _ios_sdk_path()

    generated_libs = []

    for bmod in cfg.binding_modules:
        mod_build = cfg.output_dir / f"bindings-{bmod.name}"
        gen_dir = mod_build / "gen"
        obj_dir = mod_build / "obj"
        gen_dir.mkdir(parents=True, exist_ok=True)
        obj_dir.mkdir(parents=True, exist_ok=True)

        # Generate global header
        global_h = gen_dir / f"{bmod.name}_global.h"
        with open(global_h, "w") as f:
            f.write("#pragma once\n")
            for h in bmod.headers:
                f.write(f'#include "{(cfg.project_root / h).resolve()}"\n')

        # Run shiboken6
        include_paths = [
            str(qt_macos / "include"),
            str(qt_macos / "include/QtCore"),
            str(qt_macos / "include/QtGui"),
            str(qt_macos / "include/QtWidgets"),
            str(qt_macos / "include/QtQml"),
            str(qt_macos / "include/QtQuick"),
        ]
        for h in bmod.headers:
            include_paths.append(str((cfg.project_root / h).parent.resolve()))

        typesystem_paths = [
            str(pyside_src / "pyside6/PySide6/QtCore"),
            str(pyside_src / "pyside6/PySide6/QtGui"),
            str(pyside_src / "pyside6/PySide6/QtWidgets"),
            str(pyside_src / "pyside6/PySide6/QtQml"),
            str(pyside_src / "pyside6/PySide6/QtQuick"),
            str(pyside_src / "pyside6/PySide6"),
        ]

        framework_paths = [
            str(qt_macos / "lib"),
        ]

        cmd = [
            "shiboken6",
            "--generator-set=shiboken",
            "--enable-pyside-extensions",
            f"--output-directory={gen_dir}",
            str(global_h),
            f"--typesystem-paths={os.pathsep.join(typesystem_paths)}",
            f"--include-paths={os.pathsep.join(include_paths)}",
            f"--framework-include-paths={os.pathsep.join(framework_paths)}",
            str(cfg.project_root / bmod.typesystem),
        ]
        subprocess.run(cmd, check=True)

        # Cross-compile generated wrappers
        wrapper_sources = list(gen_dir.rglob("*.cpp"))
        if not wrapper_sources:
            continue

        pyside_gen = build_dir / "pyside6-ios-gen"

        compile_flags = [
            "xcrun", "-sdk", "iphoneos", "clang++",
            "-arch", "arm64",
            f"-isysroot", ios_sdk,
            "-miphoneos-version-min=16.0",
            "-std=c++17", "-fPIC", "-O2",
            "-DQT_NO_DEBUG", "-DQT_LEAN_HEADERS=1",
            f"-iframework", str(qt_ios / "lib"),
            f"-I{qt_ios}/include",
            f"-I{python_fw}/Headers",
            f"-I{pyside_src}/shiboken6/libshiboken",
            f"-I{pyside_src}/pyside6/libpyside",
            f"-I{pyside_src}/pyside6/PySide6",
            f"-I{pyside_gen}/PySide6/QtCore",
        ]
        # Qt framework Headers dirs (bare includes like <QList> need these)
        for qt_mod in ["QtCore", "QtGui", "QtNetwork", "QtQml", "QtQuick"]:
            fw_headers = qt_ios / "lib" / f"{qt_mod}.framework" / "Headers"
            if fw_headers.is_dir():
                compile_flags.append(f"-I{fw_headers}")
        for h in bmod.headers:
            compile_flags.append(f"-I{(cfg.project_root / h).parent.resolve()}")
        compile_flags.append(f"-I{gen_dir}")

        obj_files = []
        for src in wrapper_sources:
            obj = obj_dir / f"{src.stem}.o"
            subprocess.run(
                [*compile_flags, "-c", str(src), "-o", str(obj)],
                check=True,
            )
            obj_files.append(obj)

        # Archive into static lib
        lib_path = mod_build / f"lib{bmod.name}.a"
        subprocess.run(
            ["ar", "rcs", str(lib_path)] + [str(o) for o in obj_files],
            check=True,
        )
        generated_libs.append(lib_path)

    return generated_libs


