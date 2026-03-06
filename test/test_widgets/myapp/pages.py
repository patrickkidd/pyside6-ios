"""Individual tab pages for the QtWidgets showcase."""
import math
import random

from PySide6.QtCore import Qt, QTimer, QPointF, QRectF, QPropertyAnimation, QEasingCurve
from PySide6.QtGui import (
    QPainter, QPen, QBrush, QColor, QFont, QLinearGradient,
    QRadialGradient, QPainterPath, QPolygonF, QTransform,
)
from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QGridLayout, QFormLayout,
    QGroupBox, QScrollArea, QSplitter, QTabWidget, QStackedWidget,
    QPushButton, QToolButton, QCheckBox, QRadioButton, QButtonGroup,
    QLabel, QLineEdit, QTextEdit, QPlainTextEdit,
    QSpinBox, QDoubleSpinBox, QSlider, QDial, QComboBox,
    QProgressBar, QLCDNumber, QCalendarWidget,
    QListWidget, QListWidgetItem, QTreeWidget, QTreeWidgetItem,
    QTableWidget, QTableWidgetItem, QHeaderView,
    QGraphicsView, QGraphicsScene, QGraphicsEllipseItem,
    QGraphicsRectItem, QGraphicsLineItem, QGraphicsTextItem,
    QGraphicsPathItem, QGraphicsItemGroup,
    QColorDialog, QFontDialog, QInputDialog, QMessageBox,
    QFrame, QSizePolicy,
)


def _hLine():
    line = QFrame()
    line.setFrameShape(QFrame.Shape.HLine)
    line.setFrameShadow(QFrame.Shadow.Sunken)
    return line


class ButtonsPage(QWidget):
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        layout.setContentsMargins(12, 12, 12, 12)
        self.setLayout(layout)

        # Push buttons
        grp = QGroupBox("Push Buttons")
        g = QGridLayout()
        grp.setLayout(g)
        btn = QPushButton("Normal")
        g.addWidget(btn, 0, 0)
        flat = QPushButton("Flat")
        flat.setFlat(True)
        g.addWidget(flat, 0, 1)
        disabled = QPushButton("Disabled")
        disabled.setEnabled(False)
        g.addWidget(disabled, 0, 2)
        toggle = QPushButton("Toggle")
        toggle.setCheckable(True)
        g.addWidget(toggle, 1, 0)
        icon_btn = QPushButton("Styled")
        icon_btn.setStyleSheet("background-color: #3498db; color: white; border-radius: 6px; padding: 8px;")
        g.addWidget(icon_btn, 1, 1)
        layout.addWidget(grp)

        # Tool buttons
        grp2 = QGroupBox("Tool Buttons")
        h = QHBoxLayout()
        grp2.setLayout(h)
        for style, label in [
            (Qt.ToolButtonStyle.ToolButtonTextOnly, "Text"),
            (Qt.ToolButtonStyle.ToolButtonTextBesideIcon, "Beside"),
            (Qt.ToolButtonStyle.ToolButtonTextUnderIcon, "Under"),
        ]:
            tb = QToolButton()
            tb.setText(label)
            tb.setToolButtonStyle(style)
            h.addWidget(tb)
        layout.addWidget(grp2)

        # Check boxes
        grp3 = QGroupBox("Check Boxes")
        v = QVBoxLayout()
        grp3.setLayout(v)
        for label, state in [("Unchecked", Qt.CheckState.Unchecked),
                             ("Checked", Qt.CheckState.Checked),
                             ("Tristate", Qt.CheckState.PartiallyChecked)]:
            cb = QCheckBox(label)
            if label == "Tristate":
                cb.setTristate(True)
            cb.setCheckState(state)
            v.addWidget(cb)
        layout.addWidget(grp3)

        # Radio buttons
        grp4 = QGroupBox("Radio Buttons")
        h2 = QHBoxLayout()
        grp4.setLayout(h2)
        bg = QButtonGroup(self)
        for i, label in enumerate(["Option A", "Option B", "Option C"]):
            rb = QRadioButton(label)
            if i == 0:
                rb.setChecked(True)
            bg.addButton(rb)
            h2.addWidget(rb)
        layout.addWidget(grp4)

        layout.addStretch()


