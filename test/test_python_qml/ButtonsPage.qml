import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: page
    contentWidth: availableWidth

    Flickable {
        contentHeight: col.implicitHeight + 20
        bottomMargin: 20

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 24

            SectionCard {
                title: "Standard Buttons"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 10

                    IosButton { text: "Default Button" }
                    IosButton { text: "Highlighted"; highlighted: true }
                    IosButton { text: "Destructive"; color: root.destructiveColor }
                    IosButton { text: "Disabled"; enabled: false }
                    IosButton {
                        text: "Checkable: " + (checked ? "ON" : "OFF")
                        checkable: true
                    }
                }
            }

            SectionCard {
                title: "Round Buttons"

                RowLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 12

                    Repeater {
                        model: ["+", "-", "?", "!"]
                        RoundButton {
                            text: modelData
                            width: 48; height: 48
                            radius: 24
                            font.pixelSize: 20
                            palette.button: root.accentColor
                            palette.buttonText: "white"
                        }
                    }
                }
            }

            SectionCard {
                title: "Delay Button"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 8

                    DelayButton {
                        text: "Hold to confirm"
                        delay: 2000
                        Layout.fillWidth: true
                        palette.button: root.accentColor
                        palette.buttonText: "white"
                    }

                    Text {
                        text: "Press and hold for 2 seconds"
                        font.pixelSize: 13
                        color: root.secondaryText
                    }
                }
            }

            SectionCard {
                title: "Tool Buttons"

                RowLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 0

                    Repeater {
                        model: ["Cut", "Copy", "Paste"]
                        ToolButton {
                            text: modelData
                            font.pixelSize: 15
                            palette.buttonText: root.accentColor
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
