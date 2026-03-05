import QtQuick

Rectangle {
    anchors.fill: parent
    color: "red"

    Column {
        anchors.centerIn: parent
        spacing: 20

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "QtRuntime.framework"
            font.pixelSize: 28
            font.bold: true
            color: "white"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Qt " + Qt.version + " on iOS"
            font.pixelSize: 18
            color: "#eee"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "QML rendering works!"
            font.pixelSize: 16
            color: "yellow"
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 200
            height: 60
            radius: 12
            color: tapArea.pressed ? "#333" : "#555"

            Text {
                anchors.centerIn: parent
                text: "Tap Me"
                font.pixelSize: 20
                color: "white"
            }

            TapHandler {
                id: tapArea
                onTapped: counter.count++
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Taps: " + counter.count
            font.pixelSize: 22
            color: "yellow"
        }
    }

    QtObject {
        id: counter
        property int count: 0
    }
}
