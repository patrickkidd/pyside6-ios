"""PySide6 iOS demo: exercises QML, packages, vendor deps, resources, shiboken6 bindings."""
import sys
import os

def _log(msg):
    os.write(1, (str(msg) + "\n").encode())

_log(f"Python {sys.version} on {sys.platform}")

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

_log("PySide6 imports OK")

# Test app package import
from myapp.util import appInfo

# Test vendor package import
from dateutil.parser import parse as parse_date

info = appInfo()
_log(f"Build UUID: {info['build_uuid']}")
_log(f"Vendor dateutil parse: {parse_date('2026-01-01')}")

from AppStateBindings import AppState

_log("Shiboken6 binding import OK")

# Override C++ virtual from Python
class MyAppState(AppState):
    def displayName(self):
        return "Python-Overridden"

app = QGuiApplication.instance()
_log(f"QGuiApplication: {app}")

myState = MyAppState()
_log(f"C++ deviceModel via binding: {myState.deviceModel()}")
_log(f"Python-overridden displayName: {myState.displayName()}")

engine = QQmlApplicationEngine()

# Expose app info + Python-subclassed AppState to QML
ctx = engine.rootContext()
ctx.setContextProperty("appState", myState)
ctx.setContextProperty("appInfo", {
    "python": info["python"],
    "platform": info["platform"],
    "buildUuid": info["build_uuid"],
    "buildDate": info["build_date"],
})
ctx.setContextProperty("pythonVersion", info["python"])
ctx.setContextProperty("appMessage", "PySide6 + shiboken6 bindings active")

bundle = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# QML files are in qml/ subdirectory of the bundle
qml_dir = os.path.join(bundle, "qml")
qml_path = os.path.join(qml_dir, "main.qml")
_log(f"Loading QML: {qml_path}")

engine.addImportPath(os.path.join(bundle, "qml"))
engine.load(QUrl.fromLocalFile(qml_path))

if not engine.rootObjects():
    _log("ERROR: QML failed to load")
else:
    _log("QML loaded successfully via PySide6!")
