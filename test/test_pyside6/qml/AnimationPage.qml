import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

ScrollView {
    id: animPage
    contentWidth: availableWidth

    Flickable {
        contentHeight: col.implicitHeight + 20
        bottomMargin: 20

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 24

            SectionCard {
                title: "PROPERTY ANIMATION"
                Layout.preferredHeight: 190

                Rectangle {
                    anchors { left: parent.left; right: parent.right }
                    height: 120
                    color: "#f2f2f7"
                    radius: 10

                    Rectangle {
                        id: animRect
                        width: 50; height: 50
                        radius: 25
                        color: root.destructiveColor
                        y: (parent.height - height) / 2

                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            NumberAnimation {
                                to: animRect.parent ? animRect.parent.width - animRect.width : 200
                                duration: 2000; easing.type: Easing.InOutQuad
                            }
                            NumberAnimation { to: 0; duration: 2000; easing.type: Easing.InOutQuad }
                        }

                        SequentialAnimation on color {
                            loops: Animation.Infinite
                            ColorAnimation { to: root.accentColor; duration: 2000 }
                            ColorAnimation { to: root.greenColor; duration: 2000 }
                            ColorAnimation { to: root.destructiveColor; duration: 2000 }
                        }
                    }
                }
            }

            SectionCard {
                title: "ROTATION & SCALE"
                Layout.preferredHeight: 190

                Rectangle {
                    anchors { left: parent.left; right: parent.right }
                    height: 120
                    color: "#f2f2f7"
                    radius: 10

                    Rectangle {
                        id: rotRect
                        width: 60; height: 60
                        anchors.centerIn: parent
                        color: "#af52de"
                        radius: 8

                        RotationAnimation on rotation {
                            loops: Animation.Infinite
                            from: 0; to: 360; duration: 3000
                        }

                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.5; duration: 1500; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.5; duration: 1500; easing.type: Easing.InOutSine }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Qt"
                            color: "white"
                            font.weight: Font.Bold
                            font.pixelSize: 20
                        }
                    }
                }
            }

            SectionCard {
                title: "EASING CURVES"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 8

                    Repeater {
                        model: [
                            { name: "Linear", type: Easing.Linear },
                            { name: "InOutQuad", type: Easing.InOutQuad },
                            { name: "OutBounce", type: Easing.OutBounce },
                            { name: "InOutElastic", type: Easing.InOutElastic },
                            { name: "OutBack", type: Easing.OutBack }
                        ]

                        RowLayout {
                            required property var modelData
                            property int easingType: modelData.type
                            spacing: 8
                            Layout.fillWidth: true

                            Text {
                                text: parent.modelData.name
                                Layout.preferredWidth: 100
                                font.pixelSize: 12
                                color: root.secondaryText
                            }

                            Rectangle {
                                id: track
                                Layout.fillWidth: true
                                height: 24
                                color: "#f2f2f7"
                                radius: 12

                                property int easingType: parent.easingType

                                Rectangle {
                                    width: 20; height: 20
                                    radius: 10
                                    color: root.accentColor
                                    y: 2

                                    SequentialAnimation on x {
                                        loops: Animation.Infinite
                                        NumberAnimation {
                                            to: track.width - 20
                                            duration: 2000
                                            easing.type: track.easingType
                                        }
                                        PauseAnimation { duration: 500 }
                                        NumberAnimation {
                                            to: 0
                                            duration: 2000
                                            easing.type: track.easingType
                                        }
                                        PauseAnimation { duration: 500 }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            SectionCard {
                title: "SHAPES"
                Layout.preferredHeight: 230

                Rectangle {
                    anchors { left: parent.left; right: parent.right }
                    height: 170
                    color: "#f2f2f7"
                    radius: 10
                    clip: true

                    Shape {
                        anchors.fill: parent

                        ShapePath {
                            strokeColor: root.accentColor
                            strokeWidth: 3
                            fillColor: Qt.rgba(0, 0.48, 1.0, 0.15)

                            startX: 0; startY: 100
                            PathQuad { x: 100; y: 20; controlX: 50; controlY: -30 }
                            PathQuad { x: 200; y: 100; controlX: 150; controlY: 20 }
                            PathLine { x: 200; y: 160 }
                            PathLine { x: 0; y: 160 }
                            PathLine { x: 0; y: 100 }
                        }

                        ShapePath {
                            strokeColor: root.destructiveColor
                            strokeWidth: 2
                            fillColor: "transparent"

                            startX: 20; startY: 140
                            PathCubic {
                                x: 280; y: 140
                                control1X: 80; control1Y: 40
                                control2X: 220; control2Y: 40
                            }
                        }
                    }

                    Shape {
                        y: 20; width: 30; height: 30

                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            NumberAnimation { from: 220; to: 300; duration: 1500; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 300; to: 220; duration: 1500; easing.type: Easing.InOutSine }
                        }

                        ShapePath {
                            strokeColor: root.greenColor
                            strokeWidth: 2
                            fillColor: root.greenColor
                            PathAngleArc { centerX: 15; centerY: 15; radiusX: 12; radiusY: 12; startAngle: 0; sweepAngle: 360 }
                        }
                    }
                }
            }

            SectionCard {
                title: "TOUCH INTERACTION"
                Layout.preferredHeight: 230

                Rectangle {
                    anchors { left: parent.left; right: parent.right }
                    height: 170
                    color: "#f2f2f7"
                    radius: 10
                    clip: true

                    Text {
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 8 }
                        text: "Drag the circles"
                        font.pixelSize: 13
                        color: root.secondaryText
                    }

                    Repeater {
                        model: ["#ff3b30", "#007aff", "#34c759", "#ff9500", "#af52de"]

                        Rectangle {
                            x: index * 55 + 20
                            y: 60
                            width: 44; height: 44
                            radius: 22
                            color: modelData
                            opacity: dragArea.active ? 0.8 : 1.0
                            scale: dragArea.active ? 1.2 : 1.0

                            Behavior on scale { NumberAnimation { duration: 150 } }

                            DragHandler { id: dragArea }

                            Text {
                                anchors.centerIn: parent
                                text: index + 1
                                color: "white"
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }

            SectionCard {
                title: "SYSTEM INFO"

                ColumnLayout {
                    anchors { left: parent.left; right: parent.right }
                    spacing: 4

                    Text { text: "Qt Version: " + Qt.version; font.pixelSize: 15; color: root.textColor }
                    Text { text: "Python: " + (pythonVersion || "N/A"); font.pixelSize: 15; color: root.textColor }
                    Text { text: "Platform: " + Qt.platform.os; font.pixelSize: 15; color: root.textColor }
                    Text {
                        text: appMessage || ""
                        font.pixelSize: 15; font.italic: true
                        color: root.accentColor
                        visible: appMessage ? true : false
                    }
                }
            }
        }
    }
}
