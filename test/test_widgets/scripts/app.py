"""PySide6 iOS QtWidgets demo: exercises widgets, shiboken6 bindings, custom QPainter."""
import sys
import os

def _log(msg):
    os.write(1, (str(msg) + "\n").encode())

_log(f"Python {sys.version} on {sys.platform}")

from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication, QMainWindow, QTabWidget
from PySide6.QtGui import QPalette, QColor

_log("PySide6 QtWidgets imports OK")

from myapp.util import appInfo
from AppStateBindings import AppState

_log("Shiboken6 binding import OK")

class MyAppState(AppState):
    def displayName(self):
        return "WidgetsDemo"

info = appInfo()
_log(f"Build UUID: {info['build_uuid']}")

app = QApplication.instance()
_log(f"QApplication: {app}")

myState = MyAppState()
_log(f"C++ deviceModel via binding: {myState.deviceModel()}")
_log(f"Python-overridden displayName: {myState.displayName()}")

# Apply a clean palette
palette = app.palette()
palette.setColor(QPalette.ColorRole.Window, QColor("#f5f6fa"))
palette.setColor(QPalette.ColorRole.WindowText, QColor("#2c3e50"))
palette.setColor(QPalette.ColorRole.Base, QColor("white"))
palette.setColor(QPalette.ColorRole.AlternateBase, QColor("#ecf0f1"))
palette.setColor(QPalette.ColorRole.Highlight, QColor("#3498db"))
palette.setColor(QPalette.ColorRole.HighlightedText, QColor("white"))
app.setPalette(palette)

from myapp.pages import (
    ButtonsPage, InputPage, SlidersPage, ListsPage,
    ContainersPage, GraphicsPage, CalendarPage, DialogsPage,
    PaintPage, InfoPage,
)

win = QMainWindow()
win.setWindowTitle("QtWidgets Demo")

tabs = QTabWidget()
tabs.setTabPosition(QTabWidget.TabPosition.South)
tabs.setDocumentMode(True)

tabs.addTab(InfoPage(myState.deviceModel(), info["python"], info["build_uuid"]), "Info")
tabs.addTab(ButtonsPage(), "Buttons")
tabs.addTab(InputPage(), "Input")
tabs.addTab(SlidersPage(), "Sliders")
tabs.addTab(ListsPage(), "Lists")
tabs.addTab(ContainersPage(), "Layout")
tabs.addTab(GraphicsPage(), "Graphics")
tabs.addTab(CalendarPage(), "Calendar")
tabs.addTab(DialogsPage(), "Dialogs")
tabs.addTab(PaintPage(), "Paint")

win.setCentralWidget(tabs)
win.showFullScreen()

_log("QtWidgets demo loaded successfully!")
