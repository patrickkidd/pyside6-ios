import QtQuick
import QtQuick.Layouts

Item {
    id: sw
    property string label: ""
    property bool checked: false
    property bool enabled: true

    Layout.fillWidth: true
    implicitHeight: 44
    opacity: sw.enabled ? 1.0 : 0.4

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            text: sw.label
            font.pixelSize: 17
            color: root.textColor
            Layout.fillWidth: true
        }

        Rectangle {
            width: 51; height: 31
            radius: 15.5
            color: sw.checked ? root.greenColor : "#e5e5ea"

            Behavior on color { ColorAnimation { duration: 200 } }

            Rectangle {
                x: sw.checked ? parent.width - width - 2 : 2
                y: 2
                width: 27; height: 27
                radius: 13.5
                color: "white"

                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
            }

            TapHandler {
                enabled: sw.enabled
                onTapped: sw.checked = !sw.checked
            }
        }
    }
}
