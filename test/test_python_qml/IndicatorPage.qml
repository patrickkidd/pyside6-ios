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
                title: "PROGRESS BARS"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 12

                    Text { text: "Determinate: " + Math.round(progressAnim.value * 100) + "%"; font.pixelSize: 15; color: root.secondaryText }
                    ProgressBar {
                        id: progressAnim
                        Layout.fillWidth: true
                        palette.highlight: root.accentColor
                        NumberAnimation on value {
                            from: 0; to: 1; duration: 5000; loops: Animation.Infinite
                        }
                    }

                    Text { text: "Indeterminate:"; font.pixelSize: 15; color: root.secondaryText }
                    ProgressBar {
                        indeterminate: true
                        Layout.fillWidth: true
                        palette.highlight: root.accentColor
                    }

                    Text { text: "Static (60%):"; font.pixelSize: 15; color: root.secondaryText }
                    ProgressBar {
                        value: 0.6
                        Layout.fillWidth: true
                        palette.highlight: root.accentColor
                    }
                }
            }

            SectionCard {
                title: "BUSY INDICATOR"

                RowLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 20

                    ColumnLayout {
                        Layout.fillWidth: true
                        BusyIndicator { running: true; Layout.alignment: Qt.AlignHCenter; palette.dark: root.accentColor }
                        Text { text: "Loading..."; font.pixelSize: 13; color: root.secondaryText; Layout.alignment: Qt.AlignHCenter }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        BusyIndicator {
                            running: true
                            Layout.preferredWidth: 48; Layout.preferredHeight: 48
                            Layout.alignment: Qt.AlignHCenter
                            palette.dark: root.accentColor
                        }
                        Text { text: "Large"; font.pixelSize: 13; color: root.secondaryText; Layout.alignment: Qt.AlignHCenter }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        BusyIndicator { running: false; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "Stopped"; font.pixelSize: 13; color: root.secondaryText; Layout.alignment: Qt.AlignHCenter }
                    }
                }
            }

            SectionCard {
                title: "PAGE INDICATOR"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        color: "#f2f2f7"
                        radius: 8

                        SwipeView {
                            id: miniSwipe
                            anchors.fill: parent
                            Repeater {
                                model: 5
                                Item {
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Page " + (index + 1)
                                        font.pixelSize: 18
                                        color: root.textColor
                                    }
                                }
                            }
                        }
                    }

                    PageIndicator {
                        count: miniSwipe.count
                        currentIndex: miniSwipe.currentIndex
                        interactive: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            SectionCard {
                title: "SCROLL LIST"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 8

                    Text { text: "Scroll the list below:"; font.pixelSize: 15; color: root.secondaryText }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        color: "#f2f2f7"
                        radius: 8
                        clip: true

                        ListView {
                            id: scrollList
                            anchors.fill: parent
                            model: 30
                            delegate: Item {
                                width: scrollList.width
                                height: 36
                                Text {
                                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                    text: "Scrollable item " + (index + 1)
                                    font.pixelSize: 15
                                    color: root.textColor
                                }
                                Rectangle {
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 12 }
                                    height: 0.5
                                    color: root.separatorColor
                                    visible: index < 29
                                }
                            }

                            ScrollIndicator.vertical: ScrollIndicator {}
                        }
                    }
                }
            }

            SectionCard {
                title: "TOOLTIPS"

                RowLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 12

                    Button {
                        text: "Tap me"
                        palette.button: root.accentColor
                        palette.buttonText: "white"
                        ToolTip.visible: pressed
                        ToolTip.text: "I am a tooltip!"
                    }

                    Button {
                        text: "Delayed tip"
                        palette.button: root.accentColor
                        palette.buttonText: "white"
                        ToolTip.visible: pressed
                        ToolTip.delay: 500
                        ToolTip.text: "Appeared after delay"
                    }
                }
            }
        }
    }
}
