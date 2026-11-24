// One Hub setting: a card with a label and hint on the left and a segmented
// choice on the right; the chosen segment is filled with the accent. Used by
// the Appearance and Power pages.
import QtQuick
import "../"

Rectangle {
    id: row

    property string label: ""
    property string hint: ""
    property var options: []        // [{ value, text }]
    property string current: ""
    signal picked(string value)

    width: parent ? parent.width : 400
    height: Math.max(68, texts.implicitHeight + 28)
    radius: 16
    color: Theme.surfaceCard
    border.width: 1
    border.color: Theme.outline

    Column {
        id: texts
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - choices.width - 54
        spacing: 3
        Text {
            text: row.label
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Text {
            visible: row.hint !== ""
            width: parent.width
            text: row.hint
            color: Theme.textDim
            font.family: Theme.uiFont
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
    }

    Rectangle {
        id: choices
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: seg.implicitWidth + 8
        height: 38
        radius: height / 2
        color: Theme.alpha(Theme.text, 0.07)

        Row {
            id: seg
            anchors.centerIn: parent
            spacing: 2
            Repeater {
                model: row.options
                Rectangle {
                    required property var modelData
                    readonly property bool on: row.current === modelData.value
                    height: 30
                    width: lbl.implicitWidth + 28
                    radius: height / 2
                    color: on ? Theme.accent : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animMed } }
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: parent.on ? Theme.onAccent : Theme.text
                        opacity: ma.pressed ? 0.16 : ma.containsMouse ? 0.08 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    }
                    Text {
                        id: lbl
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        color: parent.on ? Theme.onAccent : Theme.textDim
                        font.family: Theme.uiFont
                        font.pixelSize: 13
                        font.weight: parent.on ? Font.DemiBold : Font.Medium
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.picked(parent.modelData.value)
                    }
                }
            }
        }
    }
}
