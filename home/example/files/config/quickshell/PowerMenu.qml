// Power menu (Super+Esc), adapted from the round-button PowerMenu.qml in
// github.com/43PR/dotfiles (MIT). The fourth button toggles the power profile.
// Toggle: qs ipc call powermenu toggle
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    property bool showing: false
    property int currentIndex: 0
    property bool powerSaver: false

    readonly property int buttonSize: 110
    readonly property real edgeGapFrac: 0.06

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: showing || layout.opacity > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "powermenu"
    WlrLayershell.keyboardFocus: showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var actions: [
        { name: "shutdown", icon: "󰐥", key: "s", cmd: ["systemctl", "poweroff"] },
        { name: "reboot",   icon: "󰜉", key: "r", cmd: ["systemctl", "reboot"] },
        { name: "logout",   icon: "󰍃", key: "e", dispatch: "exit" },
        { name: "profile",  icon: "󰌪", key: "p", toggle: true }
    ]

    function openMenu() {
        var mon = Hyprland.focusedMonitor
        if (mon) {
            var scr = Quickshell.screens.find(function (s) { return s.name === mon.name })
            if (scr) root.screen = scr
        }
        profileGet.running = true
        currentIndex = 0
        showing = true
        Qt.callLater(function () { if (root.showing) menuRoot.forceActiveFocus() })
    }
    function closeMenu() { showing = false }
    function toggleMenu() { showing ? closeMenu() : openMenu() }

    function runAction(a) {
        if (a.toggle) {
            // Stays open so the new state is visible; Esc or a click outside closes.
            root.powerSaver = !root.powerSaver
            Quickshell.execDetached({ command: [Quickshell.env("HOME") + "/.local/share/custom/bin/power-profile.sh", "toggle"] })
            return
        }
        if (a.dispatch)
            Hyprland.dispatch(a.dispatch)
        else
            Quickshell.execDetached({ command: a.cmd })
        root.closeMenu()
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void { root.toggleMenu() }
        function show(): void { root.openMenu() }
        function hide(): void { root.closeMenu() }
    }

    Process {
        id: profileGet
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: root.powerSaver = this.text.trim() === "power-saver"
        }
    }

    Item {
        id: menuRoot
        anchors.fill: parent
        focus: true

        Keys.onPressed: function (event) {
            if (!root.showing) return
            var n = root.actions.length
            if (event.key === Qt.Key_Escape) {
                root.closeMenu()
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                root.currentIndex = (root.currentIndex + 1) % n
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                root.currentIndex = (root.currentIndex - 1 + n) % n
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.runAction(root.actions[root.currentIndex])
            } else {
                var a = root.actions.find(function (x) { return x.key === event.text.toLowerCase() })
                if (!a) return
                root.runAction(a)
            }
            event.accepted = true
        }

        // Dim backdrop; Hyprland blurs everything under it (layerrule on "powermenu").
        Rectangle {
            anchors.fill: parent
            color: Theme._bgBase
            opacity: root.showing ? 0.25 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
            MouseArea {
                anchors.fill: parent
                onClicked: root.closeMenu()
            }
        }

        Column {
            id: layout
            anchors.right: parent.right
            anchors.rightMargin: root.width * root.edgeGapFrac
            anchors.verticalCenter: parent.verticalCenter
            spacing: 20
            opacity: root.showing ? 1 : 0
            scale: root.showing ? 1 : 0.9
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool focused: index === root.currentIndex
                    readonly property bool active: modelData.toggle === true && root.powerSaver

                    width: root.buttonSize
                    height: root.buttonSize
                    radius: width / 2
                    color: mouse.pressed ? Theme.alpha(Theme.text, 0.22)
                         : btn.focused ? Theme.alpha(Theme.text, 0.16)
                         : Theme.alpha(Theme._bgBase, 0.45)
                    border.width: btn.active ? 2 : 0
                    border.color: Theme.ok
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        // Leaf while power saver is on, gauge for the normal profile.
                        text: btn.modelData.toggle ? (root.powerSaver ? "󰌪" : "󰾅") : btn.modelData.icon
                        color: btn.active ? Theme.ok : Theme.text
                        font.family: Theme.iconFont
                        font.pixelSize: root.buttonSize * 0.3
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.currentIndex = btn.index
                        onClicked: root.runAction(btn.modelData)
                    }
                }
            }
        }
    }
}
