import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    contentWidth: availableWidth

    Flickable {
        contentHeight: col.implicitHeight + 20
        bottomMargin: 20

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 24

            SectionCard {
                title: "PYSIDE6 ON IOS"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 8

                    Text { text: "Qt " + Qt.version; font.pixelSize: 20; color: root.textColor }
                    Text { text: "Python: " + (appInfo.python || "?"); font.pixelSize: 15; color: root.textColor }
                    Text { text: "Platform: " + (appInfo.platform || "?"); font.pixelSize: 15; color: root.textColor }
                    Text { text: "Build: " + (appInfo.buildUuid || "?"); font.pixelSize: 15; color: root.secondaryText }
                    Text { text: "Date: " + (appInfo.buildDate || "?"); font.pixelSize: 15; color: root.secondaryText }
                }
            }

            SectionCard {
                title: "C++ BINDING OVERRIDE"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 8

                    Text { text: "Device: " + (appState ? appState.deviceModel : "?"); font.pixelSize: 15; color: root.textColor }
                    Text { text: "Display: " + (appState ? appState.displayName : "?"); font.pixelSize: 15; color: root.accentColor; font.weight: Font.DemiBold }

                    IosSeparator {}

                    Text {
                        text: "The displayName property is a C++ virtual\noverridden in Python via shiboken6 bindings."
                        font.pixelSize: 13
                        color: root.secondaryText
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            SectionCard {
                title: "TAP COUNTER"

                Rectangle {
                    anchors { left: parent.left; right: parent.right }
                    height: 60
                    radius: 10
                    color: tapArea.pressed ? root.accentColor : "#0f3460"

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

                    QtObject {
                        id: counter
                        property int count: 0
                    }
                }
            }
        }
    }
}
