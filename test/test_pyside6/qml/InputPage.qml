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
                title: "TEXT FIELDS"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 0

                    IosTextField { placeholderText: "Enter text..." }
                    IosSeparator {}
                    IosTextField { placeholderText: "Password"; echoMode: TextInput.Password }
                    IosSeparator {}
                    IosTextField { text: "Read-only text"; readOnly: true }
                    IosSeparator {}
                    IosTextField {
                        placeholderText: "Numbers only"
                        validator: IntValidator { bottom: 0; top: 999 }
                        inputMethodHints: Qt.ImhDigitsOnly
                    }
                }
            }

            SectionCard {
                title: "TEXT AREA"

                TextArea {
                    anchors { left: parent.left; right: parent.right }
                    placeholderText: "Multi-line text area...\nType here."
                    wrapMode: TextEdit.Wrap
                    font.pixelSize: 17
                    color: root.textColor
                    implicitHeight: 100
                    background: null
                }
            }

            SectionCard {
                title: "SPIN BOX"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 12

                    RowLayout {
                        Text { text: "Quantity:"; font.pixelSize: 17; color: root.textColor }
                        Item { Layout.fillWidth: true }
                        SpinBox {
                            from: 0; to: 100; value: 5
                            editable: true
                        }
                    }
                    RowLayout {
                        Text { text: "Step by 10:"; font.pixelSize: 17; color: root.textColor }
                        Item { Layout.fillWidth: true }
                        SpinBox {
                            from: 0; to: 1000; value: 50
                            stepSize: 10
                        }
                    }
                }
            }

            SectionCard {
                title: "COMBO BOX"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 12

                    Text { text: "Select a fruit:"; font.pixelSize: 17; color: root.textColor }
                    ComboBox {
                        model: ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"]
                        Layout.fillWidth: true
                    }

                    Text { text: "Editable combo:"; font.pixelSize: 17; color: root.textColor }
                    ComboBox {
                        editable: true
                        model: ListModel {
                            ListElement { text: "Custom 1" }
                            ListElement { text: "Custom 2" }
                            ListElement { text: "Custom 3" }
                        }
                        Layout.fillWidth: true
                    }
                }
            }

            SectionCard {
                title: "TUMBLER"

                RowLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 4
                    Layout.preferredHeight: 120

                    Tumbler {
                        model: 24
                        Layout.fillWidth: true
                        visibleItemCount: 3
                    }
                    Text { text: ":"; font.pixelSize: 24; font.bold: true; color: root.textColor }
                    Tumbler {
                        model: 60
                        Layout.fillWidth: true
                        visibleItemCount: 3
                    }
                    Text { text: ":"; font.pixelSize: 24; font.bold: true; color: root.textColor }
                    Tumbler {
                        model: 60
                        Layout.fillWidth: true
                        visibleItemCount: 3
                    }
                }
            }
        }
    }
}
