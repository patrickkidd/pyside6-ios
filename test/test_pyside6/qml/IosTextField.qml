import QtQuick

TextInput {
    property string placeholderText: ""

    height: 44
    font.pixelSize: 17
    color: root.textColor
    verticalAlignment: TextInput.AlignVCenter
    clip: true

    Text {
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        text: parent.placeholderText
        font.pixelSize: 17
        color: root.secondaryText
        visible: !parent.text && !parent.activeFocus
    }
}
