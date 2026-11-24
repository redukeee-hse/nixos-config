// Page title with an optional line under it.
import QtQuick
import "../"

Column {
    property string title: ""
    property string subtitle: ""
    width: parent ? parent.width : 400
    spacing: 4
    bottomPadding: 6

    Text {
        text: parent.title
        color: Theme.text
        font.family: Theme.uiFont
        font.pixelSize: 24
        font.weight: Font.DemiBold
    }
    Text {
        visible: text !== ""
        width: parent.width
        text: parent.subtitle
        color: Theme.textDim
        font.family: Theme.uiFont
        font.pixelSize: 13
        wrapMode: Text.Wrap
    }
}