class InputPage(QWidget):
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        layout.setContentsMargins(12, 12, 12, 12)
        self.setLayout(layout)

        form = QFormLayout()
        self.lineEdit = QLineEdit()
        self.lineEdit.setPlaceholderText("Type here...")
        form.addRow("Line Edit:", self.lineEdit)

        self.password = QLineEdit()
        self.password.setEchoMode(QLineEdit.EchoMode.Password)
        self.password.setPlaceholderText("Password")
        form.addRow("Password:", self.password)

        self.spinBox = QSpinBox()
        self.spinBox.setRange(0, 100)
        self.spinBox.setValue(42)
        form.addRow("SpinBox:", self.spinBox)

        self.doubleSpinBox = QDoubleSpinBox()
        self.doubleSpinBox.setRange(0.0, 1.0)
        self.doubleSpinBox.setSingleStep(0.1)
        self.doubleSpinBox.setValue(0.5)
        form.addRow("DoubleSpin:", self.doubleSpinBox)

        self.combo = QComboBox()
        self.combo.addItems(["Apple", "Banana", "Cherry", "Date", "Elderberry"])
        self.combo.setEditable(True)
        form.addRow("ComboBox:", self.combo)

        self.readOnlyCombo = QComboBox()
        self.readOnlyCombo.addItems(["Read", "Only", "Combo"])
        form.addRow("Fixed Combo:", self.readOnlyCombo)

        layout.addLayout(form)
        layout.addWidget(_hLine())

        layout.addWidget(QLabel("Multi-line Text Edit:"))
        self.textEdit = QTextEdit()
        self.textEdit.setPlaceholderText("Rich text editing...")
        self.textEdit.setMaximumHeight(100)
        layout.addWidget(self.textEdit)

        layout.addWidget(QLabel("Plain Text Edit:"))
        self.plainText = QPlainTextEdit()
        self.plainText.setPlaceholderText("Plain text only...")
        self.plainText.setMaximumHeight(80)
        layout.addWidget(self.plainText)

        layout.addStretch()


class SlidersPage(QWidget):
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        layout.setContentsMargins(12, 12, 12, 12)
        self.setLayout(layout)

        # Horizontal slider + LCD
        grp = QGroupBox("Horizontal Slider")
        v = QVBoxLayout()
        grp.setLayout(v)
        self.lcd = QLCDNumber(3)
        self.lcd.setSegmentStyle(QLCDNumber.SegmentStyle.Flat)
        self.lcd.setFixedHeight(50)
        v.addWidget(self.lcd)
        self.hSlider = QSlider(Qt.Orientation.Horizontal)
        self.hSlider.setRange(0, 100)
        self.hSlider.setValue(50)
        self.hSlider.setTickPosition(QSlider.TickPosition.TicksBelow)
        self.hSlider.setTickInterval(10)
        self.hSlider.valueChanged.connect(self.lcd.display)
        self.lcd.display(50)
        v.addWidget(self.hSlider)
        layout.addWidget(grp)

        # Dial
        grp2 = QGroupBox("Dial + Progress Bar")
        g = QHBoxLayout()
        grp2.setLayout(g)
        self.dial = QDial()
        self.dial.setRange(0, 100)
        self.dial.setNotchesVisible(True)
        self.dial.setValue(25)
        g.addWidget(self.dial)
        vr = QVBoxLayout()
        self.progress = QProgressBar()
        self.progress.setRange(0, 100)
        self.progress.setValue(25)
        vr.addWidget(self.progress)
        self.progressLabel = QLabel("25%")
        self.progressLabel.setAlignment(Qt.AlignmentFlag.AlignCenter)
        vr.addWidget(self.progressLabel)
        g.addLayout(vr)
        self.dial.valueChanged.connect(self._onDialChanged)
        layout.addWidget(grp2)

        # Animated progress bar
        grp3 = QGroupBox("Animated Progress")
        v3 = QVBoxLayout()
        grp3.setLayout(v3)
        self.animProgress = QProgressBar()
        self.animProgress.setRange(0, 100)
        v3.addWidget(self.animProgress)
        h = QHBoxLayout()
        startBtn = QPushButton("Start")
        startBtn.clicked.connect(self._startAnim)
        resetBtn = QPushButton("Reset")
        resetBtn.clicked.connect(self._resetAnim)
        h.addWidget(startBtn)
        h.addWidget(resetBtn)
        v3.addLayout(h)
        layout.addWidget(grp3)

        self.animTimer = QTimer(self)
        self.animTimer.timeout.connect(self._tickAnim)

        layout.addStretch()

    def _onDialChanged(self, val):
        self.progress.setValue(val)
        self.progressLabel.setText(f"{val}%")

    def _startAnim(self):
        self.animProgress.setValue(0)
        self.animTimer.start(50)

    def _resetAnim(self):
        self.animTimer.stop()
        self.animProgress.setValue(0)

    def _tickAnim(self):
        v = self.animProgress.value() + 1
        self.animProgress.setValue(v)
        if v >= 100:
            self.animTimer.stop()


