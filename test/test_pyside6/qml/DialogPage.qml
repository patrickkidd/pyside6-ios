import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: dialogPage
    contentWidth: availableWidth

    Flickable {
        contentHeight: col.implicitHeight + 20
        bottomMargin: 20

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 24

            SectionCard {
                title: "STANDARD DIALOGS"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 10

                    IosButton { text: "Simple Dialog"; highlighted: true; onClicked: simpleDialog.open() }
                    IosButton { text: "Confirmation Dialog"; onClicked: confirmDialog.open() }
                    IosButton { text: "Input Dialog"; onClicked: inputDialog.open() }
                    IosButton { text: "Scrollable Dialog"; onClicked: scrollDialog.open() }

                    Text {
                        id: dialogResult
                        text: "Dialog result appears here"
                        font.pixelSize: 15
                        font.italic: true
                        color: root.secondaryText
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            SectionCard {
                title: "POPUPS & MENUS"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 10

                    IosButton { text: "Show Popup"; highlighted: true; onClicked: popup.open() }
                    IosButton { text: "Show Menu"; onClicked: contextMenu.popup() }
                }
            }

            SectionCard {
                title: "FRAMES & PANES"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: frameCol.implicitHeight + 24
                        radius: 8
                        color: "#f2f2f7"

                        ColumnLayout {
                            id: frameCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            Text { text: "This is a Frame"; font.pixelSize: 17; font.weight: Font.DemiBold; color: root.textColor }
                            Text { text: "Frames provide a visual border"; font.pixelSize: 15; color: root.secondaryText }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: paneCol.implicitHeight + 24
                        radius: 8
                        color: root.accentColor
                        opacity: 0.1

                        ColumnLayout {
                            id: paneCol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            Text { text: "This is a Pane"; font.pixelSize: 17; font.weight: Font.DemiBold; color: root.textColor }
                            Text { text: "Panes provide padding and background"; font.pixelSize: 15; color: root.secondaryText }
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: simpleDialog
        title: "Information"
        standardButtons: Dialog.Ok
        anchors.centerIn: Overlay.overlay
        width: dialogPage.width * 0.8

        Label {
            text: "PySide6 on iOS via QtRuntime.framework.\nQt " + Qt.version + "\nPython " + (pythonVersion || "N/A")
            wrapMode: Text.Wrap
            width: simpleDialog.availableWidth
        }

        onAccepted: dialogResult.text = "Simple dialog closed"
    }

    Dialog {
        id: confirmDialog
        title: "Confirm Action"
        standardButtons: Dialog.Yes | Dialog.No
        anchors.centerIn: Overlay.overlay
        width: dialogPage.width * 0.8

        Label {
            text: "Are you sure you want to proceed?"
            wrapMode: Text.Wrap
            width: confirmDialog.availableWidth
        }

        onAccepted: dialogResult.text = "Confirmed: Yes"
        onRejected: dialogResult.text = "Confirmed: No"
    }

    Dialog {
        id: inputDialog
        title: "Enter Name"
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: Overlay.overlay
        width: dialogPage.width * 0.8

        TextField {
            id: inputField
            placeholderText: "Your name..."
            width: inputDialog.availableWidth
        }

        onAccepted: dialogResult.text = "Hello, " + (inputField.text || "stranger") + "!"
        onRejected: dialogResult.text = "Input cancelled"
    }

    Dialog {
        id: scrollDialog
        title: "Terms & Conditions"
        standardButtons: Dialog.Ok
        anchors.centerIn: Overlay.overlay
        width: dialogPage.width * 0.8
        height: 300

        ScrollView {
            anchors.fill: parent

            Label {
                width: scrollDialog.availableWidth
                text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ".repeat(20)
                wrapMode: Text.Wrap
            }
        }
    }

    Popup {
        id: popup
        anchors.centerIn: Overlay.overlay
        width: 240
        height: 140
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 14
            color: root.cardColor
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8
            Text { text: "I'm a popup!"; font.pixelSize: 17; font.weight: Font.DemiBold; color: root.textColor; Layout.alignment: Qt.AlignHCenter }
            Text { text: "Tap outside to close"; font.pixelSize: 15; color: root.secondaryText; Layout.alignment: Qt.AlignHCenter }
        }
    }

    Menu {
        id: contextMenu
        MenuItem { text: "Cut"; onTriggered: dialogResult.text = "Cut selected" }
        MenuItem { text: "Copy"; onTriggered: dialogResult.text = "Copy selected" }
        MenuItem { text: "Paste"; onTriggered: dialogResult.text = "Paste selected" }
        MenuSeparator {}
        MenuItem { text: "Select All"; onTriggered: dialogResult.text = "Select All" }
    }
}
