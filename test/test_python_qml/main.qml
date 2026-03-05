import QtQuick

Rectangle {
    anchors.fill: parent
    color: "#1a1a2e"

    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Python + Qt on iOS"
            font.pixelSize: 28
            font.bold: true
            color: "#e94560"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Python " + (pythonVersion || "?")
            font.pixelSize: 20
            color: "#0f3460"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Qt " + Qt.version
            font.pixelSize: 20
            color: "#0f3460"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: appMessage || ""
            font.pixelSize: 16
            color: "#e94560"
            font.italic: true
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 200
            height: 60
            radius: 12
            color: tapArea.pressed ? "#e94560" : "#0f3460"

            Text {
                anchors.centerIn: parent
                text: "Taps: " + counter.count
                font.pixelSize: 20
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
