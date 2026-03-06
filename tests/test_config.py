import os
import tempfile
from pathlib import Path
from unittest.mock import patch

import pytest

from pyside6_ios.config import (
    AppConfig, PackageEntry, QmlPlugin, _discover_qml_plugins, _resolve, load,
)


def test_resolve_absolute():
    assert _resolve(Path("/base"), "/abs/path") == Path("/abs/path")


def test_resolve_relative():
    result = _resolve(Path("/base"), "rel/path")
    assert result == Path("/base/rel/path").resolve()


def test_resolve_tilde():
    result = _resolve(Path("/base"), "~/test")
    assert str(result).startswith(os.path.expanduser("~"))


def _write_toml(tmp: Path, extra: str = "") -> Path:
    toml = tmp / "pyside6-ios.toml"
    toml.write_text(f"""
[app]
name = "TestApp"
bundle-id = "com.test.app"
version = "1.0"
team-id = "TEAM123"

[paths]
pyside6-ios = "{tmp}"
qt-ios = "{tmp / 'qt'}"
output-dir = "out"

[pyside6]
modules = ["QtCore"]

[python]
scripts = ["main.py"]

[signing]
style = "Automatic"

{extra}
""")
    return toml


def _setup_build_artifacts(tmp: Path):
    """Create minimal build artifacts that config.load() validates."""
    # Python version detection
    headers = tmp / "build/python/Python.xcframework/ios-arm64/Python.framework/Headers"
    headers.mkdir(parents=True)
    (headers / "patchlevel.h").write_text('#define PY_VERSION "3.13.1"')

    # PySide6 static lib
    static = tmp / "build/pyside6-ios-static"
    static.mkdir(parents=True)
    (static / "libPySide6_QtCore.a").write_text("")

    # Qt iOS SDK
    qt = tmp / "qt"
    qt.mkdir(parents=True)

    # Other required build dirs
    for d in ["build/shiboken-ios", "build/libpyside-ios",
              "build/libpysideqml-ios", "build/QtRuntime.framework"]:
        (tmp / d).mkdir(parents=True)


def test_load_minimal(tmp_path):
    _setup_build_artifacts(tmp_path)
    toml = _write_toml(tmp_path)

    cfg = load(toml)
    assert cfg.name == "TestApp"
    assert cfg.bundle_id == "com.test.app"
    assert cfg.version == "1.0"
    assert cfg.team_id == "TEAM123"
    assert cfg.pyside6_modules == ["QtCore"]
    assert cfg.python_version == "3.13"
    assert cfg.signing_style == "Automatic"
    assert cfg.project_root == tmp_path


def test_load_packages(tmp_path):
    _setup_build_artifacts(tmp_path)
    # Write a custom toml without the base [python] to avoid duplicate section
    toml = tmp_path / "pyside6-ios.toml"
    toml.write_text(f"""
[app]
name = "TestApp"
bundle-id = "com.test.app"
version = "1.0"
team-id = "TEAM123"

[paths]
pyside6-ios = "{tmp_path}"
qt-ios = "{tmp_path / 'qt'}"
output-dir = "out"

[pyside6]
modules = ["QtCore"]

[python]
packages = [
    {{ src = "myapp", exclude = ["*.pyc"] }},
    {{ src = "lib", as = "mylib" }},
]
vendor-dir = "vendor"
scripts = ["run.py"]

[signing]
style = "Automatic"
""")
    cfg = load(toml)
    assert len(cfg.packages) == 2
    assert cfg.packages[0].src == "myapp"
    assert cfg.packages[0].exclude == ["*.pyc"]
    assert cfg.packages[1].dest == "mylib"
    assert cfg.vendor_dir == "vendor"


def test_load_resources(tmp_path):
    _setup_build_artifacts(tmp_path)
    toml = _write_toml(tmp_path, """
[resources]
dirs = ["res/images"]
assets = "Assets.xcassets"
settings-bundle = "Settings.bundle"
""")
    cfg = load(toml)
    assert cfg.resource_dirs == ["res/images"]
    assert cfg.assets == "Assets.xcassets"
    assert cfg.settings_bundle == "Settings.bundle"


def test_load_defines(tmp_path):
    _setup_build_artifacts(tmp_path)
    toml = _write_toml(tmp_path, """
[defines]
common = ["APP=1"]
debug = ["DEBUG=1"]
""")
    cfg = load(toml)
    assert cfg.defines_common == ["APP=1"]
    assert cfg.defines_debug == ["DEBUG=1"]


def test_load_build_settings(tmp_path):
    _setup_build_artifacts(tmp_path)
    toml = _write_toml(tmp_path, """
[build-settings]
CLANG_ENABLE_MODULES = "YES"

[build-settings.debug]
GCC_OPTIMIZATION_LEVEL = "0"
""")
    cfg = load(toml)
    assert cfg.build_settings["CLANG_ENABLE_MODULES"] == "YES"
    assert cfg.build_settings_debug["GCC_OPTIMIZATION_LEVEL"] == "0"


def test_load_entitlements(tmp_path):
    _setup_build_artifacts(tmp_path)
    toml = _write_toml(tmp_path, """
[entitlements]
file = "App.entitlements"
""")
    cfg = load(toml)
    assert cfg.entitlements == "App.entitlements"


def test_discover_qml_plugins(tmp_path):
    qml_root = tmp_path / "qml/QtQuick"
    qml_root.mkdir(parents=True)
    (qml_root / "qmldir").write_text(
        "module QtQuick\nclassname QtQuick2Plugin\nplugin qtquick2plugin\n"
    )
    (qml_root / "libqtquick2plugin.a").write_text("")

    plugins = _discover_qml_plugins(tmp_path, ["QtQuick"])
    assert len(plugins) == 1
    assert plugins[0].classname == "QtQuick2Plugin"
    assert plugins[0].libname == "qtquick2plugin"
    assert plugins[0].libdir == str(qml_root)


def test_discover_qml_plugins_deduplicates(tmp_path):
    for mod in ["QtQuick", "QtQuick/Controls"]:
        d = tmp_path / "qml" / mod
        d.mkdir(parents=True)
        (d / "qmldir").write_text("classname SharedPlugin\nplugin shared\n")
        (d / "libshared.a").write_text("")

    plugins = _discover_qml_plugins(tmp_path, ["QtQuick"])
    classnames = [p.classname for p in plugins]
    assert classnames.count("SharedPlugin") == 1


def test_missing_pyside6_module_raises(tmp_path):
    _setup_build_artifacts(tmp_path)
    toml = _write_toml(tmp_path)
    # Override modules to include one that doesn't exist
    toml.write_text(toml.read_text().replace(
        'modules = ["QtCore"]',
        'modules = ["QtCore", "QtWidgets"]'
    ))
    with pytest.raises(FileNotFoundError, match="QtWidgets"):
        load(toml)
