import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: navPage

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        SectionCard {
            title: "STACK VIEW NAVIGATION"
            Layout.preferredHeight: 260

            ColumnLayout {
                anchors { left: parent.left; right: parent.right }
                spacing: 8

                StackView {
                    id: stack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 160
                    clip: true

                    initialItem: Component {
                        Rectangle {
                            color: root.cardColor
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "Root Page"; font.pixelSize: 17; font.weight: Font.DemiBold; color: root.textColor; Layout.alignment: Qt.AlignHCenter }
                                Text { text: "Depth: " + stack.depth; font.pixelSize: 15; color: root.secondaryText; Layout.alignment: Qt.AlignHCenter }
                                IosButton { text: "Push Page"; highlighted: true; onClicked: stack.push(subPage); Layout.preferredWidth: 160; Layout.alignment: Qt.AlignHCenter }
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 8
                    IosButton {
                        text: "Pop"
                        enabled: stack.depth > 1
                        Layout.fillWidth: true
                        onClicked: stack.pop()
                    }
                    Text { text: "Depth: " + stack.depth; font.pixelSize: 15; color: root.secondaryText }
                    IosButton {
                        text: "Push"
                        highlighted: true
                        Layout.fillWidth: true
                        onClicked: stack.push(subPage)
                    }
                }
            }
        }

        SectionCard {
            title: "DRAWERS"

            RowLayout {
                anchors { left: parent.left; right: parent.right }
                spacing: 8

                IosButton { text: "Left Drawer"; highlighted: true; Layout.fillWidth: true; onClicked: leftDrawer.open() }
                IosButton { text: "Right Drawer"; Layout.fillWidth: true; onClicked: rightDrawer.open() }
            }
        }

        SectionCard {
            title: "SWIPE VIEW"
            Layout.fillHeight: true

            ColumnLayout {
                anchors { left: parent.left; right: parent.right }
                spacing: 4

                SwipeView {
                    id: demoSwipe
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    clip: true

                    Repeater {
                        model: [
                            { name: "Red", hex: "#ff3b30" },
                            { name: "Green", hex: "#34c759" },
                            { name: "Blue", hex: "#007aff" },
                            { name: "Orange", hex: "#ff9500" }
                        ]
                        Rectangle {
                            color: modelData.hex
                            radius: 10
                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                color: "white"
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                PageIndicator {
                    count: demoSwipe.count
                    currentIndex: demoSwipe.currentIndex
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Component {
        id: subPage
        Rectangle {
            color: root.cardColor
            property int pageNum: stack.depth
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                Text { text: "Sub Page " + pageNum; font.pixelSize: 17; font.weight: Font.DemiBold; color: root.textColor; Layout.alignment: Qt.AlignHCenter }
                Text { text: "Depth: " + stack.depth; font.pixelSize: 15; color: root.secondaryText; Layout.alignment: Qt.AlignHCenter }
                IosButton { text: "Push Another"; highlighted: true; onClicked: stack.push(subPage); Layout.preferredWidth: 160; Layout.alignment: Qt.AlignHCenter }
            }
        }
    }

    Drawer {
        id: leftDrawer
        width: navPage.width * 0.75
        height: navPage.height
        edge: Qt.LeftEdge

        Rectangle {
            anchors.fill: parent
            color: root.cardColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                anchors.topMargin: 40
                spacing: 0

                Text { text: "Menu"; font.pixelSize: 28; font.weight: Font.Bold; color: root.textColor }
                Item { Layout.preferredHeight: 16 }

                Repeater {
                    model: ["Home", "Settings", "Profile", "About"]
                    Item {
                        Layout.fillWidth: true
                        height: 48
                        Text {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            text: modelData
                            font.pixelSize: 17
                            color: root.accentColor
                        }
                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: 0.5; color: root.separatorColor
                        }
                        TapHandler { onTapped: leftDrawer.close() }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }

    Drawer {
        id: rightDrawer
        width: navPage.width * 0.65
        height: navPage.height
        edge: Qt.RightEdge

        Rectangle {
            anchors.fill: parent
            color: root.cardColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                anchors.topMargin: 40
                spacing: 0

                Text { text: "Notifications"; font.pixelSize: 22; font.weight: Font.Bold; color: root.textColor }
                Item { Layout.preferredHeight: 16 }

                Repeater {
                    model: 5
                    Item {
                        Layout.fillWidth: true
                        height: 48
                        Text {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            text: "Notification " + (index + 1)
                            font.pixelSize: 15
                            color: root.textColor
                        }
                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: 0.5; color: root.separatorColor
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
