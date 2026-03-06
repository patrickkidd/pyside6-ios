from pathlib import Path

from pyside6_ios.config import AppConfig, PackageEntry, QmlPlugin
from pyside6_ios.pbxproj import generate, _escape, IdGen


def _cfg(**overrides) -> AppConfig:
    defaults = dict(
        name="TestApp",
        bundle_id="com.test.app",
        version="1.0",
        entry_point="",
        team_id="TEAM123",
        deployment_target="16.0",
        pyside6_ios=Path("/p6ios"),
        qt_ios=Path("/qt-ios"),
        output_dir=Path("/p6ios/test/out"),
        pyside6_modules=["QtCore"],
        project_root=Path("/p6ios/test"),
        python_version="3.13",
        signing_style="Automatic",
    )
    defaults.update(overrides)
    return AppConfig(**defaults)


def test_idgen_deterministic():
    g = IdGen()
    assert g.next() == "000000000000000000000001"
    assert g.next() == "000000000000000000000002"


def test_escape_simple():
    assert _escape("YES") == "YES"
    assert _escape("com.test.app") == '"com.test.app"'
    assert _escape("path/to/file") == '"path/to/file"'
    assert _escape("has space") == '"has space"'


def test_generate_minimal():
    cfg = _cfg()
    pbx = generate(cfg)
    assert "archiveVersion = 1;" in pbx
    assert "objectVersion = 56;" in pbx
    assert "main.mm" in pbx
    assert "QtRuntime.framework" in pbx
    assert "Python.framework" in pbx
    assert "TEAM123" in pbx
    assert '"com.test.app"' in pbx


def test_generate_has_sources_phase():
    cfg = _cfg()
    pbx = generate(cfg)
    assert "PBXSourcesBuildPhase" in pbx
    assert "PBXFrameworksBuildPhase" in pbx
    assert "PBXShellScriptBuildPhase" in pbx


def test_generate_pyside6_modules():
    cfg = _cfg(pyside6_modules=["QtCore", "QtGui"])
    pbx = generate(cfg)
    assert "libPySide6_QtCore.a" in pbx
    assert "libPySide6_QtGui.a" in pbx


def test_generate_qml_plugins_ldflags():
    cfg = _cfg(qml_plugins=[
        QmlPlugin("QtQuick2Plugin", "qtquick2plugin", "/qt/qml/QtQuick"),
    ])
    pbx = generate(cfg)
    assert '"-lqtquick2plugin"' in pbx
    assert "OTHER_LDFLAGS" in pbx


def test_generate_qml_plugin_lib_search_paths():
    cfg = _cfg(qml_plugins=[
        QmlPlugin("Plug", "plug", "/qt/qml/Mod"),
    ])
    pbx = generate(cfg)
    assert "/qt/qml/Mod" in pbx


def test_generate_assets_catalog():
    cfg = _cfg(assets="Assets.xcassets")
    pbx = generate(cfg)
    assert "folder.assetcatalog" in pbx
    assert "PBXResourcesBuildPhase" in pbx


def test_generate_no_assets_no_resources_phase():
    cfg = _cfg()
    pbx = generate(cfg)
    assert "PBXResourcesBuildPhase" not in pbx


def test_generate_entitlements():
    cfg = _cfg(entitlements="App.entitlements")
    pbx = generate(cfg)
    assert "CODE_SIGN_ENTITLEMENTS" in pbx
    assert '"App.entitlements"' in pbx


def test_generate_resource_dirs():
    cfg = _cfg(resource_dirs=["images"])
    pbx = generate(cfg)
    assert "Copy Resources" in pbx
    assert "app_resources" in pbx  # not "resources" to avoid iOS bundle conflict


def test_generate_settings_bundle():
    cfg = _cfg(settings_bundle="Settings.bundle")
    pbx = generate(cfg)
    assert "Settings.bundle" in pbx
    assert "codesign" in pbx


def test_generate_build_settings():
    cfg = _cfg(build_settings={"CLANG_ENABLE_MODULES": "YES"})
    pbx = generate(cfg)
    assert "CLANG_ENABLE_MODULES = YES;" in pbx


def test_generate_script_sandboxing_disabled():
    cfg = _cfg()
    pbx = generate(cfg)
    assert "ENABLE_USER_SCRIPT_SANDBOXING = NO;" in pbx


def test_generate_shell_scripts():
    cfg = _cfg(
        packages=[PackageEntry("myapp", ["*.pyc"])],
        vendor_dir="vendor",
        scripts=["app.py"],
    )
    pbx = generate(cfg)
    assert "Copy Python Stdlib" in pbx
    assert "Copy Python Packages" in pbx
    assert "Copy QML Modules" in pbx


def test_generate_extra_source_files():
    cfg = _cfg(source_files=["native/deviceinfo.mm", "native/appstate.cpp"])
    pbx = generate(cfg)
    assert "deviceinfo.mm" in pbx
    assert "appstate.cpp" in pbx
    assert "sourcecode.cpp.objcpp" in pbx  # .mm filetype


def test_generate_header_search_paths():
    cfg = _cfg(header_search_paths=["native"])
    pbx = generate(cfg)
    assert "/p6ios/test/native" in pbx
    assert "HEADER_SEARCH_PATHS" in pbx


def test_generate_resource_files_glob():
    cfg = _cfg(resource_files=["resources/fonts/*"])
    pbx = generate(cfg)
    assert "Copy Resources" in pbx
    assert "app_resources" in pbx


def test_generate_moc_files():
    moc_files = [Path("/p6ios/test/out/moc/moc_appstate.cpp")]
    cfg = _cfg()
    pbx = generate(cfg, moc_files=moc_files)
    assert "moc_appstate.cpp" in pbx


def test_generate_binding_libs():
    binding_libs = [Path("/p6ios/test/out/bindings-MyMod/libMyMod.a")]
    cfg = _cfg()
    pbx = generate(cfg, binding_libs=binding_libs)
    assert "libMyMod.a" in pbx
    assert "bindings-MyMod" in pbx  # lib search path
