import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 393
    height: 852
    color: "#f2f2f7"

    property color accentColor: "#007aff"
    property color cardColor: "#ffffff"
    property color textColor: "#000000"
    property color secondaryText: "#8e8e93"
    property color separatorColor: "#c6c6c8"
    property color destructiveColor: "#ff3b30"
    property color greenColor: "#34c759"

    header: ToolBar {
        background: Rectangle { color: root.cardColor }

        Label {
            anchors.centerIn: parent
            text: tabBar.currentIndex >= 0 ? pageModel.get(tabBar.currentIndex).title : ""
            font.pixelSize: 17
            font.weight: Font.DemiBold
            color: root.textColor
        }
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        ButtonsPage {}
        InputPage {}
        SelectionPage {}
        IndicatorPage {}
        NavigationPage {}
        DialogPage {}
        ListPage {}
        AnimationPage {}
        InfoPage {}
    }

    footer: Rectangle {
        height: 50
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
        ListElement { title: "App Info & Bindings"; label: "Info" }
    }
}
