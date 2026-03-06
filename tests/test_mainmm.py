from pathlib import Path

from pyside6_ios.config import AppConfig, BindingModule, QmlPlugin
from pyside6_ios.mainmm import generate


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
        pyside6_modules=["QtCore", "QtGui"],
        project_root=Path("/p6ios/test"),
        python_version="3.13",
        signing_style="Automatic",
    )
    defaults.update(overrides)
    return AppConfig(**defaults)


def test_pyside6_module_inittab():
    src = generate(_cfg())
    assert 'extern "C" PyObject *PyInit_QtCore();' in src
    assert 'extern "C" PyObject *PyInit_QtGui();' in src
    assert 'PyImport_AppendInittab("PySide6.QtCore", PyInit_QtCore);' in src
    assert 'PyImport_AppendInittab("PySide6.QtGui", PyInit_QtGui);' in src


def test_shiboken_inittab():
    src = generate(_cfg())
    assert 'extern "C" PyObject *PyInit_Shiboken();' in src
    assert 'PyImport_AppendInittab("shiboken6.Shiboken", PyInit_Shiboken);' in src


def test_qml_plugin_imports():
    cfg = _cfg(qml_plugins=[
        QmlPlugin("QtQuick2Plugin", "qtquick2plugin", "/qt/qml/QtQuick"),
    ])
    src = generate(cfg)
    assert "Q_IMPORT_PLUGIN(QtQuick2Plugin)" in src
    assert "Q_IMPORT_PLUGIN(QIOSIntegrationPlugin)" in src


def test_vendor_path_included():
    cfg = _cfg(vendor_dir="vendor")
    src = generate(cfg)
    assert 'appVendorPath' in src
    assert '"vendor"' in src


def test_vendor_path_excluded():
    cfg = _cfg(vendor_dir="")
    src = generate(cfg)
    assert 'appVendorPath' not in src


def test_python_version_in_stdlib_path():
    cfg = _cfg(python_version="3.13")
    src = generate(cfg)
    assert "lib/python3.13" in src


def test_binding_modules():
    cfg = _cfg(binding_modules=[
        BindingModule("_mymod", ["mymod.h"], "typesystem.xml"),
    ])
    src = generate(cfg)
    assert 'extern "C" PyObject *PyInit_mymod();' in src
    assert 'PyImport_AppendInittab("_mymod", PyInit_mymod);' in src


def test_app_name_in_argv():
    cfg = _cfg(name="My App")
    src = generate(cfg)
    assert '"MyApp"' in src
