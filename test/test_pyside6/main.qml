import QtQuick

Window {
    visible: true
    width: 393
    height: 852
    color: "#1a1a2e"

    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "PySide6 on iOS"
            font.pixelSize: 32
            font.bold: true
            color: "#e94560"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Qt " + Qt.version
            font.pixelSize: 22
            color: "#16213e"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Pure Python + PySide6 + QML"
            font.pixelSize: 16
            color: "#0f3460"
            font.italic: true
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 220
            height: 60
            radius: 12
            color: tapArea.pressed ? "#e94560" : "#0f3460"

            Text {
                anchors.centerIn: parent
                text: "Taps: " + counter.count
                font.pixelSize: 22
                color: "white"
            }

            TapHandler {
                id: tapArea
                onTapped: counter.count++
            }
        }
    }

    QtObject {
        id: counter
        property int count: 0
    }
}
