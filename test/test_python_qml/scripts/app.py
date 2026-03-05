"""
M4b: Python-driven QML app on iOS.
This script is executed by the C++ host and uses the qtbridge
C extension to create and control a QML window.
"""
import sys
import os
import qtbridge

print(f"Python {sys.version} driving Qt on {sys.platform}")

# QML file is in the app bundle root
bundle = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
qml_path = os.path.join(bundle, "main.qml")
print(f"Loading QML: {qml_path}")

# Set context properties before loading QML
qtbridge.setProperty("pythonVersion", sys.version.split()[0])
qtbridge.setProperty("appMessage", "Python is driving this QML UI!")

# Load and show the QML scene
qtbridge.loadQml(qml_path)
print("QML loaded from Python")