class ListsPage(QWidget):
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        layout.setContentsMargins(12, 12, 12, 12)
        self.setLayout(layout)

        tabs = QTabWidget()

        # List widget
        lw = QListWidget()
        for i in range(20):
            item = QListWidgetItem(f"List item {i + 1}")
            if i % 3 == 0:
                item.setCheckState(Qt.CheckState.Checked)
            else:
                item.setCheckState(Qt.CheckState.Unchecked)
            lw.addItem(item)
        tabs.addTab(lw, "List")

        # Tree widget
        tw = QTreeWidget()
        tw.setHeaderLabels(["Name", "Type", "Size"])
        tw.setColumnCount(3)
        for category, items in [
            ("Fruits", [("Apple", "Red", "Medium"), ("Banana", "Yellow", "Large"), ("Cherry", "Red", "Small")]),
            ("Vegetables", [("Carrot", "Orange", "Medium"), ("Pea", "Green", "Small"), ("Potato", "Brown", "Large")]),
            ("Grains", [("Rice", "White", "Small"), ("Wheat", "Gold", "Medium"), ("Oat", "Tan", "Small")]),
        ]:
            parent = QTreeWidgetItem([category])
            for name, color, size in items:
                child = QTreeWidgetItem([name, color, size])
                parent.addChild(child)
            tw.addTopLevelItem(parent)
            parent.setExpanded(True)
        tw.header().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        tabs.addTab(tw, "Tree")

        # Table widget
        table = QTableWidget(8, 4)
        table.setHorizontalHeaderLabels(["Name", "Age", "City", "Score"])
        data = [
            ("Alice", "28", "Tokyo", "92"), ("Bob", "35", "London", "87"),
            ("Carol", "42", "Paris", "95"), ("Dave", "31", "Sydney", "78"),
            ("Eve", "26", "Berlin", "88"), ("Frank", "39", "NYC", "91"),
            ("Grace", "33", "Seoul", "96"), ("Hank", "45", "Rome", "83"),
        ]
        for r, row in enumerate(data):
            for c, val in enumerate(row):
                table.setItem(r, c, QTableWidgetItem(val))
        table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        table.setAlternatingRowColors(True)
        tabs.addTab(table, "Table")

        layout.addWidget(tabs)


class ContainersPage(QWidget):
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        layout.setContentsMargins(12, 12, 12, 12)
        self.setLayout(layout)

        # Splitter demo
        grp = QGroupBox("Splitter")
        v = QVBoxLayout()
        grp.setLayout(v)
        splitter = QSplitter(Qt.Orientation.Horizontal)
        left = QLabel("Left\nPane")
        left.setAlignment(Qt.AlignmentFlag.AlignCenter)
        left.setStyleSheet("background: #ecf0f1; padding: 10px;")
        right = QLabel("Right\nPane")
        right.setAlignment(Qt.AlignmentFlag.AlignCenter)
        right.setStyleSheet("background: #d5dbdb; padding: 10px;")
        splitter.addWidget(left)
        splitter.addWidget(right)
        splitter.setSizes([150, 150])
        v.addWidget(splitter)
        layout.addWidget(grp)

        # Stacked widget
        grp2 = QGroupBox("Stacked Widget")
        v2 = QVBoxLayout()
        grp2.setLayout(v2)
        h = QHBoxLayout()
        self.stackBtns = []
        self.stack = QStackedWidget()
        colors = [("#e74c3c", "Red Page"), ("#2ecc71", "Green Page"), ("#3498db", "Blue Page")]
        for i, (color, text) in enumerate(colors):
            page = QLabel(text)
            page.setAlignment(Qt.AlignmentFlag.AlignCenter)
            page.setStyleSheet(f"background: {color}; color: white; font-size: 16px; padding: 20px;")
            self.stack.addWidget(page)
            btn = QPushButton(text.split()[0])
            btn.clicked.connect(lambda checked, idx=i: self.stack.setCurrentIndex(idx))
            self.stackBtns.append(btn)
            h.addWidget(btn)
        v2.addLayout(h)
        v2.addWidget(self.stack)
        layout.addWidget(grp2)

        # Scroll area
        grp3 = QGroupBox("Scroll Area")
        v3 = QVBoxLayout()
        grp3.setLayout(v3)
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setMaximumHeight(120)
        inner = QWidget()
        innerLayout = QVBoxLayout()
        inner.setLayout(innerLayout)
        for i in range(15):
            innerLayout.addWidget(QLabel(f"Scrollable item {i + 1}"))
        scroll.setWidget(inner)
        v3.addWidget(scroll)
        layout.addWidget(grp3)

        layout.addStretch()


