// A list card: icon badge, title and detail, and trailing controls (put
// buttons inside it; they go to the right). `active` marks the current or
// connected item; `clickable` makes the whole card a button.
import QtQuick
import "../"

Rectangle {
    id: item

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool clickable: false
    property color tint: Theme.accent
    default property alias trailing: tail.data
    signal clicked()

    width: parent ? parent.width : 400
    height: 60
    radius: 14
    color: active ? Theme.alpha(tint, 0.14) : Theme.surfaceCard
    border.width: 1
    border.color: active ? Theme.alpha(tint, 0.4) : Theme.outline
    Behavior on color { ColorAnimation { duration: Theme.animMed } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.text
        opacity: !item.clickable ? 0 : ma.pressed ? 0.1 : ma.containsMouse ? 0.05 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: item.clickable
        hoverEnabled: true
        cursorShape: item.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: item.clicked()
    }

    Rectangle {
        id: badge
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 36; height: 36; radius: 18
        color: item.active ? item.tint : Theme.alpha(Theme.text, 0.08)
        Text {
            anchors.centerIn: parent
            text: item.icon
            color: item.active ? Theme.onAccent : Theme.textDim
            font.family: Theme.iconFont
            font.pixelSize: 16
        }
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: 12
        anchors.right: tail.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            width: parent.width
            text: item.title
            color: Theme.text
            font.family: Theme.uiFont
            font.pixelSize: 14
            font.weight: item.active ? Font.DemiBold : Font.Medium
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: text !== ""
            text: item.subtitle
            color: item.active ? Theme.text : Theme.textDim
            opacity: item.active ? 0.75 : 1
            font.family: Theme.uiFont
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    Row {
        id: tail
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
    }
}
