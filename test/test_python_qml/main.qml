import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    anchors.fill: parent
    color: "#f2f2f7"

    property real safeTop: 60
    property real safeBottom: 34
    property color accentColor: "#007aff"
    property color cardColor: "#ffffff"
    property color textColor: "#000000"
    property color secondaryText: "#8e8e93"
    property color separatorColor: "#c6c6c8"
    property color destructiveColor: "#ff3b30"
    property color greenColor: "#34c759"

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: root.safeTop
        anchors.bottomMargin: root.safeBottom
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: root.cardColor

            Label {
                anchors.centerIn: parent
                text: tabBar.currentIndex >= 0 ? pageModel.get(tabBar.currentIndex).title : ""
                font.pixelSize: 17
                font.weight: Font.DemiBold
                color: root.textColor
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 0.5
                color: root.separatorColor
            }
        }

        // Pages
        SwipeView {
            id: swipeView
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            ButtonsPage {}
            InputPage {}
            SelectionPage {}
            IndicatorPage {}
            NavigationPage {}
            DialogPage {}
            ListPage {}
            AnimationPage {}
        }

        // Tab bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: root.cardColor

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 0.5
                color: root.separatorColor
            }

            RowLayout {
                anchors.fill: parent
                anchors.topMargin: 2
                spacing: 0

                Repeater {
                    model: pageModel

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        property bool active: tabBar.currentIndex === index

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Rectangle {
                                width: 6; height: 6
                                radius: 3
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: active ? root.accentColor : "transparent"
                            }

                            Text {
                                text: model.label
                                font.pixelSize: 10
                                font.weight: active ? Font.DemiBold : Font.Normal
                                color: active ? root.accentColor : root.secondaryText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        TapHandler {
                            onTapped: tabBar.currentIndex = index
                        }
                    }
                }
            }
        }
    }

    // Hidden TabBar to sync with SwipeView
    TabBar {
        id: tabBar
        visible: false
        currentIndex: swipeView.currentIndex

        Repeater {
            model: pageModel
            TabButton { text: model.label }
        }
    }

    ListModel {
        id: pageModel
        ListElement { title: "Buttons & Actions"; label: "Buttons" }
        ListElement { title: "Text Input"; label: "Input" }
        ListElement { title: "Selection Controls"; label: "Select" }
        ListElement { title: "Progress & Indicators"; label: "Status" }
        ListElement { title: "Navigation"; label: "Nav" }
        ListElement { title: "Dialogs & Popups"; label: "Dialogs" }
        ListElement { title: "Lists & Delegates"; label: "Lists" }
        ListElement { title: "Animation & Graphics"; label: "Anim" }
    }
}