class GraphicsPage(QWidget):
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        layout.setContentsMargins(8, 8, 8, 8)
        self.setLayout(layout)

        self.scene = QGraphicsScene(-200, -200, 400, 400)
        self.view = QGraphicsView(self.scene)
        self.view.setRenderHint(QPainter.RenderHint.Antialiasing)
        self.view.setDragMode(QGraphicsView.DragMode.ScrollHandDrag)

        self._buildScene()

        layout.addWidget(self.view)

        h = QHBoxLayout()
        zoomIn = QPushButton("Zoom In")
        zoomIn.clicked.connect(lambda: self.view.scale(1.2, 1.2))
        zoomOut = QPushButton("Zoom Out")
        zoomOut.clicked.connect(lambda: self.view.scale(1 / 1.2, 1 / 1.2))
        resetBtn = QPushButton("Reset")
        resetBtn.clicked.connect(lambda: self.view.resetTransform())
        addBtn = QPushButton("Add Shape")
        addBtn.clicked.connect(self._addRandomShape)
        h.addWidget(zoomIn)
        h.addWidget(zoomOut)
        h.addWidget(resetBtn)
        h.addWidget(addBtn)
        layout.addLayout(h)

    def _buildScene(self):
        # Gradient background rect
        bg = QLinearGradient(QPointF(-200, -200), QPointF(200, 200))
        bg.setColorAt(0, QColor("#2c3e50"))
        bg.setColorAt(1, QColor("#3498db"))
        self.scene.setBackgroundBrush(QBrush(bg))

        # Concentric circles
        for i in range(5, 0, -1):
            r = i * 30
            ellipse = self.scene.addEllipse(
                QRectF(-r, -r, 2 * r, 2 * r),
                QPen(QColor(255, 255, 255, 50), 1),
                QBrush(QColor(255, 255, 255, 15 + i * 8)),
            )
            ellipse.setFlag(ellipse.GraphicsItemFlag.ItemIsMovable)

        # Star path
        path = QPainterPath()
        for i in range(5):
            angle = math.radians(i * 144 - 90)
            pt = QPointF(60 * math.cos(angle), 60 * math.sin(angle))
            if i == 0:
                path.moveTo(pt)
            else:
                path.lineTo(pt)
        path.closeSubpath()
        star = self.scene.addPath(
            path,
            QPen(QColor("#f1c40f"), 2),
            QBrush(QColor(241, 196, 15, 120)),
        )
        star.setPos(120, -80)
        star.setFlag(star.GraphicsItemFlag.ItemIsMovable)

        # Colored rectangles
        colors = ["#e74c3c", "#2ecc71", "#9b59b6", "#e67e22"]
        for i, color in enumerate(colors):
            rect = self.scene.addRect(
                QRectF(0, 0, 50, 50),
                QPen(Qt.PenStyle.NoPen),
                QBrush(QColor(color)),
            )
            rect.setPos(-160 + i * 55, 120)
            rect.setRotation(i * 15)
            rect.setFlag(rect.GraphicsItemFlag.ItemIsMovable)
            rect.setFlag(rect.GraphicsItemFlag.ItemIsSelectable)

        # Text items
        title = self.scene.addText("QGraphicsView", QFont("Helvetica", 18, QFont.Weight.Bold))
        title.setDefaultTextColor(QColor("white"))
        title.setPos(-90, -180)

        subtitle = self.scene.addText("Drag items around!", QFont("Helvetica", 11))
        subtitle.setDefaultTextColor(QColor(255, 255, 255, 180))
        subtitle.setPos(-70, -150)

        # Lines radiating from center
        for angle in range(0, 360, 30):
            rad = math.radians(angle)
            self.scene.addLine(
                0, 0,
                140 * math.cos(rad), 140 * math.sin(rad),
                QPen(QColor(255, 255, 255, 30), 1),
            )

    def _addRandomShape(self):
        x = random.randint(-150, 150)
        y = random.randint(-150, 150)
        color = QColor(random.randint(50, 255), random.randint(50, 255), random.randint(50, 255))
        if random.random() > 0.5:
            item = self.scene.addEllipse(
                QRectF(0, 0, 40, 40),
                QPen(color.darker(), 2),
                QBrush(color),
            )
        else:
            item = self.scene.addRect(
                QRectF(0, 0, 40, 40),
                QPen(color.darker(), 2),
                QBrush(color),
            )
        item.setPos(x, y)
        item.setFlag(item.GraphicsItemFlag.ItemIsMovable)
        item.setFlag(item.GraphicsItemFlag.ItemIsSelectable)


