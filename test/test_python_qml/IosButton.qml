import QtQuick
import QtQuick.Layouts

Item {
    id: btn
    property string text: ""
    property bool highlighted: false
    property bool checkable: false
    property bool checked: false
    property bool enabled: true
    property color color: root.accentColor
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 44
    opacity: btn.enabled ? 1.0 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: {
            if (!btn.enabled) return "#e5e5ea"
            if (btn.highlighted) return btn.color
            if (btn.checkable && btn.checked) return btn.color
            return "#e5e5ea"
        }

        Text {
            anchors.centerIn: parent
            text: btn.text
            font.pixelSize: 17
            font.weight: Font.Medium
            color: {
                if (btn.highlighted || (btn.checkable && btn.checked))
                    return "white"
                return btn.color
            }
        }

        TapHandler {
            enabled: btn.enabled
            onTapped: {
                if (btn.checkable) btn.checked = !btn.checked
                btn.clicked()
            }
        }
    }
}
