// On/off switch: an accent track with a knob when on, an outlined track
// when off. Emits toggled(); the caller owns `checked`.
import QtQuick
import "../"

Item {
    id: sw

    property bool checked: false
    signal toggled(bool on)

    implicitWidth: 46
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight
    opacity: enabled ? 1 : 0.45

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: sw.checked ? Theme.accent : Theme.alpha(Theme.text, 0.1)
        border.width: sw.checked ? 0 : 2
        border.color: Theme.alpha(Theme.text, 0.35)
        Behavior on color { ColorAnimation { duration: Theme.animMed } }

        Rectangle {
            id: knob
            readonly property real size: sw.checked ? 20 : 14
            width: ma.pressed ? size + 4 : size
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 4 : 7 - (width - 14) / 2
            color: sw.checked ? Theme.onAccent : Theme.alpha(Theme.text, 0.6)
            Behavior on x { NumberAnimation { duration: Theme.animMed; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Theme.animFast } }
            Text {
                anchors.centerIn: parent
                visible: sw.checked
                text: "󰄬"
                color: Theme.accent
                font.family: Theme.iconFont
                font.pixelSize: 13
            }
        }

        // Hover halo around the knob.
        Rectangle {
            width: 34; height: 34; radius: 17
            anchors.verticalCenter: parent.verticalCenter
            x: knob.x + knob.width / 2 - width / 2
            color: Theme.text
            opacity: ma.pressed ? 0.14 : ma.containsMouse ? 0.08 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled(!sw.checked)
    }
}
