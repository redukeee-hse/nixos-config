// One Hub setting: a label with a hint on the left and a segmented choice on
// the right. Used by the Appearance, Power and Apps pages.
import QtQuick
import "../"

Item {
    id: row

    property string label: ""
    property string hint: ""
    property var options: []        // [{ value, text }]
    property string current: ""
    signal picked(string value)

    width: parent ? parent.width : 400
    height: Math.max(56, texts.implicitHeight + 20)

    Column {
        id: texts
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - choices.width - 20
        spacing: 3
        Text {
            text: row.label
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }
        Text {
            visible: row.hint !== ""
            width: parent.width
            text: row.hint
            color: Theme.textFaint
            font.family: Theme.fontFamily
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
    }

    Row {
        id: choices
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Repeater {
            model: row.options
            Rectangle {
                required property var modelData
                readonly property bool on: row.current === modelData.value
                height: 30
                width: lbl.implicitWidth + 24
                radius: Theme.radius
                color: on ? Theme.alpha(Theme.accent, 0.22) : (ma.containsMouse ? Theme.alpha(Theme.text, 0.08) : Theme.alpha(Theme.text, 0.04))
                border.width: on ? 1 : 0
                border.color: Theme.accent
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Text {
                    id: lbl
                    anchors.centerIn: parent
                    text: parent.modelData.text
                    color: parent.on ? Theme.text : Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: row.picked(parent.modelData.value)
                }
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.alpha(Theme.text, 0.06)
    }
}
