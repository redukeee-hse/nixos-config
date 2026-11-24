// A card with an icon, a title, a line of detail and a switch on the right.
// The whole card is clickable, like a quick-settings tile.
import QtQuick
import "../"

Rectangle {
    id: row

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    signal toggled(bool on)

    width: parent ? parent.width : 400
    height: 64
    radius: 16
    color: checked ? Theme.alpha(Theme.accent, 0.16) : Theme.surfaceCard
    border.width: 1
    border.color: checked ? Theme.alpha(Theme.accent, 0.35) : Theme.outline
    Behavior on color { ColorAnimation { duration: Theme.animMed } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.text
        opacity: ma.pressed ? 0.1 : ma.containsMouse ? 0.05 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Rectangle {
        id: badge
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 38; height: 38; radius: 19
        color: row.checked ? Theme.accent : Theme.alpha(Theme.text, 0.08)
        Behavior on color { ColorAnimation { duration: Theme.animMed } }
        Text {
            anchors.centerIn: parent
            text: row.icon
            color: row.checked ? Theme.onAccent : Theme.textDim
            font.family: Theme.iconFont
            font.pixelSize: 17
        }
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: 14
        anchors.right: toggle.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            width: parent.width
            text: row.title
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: 14
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: text !== ""
            text: row.subtitle
            color: Theme.textDim
            font.family: Theme.uiFont
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    HubSwitch {
        id: toggle
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        checked: row.checked
        onToggled: on => row.toggled(on)
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.toggled(!row.checked)
    }
}