class CalendarPage(QWidget):
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        layout.setContentsMargins(12, 12, 12, 12)
        self.setLayout(layout)

        self.calendar = QCalendarWidget()
        self.calendar.setGridVisible(True)
        layout.addWidget(self.calendar)

        self.dateLabel = QLabel()
        self.dateLabel.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.dateLabel.setStyleSheet("font-size: 16px; padding: 10px;")
        self.calendar.selectionChanged.connect(self._onDateChanged)
        self._onDateChanged()
        layout.addWidget(self.dateLabel)

        layout.addStretch()

    def _onDateChanged(self):
        d = self.calendar.selectedDate()
        self.dateLabel.setText(f"Selected: {d.toString('dddd, MMMM d, yyyy')}")


class DialogsPage(QWidget):
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        layout.setContentsMargins(12, 12, 12, 12)
        self.setLayout(layout)

        self.resultLabel = QLabel("Tap a button to show a dialog")
        self.resultLabel.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.resultLabel.setWordWrap(True)
        self.resultLabel.setStyleSheet("font-size: 14px; padding: 10px; background: #ecf0f1; border-radius: 6px;")
        layout.addWidget(self.resultLabel)
        layout.addWidget(_hLine())

        grid = QGridLayout()

        msgBtn = QPushButton("Message Box")
        msgBtn.clicked.connect(self._showMessage)
        grid.addWidget(msgBtn, 0, 0)

        questionBtn = QPushButton("Question")
        questionBtn.clicked.connect(self._showQuestion)
        grid.addWidget(questionBtn, 0, 1)

        colorBtn = QPushButton("Color Picker")
        colorBtn.clicked.connect(self._showColor)
        grid.addWidget(colorBtn, 1, 0)

        fontBtn = QPushButton("Font Picker")
        fontBtn.clicked.connect(self._showFont)
        grid.addWidget(fontBtn, 1, 1)

        inputBtn = QPushButton("Text Input")
        inputBtn.clicked.connect(self._showInput)
        grid.addWidget(inputBtn, 2, 0)

        intBtn = QPushButton("Int Input")
        intBtn.clicked.connect(self._showIntInput)
        grid.addWidget(intBtn, 2, 1)

        layout.addLayout(grid)
        layout.addStretch()

    def _showMessage(self):
        QMessageBox.information(self, "Info", "This is a QMessageBox on iOS!")
        self.resultLabel.setText("Message box shown")

    def _showQuestion(self):
        result = QMessageBox.question(self, "Question", "Do you like QtWidgets on iOS?")
        answer = "Yes" if result == QMessageBox.StandardButton.Yes else "No"
        self.resultLabel.setText(f"Answer: {answer}")

    def _showColor(self):
        color = QColorDialog.getColor(QColor("#3498db"), self, "Pick a Color")
        if color.isValid():
            self.resultLabel.setText(f"Color: {color.name()}")
            self.resultLabel.setStyleSheet(
                f"font-size: 14px; padding: 10px; background: {color.name()}; "
                f"color: {'white' if color.lightness() < 128 else 'black'}; border-radius: 6px;"
            )

    def _showFont(self):
        ok, font = QFontDialog.getFont(QFont("Helvetica", 14), self)
        if ok:
            self.resultLabel.setText(f"Font: {font.family()} {font.pointSize()}pt")
            self.resultLabel.setFont(font)

    def _showInput(self):
        text, ok = QInputDialog.getText(self, "Input", "Enter your name:")
        if ok and text:
            self.resultLabel.setText(f"Hello, {text}!")

    def _showIntInput(self):
        val, ok = QInputDialog.getInt(self, "Integer", "Pick a number:", 50, 0, 100)
        if ok:
            self.resultLabel.setText(f"Number: {val}")


