import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        SectionCard {
            title: "SETTINGS-STYLE LIST"
            Layout.preferredHeight: 240

            ListView {
                anchors { left: parent.left; right: parent.right }
                height: 200
                clip: true
                model: ListModel {
                    ListElement { name: "Wi-Fi"; desc: "Connected to HomeNetwork" }
                    ListElement { name: "Bluetooth"; desc: "2 devices connected" }
                    ListElement { name: "Cellular"; desc: "5G" }
                    ListElement { name: "VPN"; desc: "Not connected" }
                    ListElement { name: "Hotspot"; desc: "Off" }
                    ListElement { name: "Notifications"; desc: "Banners, Sounds" }
                    ListElement { name: "Focus"; desc: "Do Not Disturb" }
                    ListElement { name: "Screen Time"; desc: "4h 23m today" }
                }
                delegate: Item {
                    width: parent ? parent.width : 0
                    height: 52

                    RowLayout {
                        anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                        spacing: 8

                        ColumnLayout {
                            spacing: 2
                            Text { text: model.name; font.pixelSize: 17; color: root.textColor }
                            Text { text: model.desc; font.pixelSize: 13; color: root.secondaryText }
                        }

                        Item { Layout.fillWidth: true }

                        Text { text: ">"; font.pixelSize: 17; color: root.separatorColor }
                    }

                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 4 }
                        height: 0.5; color: root.separatorColor
                    }
                }

                ScrollIndicator.vertical: ScrollIndicator {}
            }
        }

        SectionCard {
            title: "SWIPE TO ACT"
            Layout.fillHeight: true

            ListView {
                id: swipeList
                anchors { left: parent.left; right: parent.right }
                height: 200
                clip: true
                model: ListModel {
                    ListElement { title: "Meeting with team" }
                    ListElement { title: "Review pull request" }
                    ListElement { title: "Update documentation" }
                    ListElement { title: "Fix CI pipeline" }
                    ListElement { title: "Deploy to staging" }
                    ListElement { title: "Write unit tests" }
                    ListElement { title: "Code review session" }
                }

                delegate: SwipeDelegate {
                    width: swipeList.width
                    text: model.title
                    font.pixelSize: 17

                    swipe.right: Rectangle {
                        width: parent.width; height: parent.height
                        color: root.destructiveColor
                        Text { anchors.centerIn: parent; text: "Delete"; color: "white"; font.weight: Font.DemiBold }
                    }

                    swipe.left: Rectangle {
                        width: parent.width; height: parent.height
                        color: root.greenColor
                        Text { anchors.centerIn: parent; text: "Done"; color: "white"; font.weight: Font.DemiBold }
                    }
                }

                ScrollIndicator.vertical: ScrollIndicator {}
            }
        }

        SectionCard {
            title: "SWITCH DELEGATES"
            Layout.preferredHeight: 200

            ListView {
                anchors { left: parent.left; right: parent.right }
                height: 160
                clip: true
                model: ListModel {
                    ListElement { label: "Push Notifications"; on: true }
                    ListElement { label: "Email Alerts"; on: false }
                    ListElement { label: "Sound Effects"; on: true }
                    ListElement { label: "Haptic Feedback"; on: true }
                    ListElement { label: "Auto-Update"; on: false }
                }

                delegate: Item {
                    width: parent ? parent.width : 0
                    height: 44

                    IosSwitch {
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        label: model.label
                        checked: model.on
                    }

                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: 0.5; color: root.separatorColor
                    }
                }

                ScrollIndicator.vertical: ScrollIndicator {}
            }
        }
    }
}
