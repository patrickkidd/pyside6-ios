import QtQuick
import QtQuick.Layouts

Item {
    id: card
    property string title: ""
    default property alias content: contentArea.data

    Layout.fillWidth: true
    Layout.margins: 16
    implicitHeight: cardCol.implicitHeight

    Column {
        id: cardCol
        anchors { left: parent.left; right: parent.right }
        spacing: 6

        Text {
            text: card.title
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: root.secondaryText
            leftPadding: 4
            visible: card.title !== ""
            textFormat: Text.PlainText
        }

        Rectangle {
            width: cardCol.width
            implicitHeight: contentArea.implicitHeight + 24
            radius: 10
            color: root.cardColor

            Item {
                id: contentArea
                anchors {
                    left: parent.left; right: parent.right
                    top: parent.top
                    margins: 12
                }
                implicitHeight: childrenRect.height
            }
        }
    }
}