class PaintPage(QWidget):
    """Custom QPainter rendering demo."""

    def __init__(self):
        super().__init__()
        self._hue = 0
        self.timer = QTimer(self)
        self.timer.timeout.connect(self._tick)
        self.timer.start(30)

    def _tick(self):
        self._hue = (self._hue + 1) % 360
        self.update()

    def paintEvent(self, event):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        w, h = self.width(), self.height()
        cx, cy = w / 2, h / 2

        # Background gradient
        grad = QRadialGradient(QPointF(cx, cy), max(w, h) / 2)
        grad.setColorAt(0, QColor.fromHsv(self._hue, 40, 40))
        grad.setColorAt(1, QColor.fromHsv((self._hue + 180) % 360, 40, 20))
        p.fillRect(self.rect(), QBrush(grad))

        # Rotating arcs
        p.save()
        p.translate(cx, cy)
        for i in range(12):
            angle = self._hue * 2 + i * 30
            color = QColor.fromHsv((self._hue + i * 30) % 360, 200, 220, 160)
            p.setPen(QPen(color, 3))
            r = min(w, h) * 0.3
            rect = QRectF(-r, -r, 2 * r, 2 * r)
            p.drawArc(rect, int(angle * 16), 60 * 16)
        p.restore()

        # Bouncing circles
        for i in range(8):
            phase = math.radians(self._hue * 3 + i * 45)
            x = cx + math.cos(phase) * min(w, h) * 0.25
            y = cy + math.sin(phase * 1.3) * min(w, h) * 0.2
            radius = 12 + 6 * math.sin(phase * 2)
            color = QColor.fromHsv((self._hue + i * 45) % 360, 220, 255, 200)
            p.setBrush(QBrush(color))
            p.setPen(Qt.PenStyle.NoPen)
            p.drawEllipse(QPointF(x, y), radius, radius)

        # Title
        p.setPen(QColor(255, 255, 255, 220))
        p.setFont(QFont("Helvetica", 16, QFont.Weight.Bold))
        p.drawText(self.rect(), Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignHCenter, "Custom QPainter")

        p.end()


class InfoPage(QWidget):
    def __init__(self, deviceModel, pythonVersion, buildUuid):
        super().__init__()
        layout = QVBoxLayout()
        layout.setContentsMargins(12, 12, 12, 12)
        self.setLayout(layout)

        title = QLabel("PySide6 QtWidgets on iOS")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        title.setStyleSheet("font-size: 20px; font-weight: bold; padding: 10px;")
        layout.addWidget(title)
        layout.addWidget(_hLine())

        info = [
            ("Python", pythonVersion),
            ("Platform", "iOS (arm64)"),
            ("Device", deviceModel),
            ("Build ID", buildUuid),
            ("Qt Version", "6.8.3"),
            ("UI Framework", "QtWidgets"),
            ("C++ Bridge", "shiboken6"),
            ("Native Code", "Obj-C++ deviceinfo"),
        ]
        form = QFormLayout()
        for label, value in info:
            valLabel = QLabel(value)
            valLabel.setStyleSheet("font-weight: bold;")
            form.addRow(f"{label}:", valLabel)
        layout.addLayout(form)
        layout.addWidget(_hLine())

        desc = QLabel(
            "This demo exercises every major feature of the pyside6-ios build tool "
            "with QtWidgets instead of QML: custom C++ classes, Objective-C++ native code, "
            "MOC auto-detection, shiboken6 bindings, Python packages, and the full "
            "QtWidgets control set including QGraphicsView."
        )
        desc.setWordWrap(True)
        desc.setStyleSheet("color: #7f8c8d; padding: 8px;")
        layout.addWidget(desc)

        layout.addStretch()
