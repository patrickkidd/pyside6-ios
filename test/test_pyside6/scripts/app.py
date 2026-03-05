"""M5: Full PySide6 QML app on iOS."""
import sys
import os

def _log(msg):
    os.write(1, (str(msg) + "\n").encode())

_log(f"Python {sys.version} on {sys.platform}")

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

_log(f"PySide6 imports OK")

# QGuiApplication was already created by the host app.
# PySide6 wraps the existing instance.
app = QGuiApplication.instance()
_log(f"QGuiApplication: {app}")

engine = QQmlApplicationEngine()

bundle = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
qml_path = os.path.join(bundle, "main.qml")
_log(f"Loading QML: {qml_path}")

engine.load(QUrl.fromLocalFile(qml_path))

if not engine.rootObjects():
    _log("ERROR: QML failed to load")
else:
    _log("QML loaded successfully via PySide6!")
