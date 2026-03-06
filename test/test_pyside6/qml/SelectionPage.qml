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
                title: "CHECK BOXES"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 0

                    CheckBox { text: "Option A"; checked: true; palette.highlight: root.accentColor }
                    CheckBox { text: "Option B"; palette.highlight: root.accentColor }
                    CheckBox { text: "Option C"; palette.highlight: root.accentColor }
                    CheckBox {
                        text: "Tri-state"
                        tristate: true
                        checkState: Qt.PartiallyChecked
                        palette.highlight: root.accentColor
                    }
                    CheckBox { text: "Disabled"; enabled: false }
                }
            }

            SectionCard {
                title: "RADIO BUTTONS"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 0

                    RadioButton { text: "Small"; checked: true; palette.highlight: root.accentColor }
                    RadioButton { text: "Medium"; palette.highlight: root.accentColor }
                    RadioButton { text: "Large"; palette.highlight: root.accentColor }
                    RadioButton { text: "Disabled"; enabled: false }
                }
            }

            SectionCard {
                title: "SWITCHES"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 0

                    IosSwitch { label: "Wi-Fi"; checked: true }
                    IosSeparator {}
                    IosSwitch { label: "Bluetooth" }
                    IosSeparator {}
                    IosSwitch { label: "Airplane Mode" }
                    IosSeparator {}
                    IosSwitch { label: "Disabled"; enabled: false }
                }
            }

            SectionCard {
                title: "SLIDERS"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 12

                    Text { text: "Continuous: " + Math.round(contSlider.value); font.pixelSize: 15; color: root.secondaryText }
                    Slider {
                        id: contSlider
                        from: 0; to: 100; value: 40
                        Layout.fillWidth: true
                        palette.highlight: root.accentColor
                    }

                    Text { text: "Stepped: " + Math.round(stepSlider.value); font.pixelSize: 15; color: root.secondaryText }
                    Slider {
                        id: stepSlider
                        from: 0; to: 100; value: 50
                        stepSize: 10
                        snapMode: Slider.SnapAlways
                        Layout.fillWidth: true
                        palette.highlight: root.accentColor
                    }

                    Text { text: "Range: " + Math.round(rangeSlider.first.value) + " - " + Math.round(rangeSlider.second.value); font.pixelSize: 15; color: root.secondaryText }
                    RangeSlider {
                        id: rangeSlider
                        from: 0; to: 100
                        first.value: 25
                        second.value: 75
                        Layout.fillWidth: true
                        palette.highlight: root.accentColor
                    }
                }
            }

            SectionCard {
                title: "DIALS"

                RowLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 20

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Volume"; font.pixelSize: 13; color: root.secondaryText; Layout.alignment: Qt.AlignHCenter }
                        Dial {
                            id: dial1
                            from: 0; to: 11; value: 5
                            Layout.preferredWidth: 90; Layout.preferredHeight: 90
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text { text: dial1.value.toFixed(1); font.pixelSize: 15; color: root.textColor; Layout.alignment: Qt.AlignHCenter }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Speed"; font.pixelSize: 13; color: root.secondaryText; Layout.alignment: Qt.AlignHCenter }
                        Dial {
                            id: dial2
                            from: 0; to: 200; value: 80
                            stepSize: 5; snapMode: Dial.SnapAlways
                            Layout.preferredWidth: 90; Layout.preferredHeight: 90
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text { text: Math.round(dial2.value) + " mph"; font.pixelSize: 15; color: root.textColor; Layout.alignment: Qt.AlignHCenter }
                    }
                }
            }
        }
    }
}
