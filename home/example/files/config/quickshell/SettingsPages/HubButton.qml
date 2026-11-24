// A Hub button that looks like one: a pill with a fill, a hover and press
// state layer, a pointer cursor and a slight press scale.
//   kind: "filled" (main action), "tonal" (secondary), "outline",
//         "danger" (disconnect, delete), "ghost" (icon-only, quiet)
import QtQuick
import "../"

Rectangle {
    id: btn

    property string text: ""
    property string icon: ""
    property string kind: "tonal"
    property bool busy: false
    property string tooltip: ""
    signal clicked()

    // "danger" stays neutral: the palette's red slot (color1) follows the
    // wallpaper and can be any hue, often too dark to read on the card.
    readonly property color fg: kind === "filled" ? Theme.onAccent
        : kind === "outline" ? Theme.accent
        : Theme.text

    implicitHeight: 34
    implicitWidth: text === "" ? implicitHeight : content.implicitWidth + 30
    height: implicitHeight
    width: implicitWidth
    radius: height / 2
    color: kind === "filled" ? Theme.accent
        : kind === "tonal" ? Theme.alpha(Theme.accent, 0.2)
        : kind === "danger" ? Theme.alpha(Theme.text, 0.14)
        : "transparent"
    border.width: kind === "outline" ? 1 : 0
    border.color: Theme.alpha(Theme.accent, 0.6)
    opacity: enabled ? 1 : 0.45
    scale: ma.pressed ? 0.96 : 1

    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    // State layer.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: btn.fg
        opacity: ma.pressed ? 0.18 : ma.containsMouse ? 0.1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 7
        Text {
            visible: btn.icon !== "" || btn.busy
            anchors.verticalCenter: parent.verticalCenter
            text: btn.busy ? "󰔟" : btn.icon
            color: btn.fg
            font.family: Theme.iconFont
            font.pixelSize: 15
            RotationAnimation on rotation {
                running: btn.busy
                from: 0; to: 360; duration: 1100; loops: Animation.Infinite
            }
            onVisibleChanged: if (!btn.busy) rotation = 0
        }
        Text {
            visible: btn.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: btn.text
            color: btn.fg
            font.family: Theme.uiFont
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: btn.enabled && !btn.busy
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }

    Rectangle {
        visible: btn.tooltip !== "" && ma.containsMouse
        z: 10
        anchors.top: parent.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        width: tip.implicitWidth + 16
        height: 24
        radius: 6
        color: Theme.isLight ? "#2a2a2a" : "#f0f0f0"
        Text {
            id: tip
            anchors.centerIn: parent
            text: btn.tooltip
            color: Theme.isLight ? "#ffffff" : "#111111"
            font.family: Theme.uiFont
            font.pixelSize: 11
        }
    }
}
